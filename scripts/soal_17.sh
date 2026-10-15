#!/bin/sh
# gojo (Reverse Proxy with X-Forwarded Headers)
cat << 'NGINX_EOF' > /etc/nginx/sites-available/default
upstream frontend_cluster {
    server 192.220.4.3:80; # maki
    server 192.220.4.4:80; # panda
}

server {
    listen 80 default_server;
    server_name jujutsu.k18.com www.jujutsu.k18.com jujutsu.K18.com www.jujutsu.K18.com _;

    location / {
        proxy_pass http://frontend_cluster;
        proxy_set_header Host $host;
        proxy_set_header X-Real-IP $remote_addr;
        proxy_set_header X-Forwarded-For $proxy_add_x_forwarded_for;
    }

    location /api {
        proxy_pass http://192.220.4.2;
        proxy_set_header Host $host;
        proxy_set_header X-Real-IP $remote_addr;
        proxy_set_header X-Forwarded-For $proxy_add_x_forwarded_for;
    }
}
NGINX_EOF
nginx -t && service nginx restart

#!/bin/sh
# geto (Real IP Configuration - Trust Gojo 192.220.1.4)
cat << 'NGINX_EOF' > /etc/nginx/sites-available/default
upstream api_cluster {
    server 192.220.4.5:80 weight=3; # nanami
    server 192.220.4.6:80 weight=1; # todo
}

server {
    listen 80 default_server;
    server_name jujutsu.k18.com jujutsu.K18.com _;

    set_real_ip_from 192.220.1.4;
    real_ip_header X-Forwarded-For;
    real_ip_recursive on;

    location / {
        proxy_pass http://api_cluster;
        proxy_set_header Host $host;
        proxy_set_header X-Real-IP $remote_addr;
        proxy_set_header X-Forwarded-For $proxy_add_x_forwarded_for;
    }
}
NGINX_EOF
nginx -t && service nginx restart
