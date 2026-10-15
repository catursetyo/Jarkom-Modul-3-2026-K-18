#!/bin/sh
# maki (Frontend Worker)
echo 'nameserver 192.168.122.1' > /etc/resolv.conf
apt-get update -qq
DEBIAN_FRONTEND=noninteractive apt-get install -y -qq nginx php-fpm

PHP_SOCK=$(find /run/php/ -name "php*-fpm.sock" 2>/dev/null | head -n 1)
mkdir -p /run/php
ln -sf "$PHP_SOCK" /run/php/php-fpm.sock 2>/dev/null || true

mkdir -p /var/www/html
cat << 'HTML_EOF' > /var/www/html/index.php
<?php
echo "Hello from frontend worker: maki\n";
?>
HTML_EOF

cat << 'NGINX_EOF' > /etc/nginx/sites-available/default
server {
    listen 80 default_server;
    server_name jujutsu.k18.com jujutsu.K18.com _;

    allow 192.220.1.4;
    allow 127.0.0.1;
    deny all;

    root /var/www/html;
    index index.php index.html;

    location / {
        try_files $uri $uri/ =404;
    }

    location ~ \.php$ {
        include snippets/fastcgi-php.conf;
        fastcgi_pass unix:/run/php/php-fpm.sock;
    }
}
NGINX_EOF

service $(ls /etc/init.d/php*-fpm | xargs -n 1 basename) restart 2>/dev/null || true
service nginx restart

#!/bin/sh
# panda (Frontend Worker)
echo 'nameserver 192.168.122.1' > /etc/resolv.conf
apt-get update -qq
DEBIAN_FRONTEND=noninteractive apt-get install -y -qq nginx php-fpm

PHP_SOCK=$(find /run/php/ -name "php*-fpm.sock" 2>/dev/null | head -n 1)
mkdir -p /run/php
ln -sf "$PHP_SOCK" /run/php/php-fpm.sock 2>/dev/null || true

mkdir -p /var/www/html
cat << 'HTML_EOF' > /var/www/html/index.php
<?php
echo "Hello from frontend worker: panda\n";
?>
HTML_EOF

cat << 'NGINX_EOF' > /etc/nginx/sites-available/default
server {
    listen 80 default_server;
    server_name jujutsu.k18.com jujutsu.K18.com _;

    allow 192.220.1.4;
    allow 127.0.0.1;
    deny all;

    root /var/www/html;
    index index.php index.html;

    location / {
        try_files $uri $uri/ =404;
    }

    location ~ \.php$ {
        include snippets/fastcgi-php.conf;
        fastcgi_pass unix:/run/php/php-fpm.sock;
    }
}
NGINX_EOF

service $(ls /etc/init.d/php*-fpm | xargs -n 1 basename) restart 2>/dev/null || true
service nginx restart

#!/bin/sh
# nanami (API Worker)
echo 'nameserver 192.168.122.1' > /etc/resolv.conf
apt-get update -qq
DEBIAN_FRONTEND=noninteractive apt-get install -y -qq nginx php-fpm php-mysql

PHP_SOCK=$(find /run/php/ -name "php*-fpm.sock" 2>/dev/null | head -n 1)
mkdir -p /run/php
ln -sf "$PHP_SOCK" /run/php/php-fpm.sock 2>/dev/null || true

mkdir -p /var/www/html
cat << 'PHP_EOF' > /var/www/html/index.php
<?php
$client_ip = $_SERVER['HTTP_X_REAL_IP'] ?? $_SERVER['HTTP_X_FORWARDED_FOR'] ?? $_SERVER['REMOTE_ADDR'];
if (strpos($client_ip, ',') !== false) {
    $parts = explode(',', $client_ip);
    $client_ip = trim($parts[0]);
}
$endpoint = $_SERVER['REQUEST_URI'] ?? '/api';
$worker = "nanami";

try {
    $pdo = new PDO("mysql:host=192.220.4.8;dbname=db_shibuya_k18;charset=utf8", "shibuya_user", "shibuya123", [
        PDO::ATTR_TIMEOUT => 2,
        PDO::ATTR_ERRMODE => PDO::ERRMODE_SILENT
    ]);
    $stmt = $pdo->prepare("INSERT INTO request_logs (client_ip, endpoint, worker_name) VALUES (?, ?, ?)");
    $stmt->execute([$client_ip, $endpoint, $worker]);
} catch (Exception $e) {}

header("Content-Type: application/json");
echo json_encode([
    "status" => "success",
    "worker" => $worker,
    "client_ip" => $client_ip,
    "endpoint" => $endpoint
]) . "\n";
?>
PHP_EOF

cat << 'NGINX_EOF' > /etc/nginx/sites-available/default
server {
    listen 80 default_server;
    server_name jujutsu.k18.com jujutsu.K18.com _;

    allow 192.220.4.2;
    allow 127.0.0.1;
    deny all;

    root /var/www/html;
    index index.php index.html;

    location / {
        try_files $uri $uri/ /index.php?$args;
    }

    location ~ \.php$ {
        include snippets/fastcgi-php.conf;
        fastcgi_pass unix:/run/php/php-fpm.sock;
    }
}
NGINX_EOF

