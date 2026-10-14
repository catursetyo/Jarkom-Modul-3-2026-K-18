#!/bin/sh
# tengen
cat <<'EOF' > /root/init.sh
#!/bin/sh
echo 'nameserver 192.168.122.1' > /etc/resolv.conf
# tunggu interface dapat IP (dhcpd butuh interface utk listen), lalu autostart
n=0
while [ $n -lt 15 ] && ! ip -4 addr show eth0 | grep -q inet; do sleep 1; n=$((n+1)); done
service isc-dhcp-server status >/dev/null 2>&1 || service isc-dhcp-server start
EOF
chmod +x /root/init.sh
sh /root/init.sh

#!/bin/sh
# jichi
cat <<'EOF' > /root/init.sh
#!/bin/sh
echo 1 > /proc/sys/net/ipv4/ip_forward
grep -q '^net.ipv4.ip_forward=1' /etc/sysctl.conf 2>/dev/null || \
  echo 'net.ipv4.ip_forward=1' >> /etc/sysctl.conf
if command -v iptables >/dev/null 2>&1; then
  iptables -t nat -C POSTROUTING -o eth0 -s 192.220.0.0/16 -j MASQUERADE 2>/dev/null || \
    iptables -t nat -A POSTROUTING -o eth0 -s 192.220.0.0/16 -j MASQUERADE
fi
echo 'nameserver 192.168.122.1' > /etc/resolv.conf
# tunggu interface klien dapat IP, lalu autostart relay
n=0
while [ $n -lt 15 ] && ! ip -4 addr show eth2 | grep -q inet; do sleep 1; n=$((n+1)); done
# status init-script relay selalu exit 0 walau daemon mati -> start tanpa syarat
service isc-dhcp-relay start
EOF
chmod +x /root/init.sh
sh /root/init.sh