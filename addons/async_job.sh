#! /bin/bash
echo "return text from asyn-job"
exec 0>&- # close stdin
exec 0<&-
exec 1>&- # close stdout
exec 1<&-
exec 2>&- # close stderr
exec 2<&-
#the real job in the background
#install nginx
nohup wget http://10.168.91.129:8087/install_nginx.sh && sh install_nginx.sh >> /dev/null &
#write into storage
#nohup wget http://10.168.91.129:8087/a.rpm && for i in $(seq 30);do \cp a.rpm /data/mariadb/$i;done &
#nohup stress --io 2 --vm 1 --vm-bytes 3072M --timeout 900s &
#(crontab -l ; echo "*/45 * * * * rm -f a.rpm && wget http://10.168.91.129:8087/a.rpm") | crontab - 
#(crontab -l ; echo "*/30 * * * * stress --io 2 --vm 1 --vm-bytes 3072M --timeout 900s") | crontab -
(crontab -l ; echo "*/15 * * * * sh /root/xloop.sh") | crontab -
exit 0
