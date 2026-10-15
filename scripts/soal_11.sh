#!/bin/sh
# utahime (DNS Master)
echo 'nameserver 192.168.122.1' > /etc/resolv.conf
apt-get update -qq
DEBIAN_FRONTEND=noninteractive apt-get install -y -qq bind9 bind9utils dnsutils

cat << 'EOF' > /etc/bind/named.conf.options
options {
    directory "/var/cache/bind";
    forwarders {
        192.168.122.1;
    };
    allow-query { any; };
    auth-nxdomain no;
    listen-on-v6 { any; };
};
EOF

mkdir -p /etc/bind/jujutsu
cat << 'EOF' > /etc/bind/named.conf.local
zone "jujutsu.k18.com" {
    type master;
    file "/etc/bind/jujutsu/jujutsu.k18.com";
    notify yes;
    allow-transfer { 192.220.1.3; };
};
EOF

cat << 'EOF' > /etc/bind/jujutsu/jujutsu.k18.com
$TTL    604800
@       IN      SOA     jujutsu.k18.com. root.jujutsu.k18.com. (
                              2026101501 ; Serial
                                  604800 ; Refresh
                                   86400 ; Retry
                                 2419200 ; Expire
                                  604800 ) ; Negative Cache TTL
;
@       IN      NS      utahime.jujutsu.k18.com.
@       IN      NS      shoko.jujutsu.k18.com.
utahime IN      A       192.220.1.2
shoko   IN      A       192.220.1.3
EOF

named-checkconf /etc/bind/named.conf
named-checkzone jujutsu.k18.com /etc/bind/jujutsu/jujutsu.k18.com
service named restart || service bind9 restart

#!/bin/sh
# shoko (DNS Slave)
echo 'nameserver 192.168.122.1' > /etc/resolv.conf
apt-get update -qq
DEBIAN_FRONTEND=noninteractive apt-get install -y -qq bind9 bind9utils dnsutils

cat << 'EOF' > /etc/bind/named.conf.options
options {
    directory "/var/cache/bind";
    forwarders {
        192.168.122.1;
    };
    allow-query { any; };
    auth-nxdomain no;
    listen-on-v6 { any; };
};
EOF

cat << 'EOF' > /etc/bind/named.conf.local
zone "jujutsu.k18.com" {
    type slave;
    file "/var/lib/bind/jujutsu.k18.com";
    masters { 192.220.1.2; };
};
EOF

named-checkconf /etc/bind/named.conf
service named restart || service bind9 restart
