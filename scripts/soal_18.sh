#!/bin/sh
# geto (Passive Health Check & Backup Worker Kirara)
cat << 'NGINX_EOF' > /etc/nginx/sites-available/default
upstream api_cluster {
    server 192.220.4.5:80 weight=3 max_fails=2 fail_timeout=5s; # nanami
    server 192.220.4.6:80 weight=1 max_fails=2 fail_timeout=5s; # todo
    server 192.220.4.7:80 backup;                               # kirara (backup)
}

server {
    listen 80 default_server;
    server_name jujutsu.k18.com jujutsu.K18.com _;

    set_real_ip_from 192.220.1.4;
    real_ip_header X-Forwarded-For;
    real_ip_recursive on;

    location / {
        proxy_pass http://api_cluster;
        proxy_next_upstream error timeout invalid_header http_500 http_502 http_503 http_504;
        proxy_set_header Host $host;
        proxy_set_header X-Real-IP $remote_addr;
        proxy_set_header X-Forwarded-For $proxy_add_x_forwarded_for;
    }
}
NGINX_EOF
nginx -t && service nginx restart
