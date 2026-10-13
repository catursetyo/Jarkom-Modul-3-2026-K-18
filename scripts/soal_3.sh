#!/bin/sh
# jichi
apt-get update -qq
apt-get install -y -qq isc-dhcp-relay
cat <<'EOF' > /etc/default/isc-dhcp-relay
SERVERS="192.220.4.10"
INTERFACES="eth2 eth3 eth4"
EOF
service isc-dhcp-relay restart
service isc-dhcp-relay status && echo RELAY=OK || echo RELAY=FAIL
ps aux | grep dhcrelay | grep -v grep

#!/bin/sh
# itadori
cat <<'EOF' > /etc/network/interfaces
auto eth0
iface eth0 inet dhcp
EOF

#!/bin/sh
# fushiguro
cat <<'EOF' > /etc/network/interfaces
auto eth0
iface eth0 inet dhcp
EOF

#!/bin/sh
# zenin
cat <<'EOF' > /etc/network/interfaces
auto eth0
iface eth0 inet dhcp
EOF

#!/bin/sh
# okkotsu
cat <<'EOF' > /etc/network/interfaces
auto eth0
iface eth0 inet dhcp
EOF

#!/bin/sh
# ino
cat <<'EOF' > /etc/network/interfaces
auto eth0
iface eth0 inet dhcp
EOF

#!/bin/sh
# kusakabe
cat <<'EOF' > /etc/network/interfaces
auto eth0
iface eth0 inet dhcp
EOF

#!/bin/sh
# miwa
cat <<'EOF' > /etc/network/interfaces
auto eth0
iface eth0 inet dhcp
EOF

#!/bin/sh
# kugisaki
cat <<'EOF' > /etc/network/interfaces
auto eth0
iface eth0 inet dhcp
EOF