service $(ls /etc/init.d/php*-fpm | xargs -n 1 basename) restart 2>/dev/null || true
service nginx restart

#!/bin/sh
# todo (API Worker)
echo 'nameserver 192.168.122.1' > /etc/resolv.conf
apt-get update -qq
DEBIAN_FRONTEND=noninteractive apt-get install -y -qq nginx php-fpm php-mysql

PHP_SOCK=$(find /run/php/ -name "php*-fpm.sock" 2>/dev/null | head -n 1)
mkdir -p /run/php
ln -sf "$PHP_SOCK" /run/php/php-fpm.sock 2>/dev/null || true

mkdir -p /var/www/html
cat << 'PHP_EOF' > /var/www/html/index.php
<?php
$client_ip = $_SERVER['HTTP_X_REAL_IP'] ?? $_SERVER['HTTP_X_FORWARDED_FOR'] ?? $_SERVER['REMOTE_ADDR'];
if (strpos($client_ip, ',') !== false) {
    $parts = explode(',', $client_ip);
    $client_ip = trim($parts[0]);
}
$endpoint = $_SERVER['REQUEST_URI'] ?? '/api';
$worker = "todo";

try {
    $pdo = new PDO("mysql:host=192.220.4.8;dbname=db_shibuya_k18;charset=utf8", "shibuya_user", "shibuya123", [
        PDO::ATTR_TIMEOUT => 2,
        PDO::ATTR_ERRMODE => PDO::ERRMODE_SILENT
    ]);
    $stmt = $pdo->prepare("INSERT INTO request_logs (client_ip, endpoint, worker_name) VALUES (?, ?, ?)");
    $stmt->execute([$client_ip, $endpoint, $worker]);
} catch (Exception $e) {}

header("Content-Type: application/json");
echo json_encode([
    "status" => "success",
    "worker" => $worker,
    "client_ip" => $client_ip,
    "endpoint" => $endpoint
]) . "\n";
?>
PHP_EOF

cat << 'NGINX_EOF' > /etc/nginx/sites-available/default
server {
    listen 80 default_server;
    server_name jujutsu.k18.com jujutsu.K18.com _;

    allow 192.220.4.2;
    allow 127.0.0.1;
    deny all;

    root /var/www/html;
    index index.php index.html;

    location / {
        try_files $uri $uri/ /index.php?$args;
    }

    location ~ \.php$ {
        include snippets/fastcgi-php.conf;
        fastcgi_pass unix:/run/php/php-fpm.sock;
    }
}
NGINX_EOF

service $(ls /etc/init.d/php*-fpm | xargs -n 1 basename) restart 2>/dev/null || true
service nginx restart

#!/bin/sh
# kirara (API Worker & Backup)
echo 'nameserver 192.168.122.1' > /etc/resolv.conf
apt-get update -qq
DEBIAN_FRONTEND=noninteractive apt-get install -y -qq nginx php-fpm php-mysql

PHP_SOCK=$(find /run/php/ -name "php*-fpm.sock" 2>/dev/null | head -n 1)
mkdir -p /run/php
ln -sf "$PHP_SOCK" /run/php/php-fpm.sock 2>/dev/null || true

mkdir -p /var/www/html
cat << 'PHP_EOF' > /var/www/html/index.php
<?php
$client_ip = $_SERVER['HTTP_X_REAL_IP'] ?? $_SERVER['HTTP_X_FORWARDED_FOR'] ?? $_SERVER['REMOTE_ADDR'];
if (strpos($client_ip, ',') !== false) {
    $parts = explode(',', $client_ip);
    $client_ip = trim($parts[0]);
}
$endpoint = $_SERVER['REQUEST_URI'] ?? '/api';
$worker = "kirara";

try {
    $pdo = new PDO("mysql:host=192.220.4.8;dbname=db_shibuya_k18;charset=utf8", "shibuya_user", "shibuya123", [
        PDO::ATTR_TIMEOUT => 2,
        PDO::ATTR_ERRMODE => PDO::ERRMODE_SILENT
    ]);
    $stmt = $pdo->prepare("INSERT INTO request_logs (client_ip, endpoint, worker_name) VALUES (?, ?, ?)");
    $stmt->execute([$client_ip, $endpoint, $worker]);
} catch (Exception $e) {}

header("Content-Type: application/json");
echo json_encode([
    "status" => "success",
    "worker" => $worker,
    "client_ip" => $client_ip,
    "endpoint" => $endpoint
]) . "\n";
?>
PHP_EOF

cat << 'NGINX_EOF' > /etc/nginx/sites-available/default
server {
    listen 80 default_server;
    server_name jujutsu.k18.com jujutsu.K18.com _;

    allow 192.220.4.2;
    allow 127.0.0.1;
    deny all;

    root /var/www/html;
    index index.php index.html;

    location / {
        try_files $uri $uri/ /index.php?$args;
    }

    location ~ \.php$ {
        include snippets/fastcgi-php.conf;
        fastcgi_pass unix:/run/php/php-fpm.sock;
    }
}
NGINX_EOF

service $(ls /etc/init.d/php*-fpm | xargs -n 1 basename) restart 2>/dev/null || true
service nginx restart
