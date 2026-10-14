#!/bin/sh
# tengen
cat <<'EOF' > /etc/dhcp/dhcpd.conf
authoritative;
option domain-name-servers 192.220.1.2, 192.220.1.3;
option domain-name "k18.com";
option domain-search "k18.com";

# Network 4 - subnet lokal tanpa pool dinamis
subnet 192.220.4.0 netmask 255.255.255.0 { }

# Pool 1: itadori & fushiguro
class "pool1" { match pick-first-value (option dhcp-client-identifier, hardware); }
subclass "pool1" 1:02:42:8d:c6:9a:00;
subclass "pool1" 1:02:42:ea:a1:6f:00;

# Pool 2: zenin & okkotsu
class "pool2" { match pick-first-value (option dhcp-client-identifier, hardware); }
subclass "pool2" 1:02:42:ac:3e:97:00;
subclass "pool2" 1:02:42:d2:43:1c:00;

# Short lease: ino & kusakabe
class "short-lease" { match pick-first-value (option dhcp-client-identifier, hardware); }
subclass "short-lease" 1:02:42:35:9a:ff:00;
subclass "short-lease" 1:02:42:38:15:fc:00;

# Long lease: miwa
class "long-lease" { match pick-first-value (option dhcp-client-identifier, hardware); }
subclass "long-lease" 1:02:42:30:17:02:00;

# Network 2 (Divisi A)
subnet 192.220.2.0 netmask 255.255.255.0 {
  option routers 192.220.2.2;
  option broadcast-address 192.220.2.255;
  pool { range 192.220.2.10 192.220.2.34; allow members of "pool1"; }
  pool { range 192.220.2.70 192.220.2.94; allow members of "pool2"; }
}

# Network 3 (Divisi B) - kugisaki (fixed-address) menyusul di soal 6
subnet 192.220.3.0 netmask 255.255.255.0 {
  option routers 192.220.3.1;
  option broadcast-address 192.220.3.255;
  pool { range 192.220.3.10 192.220.3.88; allow members of "short-lease";
         default-lease-time 1800; max-lease-time 1800; }
  pool { range 192.220.3.100 192.220.3.199; allow members of "long-lease";
         default-lease-time 43200; max-lease-time 43200; }
}
EOF
dhcpd -t -cf /etc/dhcp/dhcpd.conf && echo DHCPD_T=OK || echo DHCPD_T=FAIL
service isc-dhcp-server restart
service isc-dhcp-server status && echo SERVICE=OK || echo SERVICE=FAIL
