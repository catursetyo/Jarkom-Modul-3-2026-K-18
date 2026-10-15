#!/bin/sh
# kusakabe (Apache Benchmark Testing)
# Install apache2-utils if not installed
which ab >/dev/null 2>&1 || {
    echo 'nameserver 192.168.122.1' > /etc/resolv.conf
    apk update && apk add apache2-utils
    echo 'nameserver 192.220.1.2' > /etc/resolv.conf
    echo 'nameserver 192.220.1.3' >> /etc/resolv.conf
}

# 1. Benchmark Frontend Caching (Target: http://jujutsu.k18.com/)
ab -n 600 -c 30 http://jujutsu.k18.com/ > /root/benchmark_frontend.txt 2>&1
cat /root/benchmark_frontend.txt | grep -E "Requests per second|Time per request|Failed requests|Complete requests"

# 2. Benchmark API Rate Limiting (Target: http://jujutsu.k18.com/api)
ab -n 600 -c 30 http://jujutsu.k18.com/api > /root/benchmark_api.txt 2>&1
cat /root/benchmark_api.txt | grep -E "Requests per second|Time per request|Failed requests|Non-2xx|Complete requests"
