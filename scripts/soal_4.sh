#!/bin/sh
# tengen
cat <<'EOF' > /etc/dhcp/dhcpd.conf
authoritative;
option domain-name-servers 192.168.122.1;

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

# Network 2 (Divisi A)
subnet 192.220.2.0 netmask 255.255.255.0 {
  option routers 192.220.2.2;
  option broadcast-address 192.220.2.255;
  pool { range 192.220.2.10 192.220.2.34; allow members of "pool1"; }
  pool { range 192.220.2.70 192.220.2.94; allow members of "pool2"; }
}

# Network 3 (Divisi B) - class lease-time & fixed-address menyusul (soal 5-6)
subnet 192.220.3.0 netmask 255.255.255.0 {
  option routers 192.220.3.1;
  option broadcast-address 192.220.3.255;
  pool { range 192.220.3.10 192.220.3.88; }
  pool { range 192.220.3.100 192.220.3.199; }
}
EOF
dhcpd -t -cf /etc/dhcp/dhcpd.conf && echo DHCPD_T=OK || echo DHCPD_T=FAIL
service isc-dhcp-server restart
service isc-dhcp-server status && echo SERVICE=OK || echo SERVICE=FAIL
