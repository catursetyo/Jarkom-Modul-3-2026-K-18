# tengen
timeout 35 tcpdump -i eth0 -n -vv udp port 67 or udp port 68

# itadori
ifdown eth0 2>&1
ifup eth0 2>&1

# ino
ifdown eth0 2>&1
ifup eth0 2>&1
