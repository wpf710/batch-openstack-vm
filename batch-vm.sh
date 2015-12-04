#!/bin/sh

. ./params

#------------------------------------------------------------------------------------
#if [ $# -lt 5 ]
#then
#  echo "Usage : ./batch-vm.sh vm-count image flavor net-id zabbix-server [vm-name] "
#  exit 1
#fi

#vm_count=$1
#image=$2
#flavor=$3
#net=$4
#zb_server=$5
#name_prefix=$6

#if [ x$name_prefix == x ]
#then
#  name_prefix='batch'
#fi

#vol_size=10
#------------------------------------------------------------------------------------

# three parameters
# $1 vm uuid
# $2 vm ip addr
# $3 zabbix server addr

function create_vm_monitor()
{
  local templates='{"templateid":"10002"}'

  vm_uuid=$1
  ip=$2  
  zabbix_api_server_ip=$3

  res=`curl -s -X POST http://${zabbix_api_server_ip}:8090/zabbix/api_jsonrpc.php -H "Accept: application/json" -H "Content-Type: application/json" -d  '{"jsonrpc": "2.0","method": "user.login","params":{"user":"Admin","password": "zabbix"},"id": 1}'`

  token=`echo $res | awk -F '"' '{print $8}'`

  data='{"jsonrpc":"2.0","method":"host.create","params":{"host":"'${vm_uuid}'","interfaces":[{"type":1,"main":1,"useip":1,"ip":"'${ip}'","dns":"","port":"10053"}],"groups":[{"groupid":"2"}],"templates":['$templates']},"auth":"'${token}'","id":1}'

  curl -s -X POST http://${zabbix_api_server_ip}:8090/zabbix/api_jsonrpc.php -H "Accept: application/json" -H "Content-Type: application/json" -d "${data}" >> /dev/null

}

vms=()
vols=()

pre_ip=""
i=1
while true;do
  if ((i > vm_count))
  then
    if [[ $keep_running != "true" ]]
    then
      echo "finished!!"
      break 
    fi 
  fi
  
  next_vm=$((i%vm_count))

  #check whether it's the next round
  if ((i > vm_count ))
  then
    echo "remove the vm in previous cycle..."
    nova delete ${vms[$next_vm]} >> /dev/null
    sleep 5
    cinder delete ${vols[$next_vm]} >> /dev/null
  fi
  
  
   vm_name=$name_prefix'-'$i

   echo -n 'create vm '$vm_name
 
   vm_id=$(nova boot --flavor $flavor --image $image --nic net-id=$net $vm_name |awk '{print $2 " " $4}'|grep -w id|awk '{print $2}')

   # progress bar
   for j in $(seq 5)
   do
        echo -n "."
        sleep 1
   done

   for j in $(seq 40)
   do

     s=$(nova show $vm_id  |grep OS-EXT-STS:vm_state |awk '{print $4}')

     if [ "$s" = "active" ]
     then
       echo  'sucessed!!'
       break
     fi

     for m in $(seq 5)
     do
        echo -n "."
        sleep 1
     done
    
   done
  
   if [ "$s" != "active" ]
   then
     echo 'failed'
     exit 1
   fi

   vms[$next_vm]=$vm_id
  
   vm_ip=$(nova show $vm_id |grep network |awk '{print $5}')


   echo "create monitor...."
   create_vm_monitor $vm_id $vm_ip $zb_server


   echo -n "waiting for the ssh to be availale"
   ssh_failed="true"
   for j in $(seq 60)
   do
     echo -n "."
     ip netns exec qdhcp-$net nmap $vm_ip -PN -p ssh 2>&1 | grep open >> /dev/null
  
     result=$?
     if [[ $result -eq 0 ]]; then
       echo
       echo "SSH OK"
       ssh_failed="false"
       break
     fi
     sleep 1
   done

   if [[ $ssh_failed == "true" ]]; then
    echo "SSH Failed"
    exit 1
   fi

   sed -i /$vm_ip/d /root/.ssh/known_hosts >> /dev/null

   #create volume
   vol_name='vol-'$vm_name
   echo -n 'create volume '$vol_name

   vol_id=$(cinder create --name $vol_name $vol_size |grep  -w id |awk '{print $4}')
  
   # progress bar
   for j in $(seq 3)
   do
        echo -n "."
        sleep 1
   done

   for j in $(seq 20)
   do

     s=$(cinder show $vol_id |awk '{print $2$4}' |grep  '^status')

     if [ "$s" = "statusavailable" ]
     then
       echo  'sucessed!!'
       break
     fi

     for m in $(seq 3)
     do
        echo -n "."
        sleep 1
     done

   done

   if [ "$s" != "statusavailable" ]
   then
     echo 'failed'
     exit 1
   fi

   vols[$next_vm]=$vol_id

   echo 'attaching volume....'
   nova volume-attach $vm_id $vol_id >>/dev/null
   echo 'mounting volume.....'


   ./set_trust.sh $vm_ip $net $vm_password >> /dev/null

   echo $pre_ip > addons/ips.txt
   ip netns exec qdhcp-$net scp addons/* root@$vm_ip:/root/ >>/dev/null

   ip netns exec qdhcp-$net ssh root@$vm_ip 'sh mount-vol.sh' >>/dev/null
   ip netns exec qdhcp-$net ssh root@$vm_ip 'rpm -ivh stress-1.0.2-1.el6.rf.x86_64.rpm' >>/dev/null
     
   ip netns exec qdhcp-$net ssh root@$vm_ip 'bash async_job.sh' >>/dev/null

   
   echo  

   pre_ip=$vm_ip

  ((i++))

  if [[ $slow_down > 0 ]]
  then
    sl=$slow_down

    if [[ $randomly_slow_down == "true" ]]
    then
      sl=$(($RANDOM%slow_down))
    fi

    if [[ $sl > 0 ]]
    then
      echo -n "slow down the process("$sl"s)"
      for m in $(seq $sl)
      do
        echo -n "."
        sleep 1
      done

      echo
      echo
    fi
  fi  
done
