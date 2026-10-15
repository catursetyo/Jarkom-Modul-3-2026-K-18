#!/bin/sh
# utahime (DNS Records: A, CNAME, Reverse PTR)
cat << 'EOF' > /etc/bind/named.conf.local
zone "jujutsu.k18.com" {
    type master;
    file "/etc/bind/jujutsu/jujutsu.k18.com";
    notify yes;
    allow-transfer { 192.220.1.3; };
};

zone "1.220.192.in-addr.arpa" {
    type master;
    file "/etc/bind/jujutsu/1.220.192.in-addr.arpa";
    notify yes;
    allow-transfer { 192.220.1.3; };
};
EOF

cat << 'EOF' > /etc/bind/jujutsu/jujutsu.k18.com
$TTL    604800
@       IN      SOA     jujutsu.k18.com. root.jujutsu.k18.com. (
                              2026101502 ; Serial
                                  604800 ; Refresh
                                   86400 ; Retry
                                 2419200 ; Expire
                                  604800 ) ; Negative Cache TTL
;
@       IN      NS      utahime.jujutsu.k18.com.
@       IN      NS      shoko.jujutsu.k18.com.
utahime IN      A       192.220.1.2
shoko   IN      A       192.220.1.3
@       IN      A       192.220.1.4
www     IN      CNAME   jujutsu.k18.com.
EOF

cat << 'EOF' > /etc/bind/jujutsu/1.220.192.in-addr.arpa
$TTL    604800
@       IN      SOA     jujutsu.k18.com. root.jujutsu.k18.com. (
                              2026101502 ; Serial
                                  604800 ; Refresh
                                   86400 ; Retry
                                 2419200 ; Expire
                                  604800 ) ; Negative Cache TTL
;
@       IN      NS      utahime.jujutsu.k18.com.
@       IN      NS      shoko.jujutsu.k18.com.
4       IN      PTR     jujutsu.k18.com.
EOF

named-checkconf /etc/bind/named.conf
named-checkzone jujutsu.k18.com /etc/bind/jujutsu/jujutsu.k18.com
named-checkzone 1.220.192.in-addr.arpa /etc/bind/jujutsu/1.220.192.in-addr.arpa
service named restart || service bind9 restart

#!/bin/sh
# shoko (Slave Reverse PTR Zone)
cat << 'EOF' > /etc/bind/named.conf.local
zone "jujutsu.k18.com" {
    type slave;
    file "/var/lib/bind/jujutsu.k18.com";
    masters { 192.220.1.2; };
};

zone "1.220.192.in-addr.arpa" {
    type slave;
    file "/var/lib/bind/1.220.192.in-addr.arpa";
    masters { 192.220.1.2; };
};
EOF

named-checkconf /etc/bind/named.conf
service named restart || service bind9 restart
