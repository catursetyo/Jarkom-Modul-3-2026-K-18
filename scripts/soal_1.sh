#!/bin/sh
# utahime
cat <<'EOF' > /etc/network/interfaces
auto eth0
iface eth0 inet static
  address 192.220.1.2
  netmask 255.255.255.0
  gateway 192.220.1.1
EOF

cat <<'EOF' > /root/init.sh
#!/bin/sh
echo 'nameserver 192.168.122.1' > /etc/resolv.conf
EOF
chmod +x /root/init.sh

sh /root/init.sh

#!/bin/sh
# shoko
cat <<'EOF' > /etc/network/interfaces
auto eth0
iface eth0 inet static
  address 192.220.1.3
  netmask 255.255.255.0
  gateway 192.220.1.1
EOF

cat <<'EOF' > /root/init.sh
#!/bin/sh
echo 'nameserver 192.168.122.1' > /etc/resolv.conf
EOF
chmod +x /root/init.sh

sh /root/init.sh

#!/bin/sh
# gojo
cat <<'EOF' > /etc/network/interfaces
auto eth0
iface eth0 inet static
  address 192.220.1.4
  netmask 255.255.255.0
  gateway 192.220.1.1
EOF

cat <<'EOF' > /root/init.sh
#!/bin/sh
echo 'nameserver 192.168.122.1' > /etc/resolv.conf
EOF
chmod +x /root/init.sh

sh /root/init.sh

#!/bin/sh
# itadori
cat <<'EOF' > /etc/network/interfaces
auto eth0
iface eth0 inet static
  address 192.220.2.36
  netmask 255.255.255.0
  gateway 192.220.2.2
EOF

cat <<'EOF' > /root/init.sh
#!/bin/sh
echo 'nameserver 192.168.122.1' > /etc/resolv.conf
EOF
chmod +x /root/init.sh

sh /root/init.sh

#!/bin/sh
# fushiguro
cat <<'EOF' > /etc/network/interfaces
auto eth0
iface eth0 inet static
  address 192.220.2.37
  netmask 255.255.255.0
  gateway 192.220.2.2
EOF

cat <<'EOF' > /root/init.sh
#!/bin/sh
echo 'nameserver 192.168.122.1' > /etc/resolv.conf
EOF
chmod +x /root/init.sh

sh /root/init.sh

#!/bin/sh
# zenin
cat <<'EOF' > /etc/network/interfaces
auto eth0
iface eth0 inet static
  address 192.220.2.38
  netmask 255.255.255.0
  gateway 192.220.2.2
EOF

cat <<'EOF' > /root/init.sh
#!/bin/sh
echo 'nameserver 192.168.122.1' > /etc/resolv.conf
EOF
chmod +x /root/init.sh

sh /root/init.sh

#!/bin/sh
# okkotsu
cat <<'EOF' > /etc/network/interfaces
auto eth0
iface eth0 inet static
  address 192.220.2.39
  netmask 255.255.255.0
  gateway 192.220.2.2
EOF

cat <<'EOF' > /root/init.sh
#!/bin/sh
echo 'nameserver 192.168.122.1' > /etc/resolv.conf
EOF
chmod +x /root/init.sh

sh /root/init.sh

#!/bin/sh
# ino
cat <<'EOF' > /etc/network/interfaces
auto eth0
iface eth0 inet static
  address 192.220.3.90
  netmask 255.255.255.0
  gateway 192.220.3.1
EOF

cat <<'EOF' > /root/init.sh
#!/bin/sh
echo 'nameserver 192.168.122.1' > /etc/resolv.conf
EOF
chmod +x /root/init.sh

sh /root/init.sh

#!/bin/sh
# kusakabe
cat <<'EOF' > /etc/network/interfaces
auto eth0
iface eth0 inet static
  address 192.220.3.91
  netmask 255.255.255.0
  gateway 192.220.3.1
EOF

cat <<'EOF' > /root/init.sh
#!/bin/sh
echo 'nameserver 192.168.122.1' > /etc/resolv.conf
EOF
chmod +x /root/init.sh

sh /root/init.sh

#!/bin/sh
# miwa
cat <<'EOF' > /etc/network/interfaces
auto eth0
iface eth0 inet static
  address 192.220.3.92
  netmask 255.255.255.0
  gateway 192.220.3.1
EOF

cat <<'EOF' > /root/init.sh
#!/bin/sh
echo 'nameserver 192.168.122.1' > /etc/resolv.conf
EOF
chmod +x /root/init.sh

sh /root/init.sh

#!/bin/sh
# kugisaki
cat <<'EOF' > /etc/network/interfaces
auto eth0
iface eth0 inet static
  address 192.220.3.93
  netmask 255.255.255.0
  gateway 192.220.3.1
EOF

