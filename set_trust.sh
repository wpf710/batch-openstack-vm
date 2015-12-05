#!/usr/bin/expect
set timeout 60
set vm_ip [lindex $argv 0]
set net [lindex $argv 1]
set pd [lindex $argv 2]
spawn sed -i /$vm_ip/d /root/.ssh/known_hosts && ip netns exec qdhcp-$net ssh-copy-id root@$vm_ip
expect "*connecting (yes/no)?"
send "yes\r"
expect "*password:"
send "$pd\r"
expect "*]#"
