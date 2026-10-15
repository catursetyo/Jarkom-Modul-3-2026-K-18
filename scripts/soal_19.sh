#!/bin/sh
# gojo (Proxy Caching & Rate Limiting)
mkdir -p /var/cache/nginx/web
chown -R www-data:www-data /var/cache/nginx

cat << 'EOF' > /etc/nginx/conf.d/cache_and_limit.conf
proxy_cache_path /var/cache/nginx/web levels=1:2 keys_zone=web_cache:10m max_size=100m inactive=60m use_temp_path=off;
limit_req_zone $binary_remote_addr zone=api_limit:10m rate=10r/s;
EOF

cat << 'NGINX_EOF' > /etc/nginx/sites-available/default
upstream frontend_cluster {
    server 192.220.4.3:80; # maki
    server 192.220.4.4:80; # panda
}

server {
    listen 80 default_server;
    server_name jujutsu.k18.com www.jujutsu.k18.com jujutsu.K18.com www.jujutsu.K18.com _;

    # Path-based routing: / -> frontend_cluster with Proxy Caching (10m)
    location / {
        proxy_pass http://frontend_cluster;
        proxy_set_header Host $host;
        proxy_set_header X-Real-IP $remote_addr;
        proxy_set_header X-Forwarded-For $proxy_add_x_forwarded_for;

        proxy_cache web_cache;
        proxy_cache_valid 200 302 10m;
        proxy_cache_use_stale error timeout updating http_500 http_502 http_503 http_504;
        proxy_ignore_headers Cache-Control Expires Set-Cookie;
        proxy_hide_header Set-Cookie;
        add_header X-Cache-Status $upstream_cache_status always;
    }

    # Path-based routing: /api -> geto with Rate Limiting (10r/s)
    location /api {
        limit_req zone=api_limit burst=5 nodelay;
        limit_req_status 503;

        proxy_pass http://192.220.4.2;
        proxy_set_header Host $host;
        proxy_set_header X-Real-IP $remote_addr;
        proxy_set_header X-Forwarded-For $proxy_add_x_forwarded_for;
    }
}
NGINX_EOF

nginx -t && service nginx restart