cat <<'EOF' > /root/init.sh
#!/bin/sh
echo 'nameserver 192.168.122.1' > /etc/resolv.conf
EOF
chmod +x /root/init.sh

sh /root/init.sh

#!/bin/sh
# geto
cat <<'EOF' > /etc/network/interfaces
auto eth0
iface eth0 inet static
  address 192.220.4.2
  netmask 255.255.255.0
  gateway 192.220.4.1
EOF

cat <<'EOF' > /root/init.sh
#!/bin/sh
echo 'nameserver 192.168.122.1' > /etc/resolv.conf
EOF
chmod +x /root/init.sh

sh /root/init.sh

#!/bin/sh
# maki
cat <<'EOF' > /etc/network/interfaces
auto eth0
iface eth0 inet static
  address 192.220.4.3
  netmask 255.255.255.0
  gateway 192.220.4.1
EOF

cat <<'EOF' > /root/init.sh
#!/bin/sh
echo 'nameserver 192.168.122.1' > /etc/resolv.conf
EOF
chmod +x /root/init.sh

sh /root/init.sh

#!/bin/sh
# panda
cat <<'EOF' > /etc/network/interfaces
auto eth0
iface eth0 inet static
  address 192.220.4.4
  netmask 255.255.255.0
  gateway 192.220.4.1
EOF

cat <<'EOF' > /root/init.sh
#!/bin/sh
echo 'nameserver 192.168.122.1' > /etc/resolv.conf
EOF
chmod +x /root/init.sh

sh /root/init.sh

#!/bin/sh
# nanami
cat <<'EOF' > /etc/network/interfaces
auto eth0
iface eth0 inet static
  address 192.220.4.5
  netmask 255.255.255.0
  gateway 192.220.4.1
EOF

cat <<'EOF' > /root/init.sh
#!/bin/sh
echo 'nameserver 192.168.122.1' > /etc/resolv.conf
EOF
chmod +x /root/init.sh

sh /root/init.sh

#!/bin/sh
# todo
cat <<'EOF' > /etc/network/interfaces
auto eth0
iface eth0 inet static
  address 192.220.4.6
  netmask 255.255.255.0
  gateway 192.220.4.1
EOF

cat <<'EOF' > /root/init.sh
#!/bin/sh
echo 'nameserver 192.168.122.1' > /etc/resolv.conf
EOF
chmod +x /root/init.sh

sh /root/init.sh

#!/bin/sh
# kirara
cat <<'EOF' > /etc/network/interfaces
auto eth0
iface eth0 inet static
  address 192.220.4.7
  netmask 255.255.255.0
  gateway 192.220.4.1
EOF

cat <<'EOF' > /root/init.sh
#!/bin/sh
echo 'nameserver 192.168.122.1' > /etc/resolv.conf
EOF
chmod +x /root/init.sh

sh /root/init.sh

#!/bin/sh
# yaga
cat <<'EOF' > /etc/network/interfaces
auto eth0
iface eth0 inet static
  address 192.220.4.8
  netmask 255.255.255.0
  gateway 192.220.4.1
EOF

cat <<'EOF' > /root/init.sh
#!/bin/sh
echo 'nameserver 192.168.122.1' > /etc/resolv.conf
EOF
chmod +x /root/init.sh

sh /root/init.sh

#!/bin/sh
# inumaki
cat <<'EOF' > /etc/network/interfaces
auto eth0
iface eth0 inet static
  address 192.220.4.9
  netmask 255.255.255.0
  gateway 192.220.4.1
EOF

cat <<'EOF' > /root/init.sh
#!/bin/sh
echo 'nameserver 192.168.122.1' > /etc/resolv.conf
EOF
chmod +x /root/init.sh

sh /root/init.sh

#!/bin/sh
# tengen
cat <<'EOF' > /etc/network/interfaces
auto eth0
iface eth0 inet static
  address 192.220.4.10
  netmask 255.255.255.0
  gateway 192.220.4.1
EOF

cat <<'EOF' > /root/init.sh
#!/bin/sh
echo 'nameserver 192.168.122.1' > /etc/resolv.conf
EOF
chmod +x /root/init.sh

sh /root/init.sh

#!/bin/sh
# jichi
cat <<'EOF' > /etc/network/interfaces
auto eth0
iface eth0 inet dhcp

auto eth1
iface eth1 inet static
  address 192.220.1.1
  netmask 255.255.255.0

auto eth2
iface eth2 inet static
  address 192.220.2.2
  netmask 255.255.255.0

auto eth3
iface eth3 inet static
  address 192.220.3.1
  netmask 255.255.255.0

auto eth4
iface eth4 inet static
  address 192.220.4.1
  netmask 255.255.255.0
EOF

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
EOF
chmod +x /root/init.sh
command -v iptables >/dev/null 2>&1 || apt-get update -qq && apt-get install -y -qq iptables

sh /root/init.sh
