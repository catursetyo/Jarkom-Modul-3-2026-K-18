#!/bin/sh
# tengen
apt-get update -qq
apt-get install -y -qq isc-dhcp-server
echo 'INTERFACESv4="eth0"' > /etc/default/isc-dhcp-server
cat <<'EOF' > /etc/dhcp/dhcpd.conf
authoritative;
option domain-name-servers 192.168.122.1;

# Network 4 - subnet lokal tanpa pool dinamis
subnet 192.220.4.0 netmask 255.255.255.0 { }

# Network 2 (Divisi A)
subnet 192.220.2.0 netmask 255.255.255.0 {
  option routers 192.220.2.2;
  option broadcast-address 192.220.2.255;
  pool { range 192.220.2.10 192.220.2.34; }
  pool { range 192.220.2.70 192.220.2.94; }
}

# Network 3 (Divisi B)
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
