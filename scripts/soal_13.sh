#!/bin/sh
# yaga (MariaDB Master)
echo 'nameserver 192.168.122.1' > /etc/resolv.conf
apt-get update -qq
DEBIAN_FRONTEND=noninteractive apt-get install -y -qq mariadb-server

sed -i 's/^bind-address.*/bind-address = 0.0.0.0/' /etc/mysql/mariadb.conf.d/50-server.cnf 2>/dev/null || true
grep -q "server-id" /etc/mysql/mariadb.conf.d/50-server.cnf || sed -i '/\[mysqld\]/a server-id = 1\nlog_bin = /var/log/mysql/mariadb-bin' /etc/mysql/mariadb.conf.d/50-server.cnf

service mariadb restart || service mysql restart

mariadb -e "CREATE DATABASE IF NOT EXISTS db_shibuya_k18;"
mariadb -e "CREATE DATABASE IF NOT EXISTS db_shibuya_K18;"

mariadb -e "CREATE TABLE IF NOT EXISTS db_shibuya_k18.request_logs (
    id INT AUTO_INCREMENT PRIMARY KEY,
    client_ip VARCHAR(50) NOT NULL,
    endpoint VARCHAR(255) DEFAULT NULL,
    worker_name VARCHAR(100) DEFAULT NULL,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);"

mariadb -e "CREATE TABLE IF NOT EXISTS db_shibuya_K18.request_logs (
    id INT AUTO_INCREMENT PRIMARY KEY,
    client_ip VARCHAR(50) NOT NULL,
    endpoint VARCHAR(255) DEFAULT NULL,
    worker_name VARCHAR(100) DEFAULT NULL,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);"

mariadb -e "CREATE USER IF NOT EXISTS 'replica'@'%' IDENTIFIED BY 'replica123';"
mariadb -e "GRANT REPLICATION SLAVE ON *.* TO 'replica'@'%';"

mariadb -e "CREATE USER IF NOT EXISTS 'shibuya_user'@'%' IDENTIFIED BY 'shibuya123';"
mariadb -e "GRANT ALL PRIVILEGES ON db_shibuya_k18.* TO 'shibuya_user'@'%';"
mariadb -e "GRANT ALL PRIVILEGES ON db_shibuya_K18.* TO 'shibuya_user'@'%';"
mariadb -e "FLUSH PRIVILEGES;"

mariadb -e "SHOW MASTER STATUS\G"

#!/bin/sh
# inumaki (MariaDB Slave)
echo 'nameserver 192.168.122.1' > /etc/resolv.conf
apt-get update -qq
DEBIAN_FRONTEND=noninteractive apt-get install -y -qq mariadb-server

sed -i 's/^bind-address.*/bind-address = 0.0.0.0/' /etc/mysql/mariadb.conf.d/50-server.cnf 2>/dev/null || true
grep -q "server-id" /etc/mysql/mariadb.conf.d/50-server.cnf || sed -i '/\[mysqld\]/a server-id = 2' /etc/mysql/mariadb.conf.d/50-server.cnf

service mariadb restart || service mysql restart

mariadb -e "CREATE DATABASE IF NOT EXISTS db_shibuya_k18;"
mariadb -e "CREATE DATABASE IF NOT EXISTS db_shibuya_K18;"

mariadb -e "CREATE TABLE IF NOT EXISTS db_shibuya_k18.request_logs (
    id INT AUTO_INCREMENT PRIMARY KEY,
    client_ip VARCHAR(50) NOT NULL,
    endpoint VARCHAR(255) DEFAULT NULL,
    worker_name VARCHAR(100) DEFAULT NULL,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);"

mariadb -e "CREATE TABLE IF NOT EXISTS db_shibuya_K18.request_logs (
    id INT AUTO_INCREMENT PRIMARY KEY,
    client_ip VARCHAR(50) NOT NULL,
    endpoint VARCHAR(255) DEFAULT NULL,
    worker_name VARCHAR(100) DEFAULT NULL,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);"

mariadb -e "STOP SLAVE;"
mariadb -e "CHANGE MASTER TO MASTER_HOST='192.220.4.8', MASTER_USER='replica', MASTER_PASSWORD='replica123';"
mariadb -e "START SLAVE;"
sleep 2
mariadb -e "SHOW SLAVE STATUS\G"
