# jichi (fase gangguan)
service isc-dhcp-relay stop
ps aux | grep dhcrelay | grep -v grep

# itadori (saat relay mati - bukti kegagalan)
ifdown eth0 2>&1
ifup eth0 2>&1
ip -4 addr show dev eth0
ping -c2 -W2 192.220.2.2

# jichi (fase pemulihan)
service isc-dhcp-relay start
ps aux | grep dhcrelay | grep -v grep

# itadori (setelah relay hidup - bukti pulih)
ifdown eth0 2>&1
ifup eth0 2>&1
ip -4 addr show dev eth0
ip route | grep '^default'
ping -c2 -W2 192.220.2.2
