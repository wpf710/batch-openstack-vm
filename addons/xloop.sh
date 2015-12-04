#!/bin/sh

while read adr
do
  wget -P /data/mariadb/  http://$adr/x.rpm >> /dev/null 
done < /root/ips.txt
