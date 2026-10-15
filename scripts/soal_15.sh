#!/bin/sh
# geto (Internal Load Balancer - Weighted Round Robin 3:1)
echo 'nameserver 192.168.122.1' > /etc/resolv.conf
apt-get update -qq
DEBIAN_FRONTEND=noninteractive apt-get install -y -qq nginx

cat << 'NGINX_EOF' > /etc/nginx/sites-available/default
upstream api_cluster {
    server 192.220.4.5:80 weight=3; # nanami (weight 3)
    server 192.220.4.6:80 weight=1; # todo (weight 1)
}

server {
    listen 80 default_server;
    server_name jujutsu.k18.com jujutsu.K18.com _;

    location / {
        proxy_pass http://api_cluster;
        proxy_set_header Host $host;
        proxy_set_header X-Real-IP $remote_addr;
        proxy_set_header X-Forwarded-For $proxy_add_x_forwarded_for;
    }
}
NGINX_EOF

nginx -t
service nginx restart
