#!/bin/sh
# gojo (Public Reverse Proxy - Path-based Routing)
echo 'nameserver 192.168.122.1' > /etc/resolv.conf
apt-get update -qq
DEBIAN_FRONTEND=noninteractive apt-get install -y -qq nginx

cat << 'NGINX_EOF' > /etc/nginx/sites-available/default
upstream frontend_cluster {
    server 192.220.4.3:80; # maki
    server 192.220.4.4:80; # panda
}

server {
    listen 80 default_server;
    server_name jujutsu.k18.com www.jujutsu.k18.com jujutsu.K18.com www.jujutsu.K18.com _;

    # Path-based routing: / -> frontend_cluster (Round Robin)
    location / {
        proxy_pass http://frontend_cluster;
        proxy_set_header Host $host;
        proxy_set_header X-Real-IP $remote_addr;
        proxy_set_header X-Forwarded-For $proxy_add_x_forwarded_for;
    }

    # Path-based routing: /api -> geto (Internal Load Balancer)
    location /api {
        proxy_pass http://192.220.4.2;
        proxy_set_header Host $host;
        proxy_set_header X-Real-IP $remote_addr;
        proxy_set_header X-Forwarded-For $proxy_add_x_forwarded_for;
    }
}
NGINX_EOF

nginx -t
service nginx restart
