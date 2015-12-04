#!/bin/sh

# get file from web server
wget http://10.168.91.129:8087/install_nginx.zip
unzip install_nginx.zip
rpm -U u1.rpm
rpm -U u2.rpm
rpm -ivh 3.rpm
rpm -ivh 4.rpm
rpm -ivh 5.rpm
rpm -ivh 6.rpm
rpm -ivh 7.rpm
tar -xvf n.gz
cd nginx-1.8.0
./configure --prefix=/opt/n --without-http_rewrite_module --without-http_gzip_module && make && make install && /opt/n/sbin/nginx

cd

#16M
cp 7.rpm /opt/n/html/x.rpm
for i in $(seq 20); do cat 7.rpm >> /opt/n/html/x.rpm ;done
