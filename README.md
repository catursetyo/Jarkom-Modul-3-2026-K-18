# PRAKTIKUM JARKOM MODUL 3 KELOMPOK K18 - 2026

## Anggota Kelompok

| Nama                  | NRP        |
| --------------------- | ---------- |
| Catur Setyo Ragil     | 5027251066 |
| Senna Bagus Harimurti | 5027251106 |

## Ringkasan Implementasi

- Praktikum menggunakan `debinet` sebagai router/server dan `alpinet` sebagai client.
- Prefix IP kelompok: `192.220.x.x` - jaringan hasil pembagian: DMZ `192.220.1.0/24`, Divisi A (`Network 2`) `192.220.2.0/24`, Divisi B (`Network 3`) `192.220.3.0/24`, Data Center (`Network 4`) `192.220.4.0/24`. Domain internal: `k18.com`.
- Topologi terdiri dari 21 node docker + 10 Ethernet switch + 1 NAT.
- Semua script instalasi & konfigurasi diletakkan di `/root` tiap node dan diarsipkan pada folder `scripts/` repo ini.

![](assets/1_topologi.png)

---

## Laporan

### Soal 1 - Konfigurasi NAT dan IP forwarding

Topologi: **jichi** sebagai router utama dengan 5 interface (`eth0` >> NAT, `eth1`–`eth4` >> masing-masing Network 1–4), DHCP server **tengen** di Data Center, 12 klien `alpine` terbagi ke Divisi A dan Divisi B, serta server jaringan (DNS, worker, LB, database) di DMZ dan Data Center.

**Konfigurasi** (`scripts/soal_1.sh`, diterapkan per node). jichi:

```text
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
```

NAT + forwarding di `jichi`:

```sh
echo 1 > /proc/sys/net/ipv4/ip_forward
iptables -t nat -C POSTROUTING -o eth0 -s 192.220.0.0/16 -j MASQUERADE || \
  iptables -t nat -A POSTROUTING -o eth0 -s 192.220.0.0/16 -j MASQUERADE
```

`init.sh` tahap persiapan awal agar node dapat mengunduh paket yang dibutuhkan

```sh
echo 'nameserver 192.168.122.1' > /etc/resolv.conf
```

| Host | IP | Gateway |
|---|---|---|
| jichi | `.1.1` / `.2.2` / `.3.1` / `.4.1` (+ eth0 DHCP) | - |
| utahime | 192.220.1.2/24 | 192.220.1.1 |
| shoko | 192.220.1.3/24 | 192.220.1.1 |
| gojo | 192.220.1.4/24 | 192.220.1.1 |
| itadori / fushiguro / zenin / okkotsu | IP sementara `.2.36–.39` (later DHCP) | 192.220.2.2 |
| ino / kusakabe / miwa / kugisaki | IP sementara `.3.90–.93` (later DHCP) | 192.220.3.1 |
| geto / maki / panda / nanami / todo / kirara | `.4.2 – .4.7` | 192.220.4.1 |
| yaga / inumaki | `.4.8` / `.4.9` | 192.220.4.1 |
| tengen | 192.220.4.10/24 | 192.220.4.1 |

Klien awal diberi IP statis sementara **di luar** semua pool DHCP (Divisi A `.2.36–.39`, Divisi B `.3.90–.93`) hanya untuk persiapan instalasi paket.

**Validasi:** `ip a` dan `ip route` tiap host (harus ada `default via ...`), ping gateway dari tiap host, ping internet (`ping google.com`), dan `iptables -t nat -L -v` di jichi.

![](assets/1_soal1_jichi_ip.png)

![](assets/1_soal1_ping_gateway_utahime.png)

![](assets/1_soal1_ping_gateway_itadori.png)

![](assets/1_soal1_ping_gateway_tengen.png)

![](assets/1_soal1_ping_internet.png)

---

### Soal 2 - DHCP Server di tengen

**Konfigurasi** (`scripts/soal_2.sh`, di tengen): instal `isc-dhcp-server`, `INTERFACESv4="eth0"` di `/etc/default/isc-dhcp-server`, lalu `dhcpd.conf`. Network 4 dideklarasikan sebagai subnet lokal **tanpa pool** (mencegah error *No subnet declaration* karena dhcpd berada di subnet tersebut):

```
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
```

Rentang terlarang Divisi A (`192.220.2.36–192.220.2.69`) sengaja tidak dimasukkan ke range mana pun.

**Validasi:** `dhcpd -t` valid, `service isc-dhcp-server status` berjalan tanpa error, lease tercatat di `/var/lib/dhcp/dhcpd.leases`.

```sh
dhcpd -t -cf /etc/dhcp/dhcpd.conf 2>&1; true
service isc-dhcp-server status; true
ps aux | grep dhcpd | grep -v grep; true
ss -uln | grep :67; true
grep -E "subnet|pool|range|class|host" /etc/dhcp/dhcpd.conf; true
```

![](assets/2_soal2_dhcpd_status.png)

---

### Soal 3 - DHCP Relay di jichi

**Konfigurasi** (`scripts/soal_3.sh`, di jichi):

```text
# /etc/default/isc-dhcp-relay
SERVERS="192.220.4.10"
INTERFACES="eth2 eth3 eth4"
```

Kedelapan klien Divisi A & B diganti ke `iface eth0 inet dhcp` lalu di-restart.

Temuan penting: `INTERFACES` relay **harus mencakup eth4** - balasan OFFER/ACK dari tengen ter-routing masuk ke jichi lewat eth4, sedangkan `dhcrelay` hanya memproses paket yang *ingress* di interface terdaftar. Hal ini dibuktikan lewat tcpdump: DISCOVER klien sampai ke tengen dan OFFER dikirim ke giaddr `.2.2`/`.3.1`, namun klien tidak pernah menerimanya sebelum eth4 ditambahkan.

**Validasi:** `ps aux | grep dhcrelay` (proses `dhcrelay -q -i eth2 -i eth3 -i eth4 192.220.4.10`), klien memperoleh IP dari pool yang benar, dan lease aktif per-MAC tercatat di `dhcpd.leases` tengen.

di jichi:
```sh
cat /etc/default/isc-dhcp-relay
ps aux | grep dhcrelay | grep -v grep
pgrep -a dhcrelay; true
```

![](assets/3_soal3_dhcrelay.png)

di tengen:
```sh
sh /root/soal_4.sh
sh /root/soal_5.sh
sh /root/soal_6.sh
grep -E "class|subclass|allow|host|fixed|domain" /etc/dhcp/dhcpd.conf; true
```

lalu di itadori:
```sh
ifdown eth0 2>&1; ifup eth0
ip -4 addr show dev eth0
cat /etc/resolv.conf
ping -c 3 192.220.2.2
```

![](assets/3_soal3_client_lease.png)

---

### Soal 4 - Dua Pool Berbasis Class MAC di Divisi A

Pool 1 (`192.220.2.10–.34`, itadori & fushiguro) dan Pool 2 (`192.220.2.70–.94`, zenin & okkotsu) berada di subnet yang sama, sehingga pemisahannya memakai **class MAC address** (`subclass` 1:**MAC**), bukan subnet.

**Konfigurasi** (`scripts/soal_4.sh`, di tengen):

```
class "pool1" { match pick-first-value (option dhcp-client-identifier, hardware); }
subclass "pool1" 1:02:42:8d:c6:9a:00;      # itadori
subclass "pool1" 1:02:42:ea:a1:6f:00;      # fushiguro

class "pool2" { match pick-first-value (option dhcp-client-identifier, hardware); }
subclass "pool2" 1:02:42:ac:3e:97:00;      # zenin
subclass "pool2" 1:02:42:d2:43:1c:00;      # okkotsu

subnet 192.220.2.0 netmask 255.255.255.0 {
  pool { range 192.220.2.10 192.220.2.34; allow members of "pool1"; }
  pool { range 192.220.2.70 192.220.2.94; allow members of "pool2"; }
}
```

**Validasi:** after restart, itadori>>`.2.10` & fushiguro>>`.2.11` (Pool 1), zenin>>`.2.70` & okkotsu>>`.2.71` (Pool 2 - terbukti pindah pool dari alokasi awal saat class aktif); tidak ada klien mendapat IP di `.2.36–.2.69`.

![](assets/4_soal4_pool1_pool2.png)

---

### Soal 5 - Short/Long Lease & Opsi DNS di Divisi B

**Konfigurasi** (`scripts/soal_5.sh`, di tengen): class `short-lease` (ino, kusakabe) >> pool `.3.10–.3.88` dengan `default/max-lease-time 1800`; class `long-lease` (miwa) >> pool `.3.100–.3.199` dengan lease `43200`. Opsi DHCP global diganti ke DNS internal sesuai soal:

```
option domain-name-servers 192.220.1.2, 192.220.1.3;
option domain-name "k18.com";
option domain-search "k18.com";
```

`allow members of` diterapkan pada kedua pool Divisi B sehingga hanya anggota class yang dilayani pool-nya (kugisaki belum punya class dan sengaja belum di-restart - fixed-address-nya menyusul di Soal 6).

**Validasi:** lease time terbaca langsung di output `udhcpc` saat renew klien (`lease of 192.220.3.10 obtained, lease time 1800` dsb.); ino/kusakabe `.3.10`/`.3.11` dengan 1800s, miwa pindah ke `.3.100` dengan 43200s; `resolv.conf` klien berisi kedua DNS + `search k18.com`.

di ino dan miwa
```sh
ifdown eth0 2>&1; sleep 2; ifup eth0
```

![](assets/5_soal5_tengen.png)

![](assets/5_soal5_lease_time_ino.png)

![](assets/5_soal5_lease_time_miwa.png)

pada ino
```sh
cat /etc/resolv.conf
ip -4 addr show dev eth0
ip route
ping -c 3 192.220.3.1
```

![](assets/5_soal5_resolv.png)

---

### Soal 6 - Fixed Address kugisaki

**Konfigurasi** (`scripts/soal_6.sh`, di tengen): blok `host` berdasarkan MAC, di luar semua pool dinamis:

```
host kugisaki {
  hardware ethernet 02:42:99:23:7c:00;
  fixed-address 192.220.3.99;
}
```

**Validasi:** kugisaki konsisten mendapat `192.220.3.99` setelah restart node **dan** setelah renew (`ifdown/ifup`); gateway `.3.1` dan opsi DNS/domain tetap benar. Catatan menarik yang terkonfirmasi: `.3.99` **tidak** muncul di `dhcpd.leases` - fixed-address di luar pool adalah binding statik dari deklarasi host, bukan lease dinamis.

di tengen
```sh
grep -n -A4 "host kugisaki" /etc/dhcp/dhcpd.conf
```

di kugisaki
```sh
ip -4 addr show dev eth0
```

```sh
ifdown eth0 2>&1; sleep 2; ifup eth0
ip -4 addr show dev eth0
ping -c 3 192.220.3.1
cat /etc/resolv.conf
```

lalu di tengen
```sh
grep "192.220.3.99" /var/lib/dhcp/dhcpd.leases; echo "grep-exit=$?"
```

![](assets/6_soal6_fixed_addr.png)

---

### Soal 7 - Audit Menyeluruh Klien

Tidak ada perubahan konfigurasi; lease kedelapan klien hanya di-renew (`ifdown/ifup`) agar opsi DNS internal berlaku di semua klien, lalu seluruh klien Divisi A & B diaudit: mask `/24`, broadcast benar, gateway benar, DNS ganda `.1.2`+`.1.3`, domain-search `k18.com`, IP sesuai pool/fixed-address, tidak ada klien di rentang terlarang, dan semuanya cocok dengan `dhcpd.leases` di tengen (IP + durasi lease per class).

Hasil audit:

| Node | IP | Pool | Gateway | Lease |
|---|---|---|---|---|
| itadori | 192.220.2.10 | pool1 | 192.220.2.2 | 43200s |
| fushiguro | 192.220.2.11 | pool1 | 192.220.2.2 | 43200s |
| zenin | 192.220.2.70 | pool2 | 192.220.2.2 | 43200s |
| okkotsu | 192.220.2.71 | pool2 | 192.220.2.2 | 43200s |
| ino | 192.220.3.10 | short-lease | 192.220.3.1 | 1800s |
| kusakabe | 192.220.3.11 | short-lease | 192.220.3.1 | 1800s |
| miwa | 192.220.3.100 | long-lease | 192.220.3.1 | 43200s |
| kugisaki | 192.220.3.99 | fixed (host) | 192.220.3.1 | statis |

pada tiap node client
```sh
ifdown eth0 2>&1; sleep 2; ifup eth0
ip -4 addr show dev eth0
ip route | grep default
cat /etc/resolv.conf
```

![](assets/7_soal7_audit_ip.png)

di tengen
```sh
grep -E "^lease 192.220" /var/lib/dhcp/dhcpd.leases | sort -t. -k3n,3 -k4n,4
grep -A6 "lease 192.220.2.10" /var/lib/dhcp/dhcpd.leases | grep -E "hardware|ends"
grep -A6 "lease 192.220.3.10" /var/lib/dhcp/dhcpd.leases | grep -E "hardware|ends"
grep "192.220.3.99" /var/lib/dhcp/dhcpd.leases; echo "kugisaki-leases=$?"
grep -E "^lease 192.220.2\.(3[6-9]|4[0-9]|5[0-9]|6[0-9])" /var/lib/dhcp/dhcpd.leases; echo "forbidden=$?"
```

![](assets/7_soal7_dhcpd_leases.png)

---

### Soal 8 - Bukti DORA melalui Packet Capture

`tcpdump -i eth0 -n -vv` di tengen disiapkan (window 90 detik, file dibaca setelah tcpdump exit agar buffer ter-flush), lalu renew dipicu pada dua klien - satu per subnet: itadori (Divisi A) dan ino (Divisi B).

Result per client:

- urutan DORA lengkap: DISCOVER >> OFFER >> REQUEST >> ACK;
- **giaddr** semua paket = IP jichi pada subnet klien (`.2.2` untuk Divisi A, `.3.1` untuk Divisi B) - bukti jalur relay;
- Server-ID `192.220.4.10`, Your-IP = IP klien sesuai pool-nya, Lease-Time 43200/1800 sesuai class;
- jalur relay terlihat: DISCOVER/REQUEST `192.220.4.1 >> 192.220.4.10`, OFFER/ACK `192.220.4.10 >> giaddr`.

mulai capture di tengen
```sh
rm -f /tmp/dora_n2.txt
(tcpdump -i eth0 -n -vv udp port 67 or udp port 68 > /tmp/dora_n2.txt 2>&1 &)
```

di itadori daftar renew
```sh
ifdown eth0 2>&1
ifup eth0 2>&1
```

lalu di tengen
```sh
pkill tcpdump
cat /tmp/dora_n2.txt
```

atau
```sh
grep -nE "giaddr|yiaddr|siaddr|Server|lease|Client-Ethernet|BOOTP/DHCP" /tmp/dora_n2.txt
```

![](assets/8_soal8_tcpdump_n2.png)

di tengen capture
```sh
rm -f /tmp/dora_n3.txt
(tcpdump -i eth0 -n -vv udp port 67 or udp port 68 > /tmp/dora_n3.txt 2>&1 &)
```

lalu di ino
```sh
ifdown eth0 2>&1
ifup eth0 2>&1
```

baca di tengen
```sh
pkill tcpdump
grep -nE "giaddr|yiaddr|siaddr|Server|lease|Client-Ethernet|BOOTP/DHCP" /tmp/dora_n3.txt
```

![](assets/8_soal8_tcpdump_n3.png)

---

### Soal 9 - Simulasi Gangguan DHCP Relay

Jalankan `scripts/soal_9.sh` pada itadori:

1. **PRE** - relay hidup, itadori `192.220.2.10` OK.
2. **GANGGUAN** - `service isc-dhcp-relay stop` di jichi >> renew klien berakhir `udhcpc failed to get a DHCP lease` (timeout tanpa OFFER), eth0 tanpa IPv4, ping gateway `.2.2` gagal.
3. **PULIH** - `service isc-dhcp-relay start` >> renew sukses, IP kembali `192.220.2.10` (terikat MAC), gateway semula OK.

cek itadori
```sh
ip -4 addr show dev eth0
ping -c2 -W2 192.220.2.2
```

cek jichi
```sh
pgrep -a dhcrelay
```

lalu
```sh
service isc-dhcp-relay stop
ps aux | grep dhcrelay | grep -v grep
```

minta lease baru tanpa relay di itadori
```sh
ifdown eth0 2>&1
ifup eth0 2>&1
ip -4 addr show dev eth0
ping -c2 -W2 192.220.2.2
```

![](assets/9_soal9_gangguan.png)

pulihkan dhcrelay
```sh
service isc-dhcp-relay start
ps aux | grep dhcrelay | grep -v grep
```

lalu di itadori
```sh
ifdown eth0 2>&1
ifup eth0 2>&1
ip -4 addr show dev eth0
ip route | grep '^default'
ping -c2 -W2 192.220.2.2
```

![](assets/9_soal9_pulih.png)

---

### Soal 10 - Persistensi Layanan

Autostart DHCP Server (tengen) dan DHCP Relay (jichi) dipasang melalui `/root/init.sh` yang dijalankan otomatis saat boot (`scripts/soal_10.sh`). Karena pengamatan: init-script `isc-dhcp-relay` Debian **tidak mengimplementasikan `status` sungguhan** (selalu exit 0 walau daemon mati), sehingga autostart relay memakai start tanpa syarat + polling verifikasi `pgrep`.

```sh
# /root/init.sh tengen - tunggu interface dapat IP dulu (dhcpd butuh interface utk listen)
n=0
while [ $n -lt 15 ] && ! ip -4 addr show eth0 | grep -q inet; do sleep 1; n=$((n+1)); done
service isc-dhcp-server status >/dev/null 2>&1 || service isc-dhcp-server start
```

```sh
# /root/init.sh jichi - forwarding + MASQUERADE + DNS + autostart relay
# (init.sh lengkap juga memuat net.ipv4.ip_forward=1, rule MASQUERADE idempoten,
#  dan resolv.conf - lihat scripts/soal_10.sh)
while [ $n -lt 15 ] && ! ip -4 addr show eth2 | grep -q inet; do sleep 1; n=$((n+1)); done
service isc-dhcp-relay start        # start tanpa syarat - guard status relay menipu
```

**Validasi:** kedua node di-restart penuh (stop>>start) >> dhcpd & dhcrelay hidup sendiri; config jichi utuh (5 IP, forwarding, MASQUERADE di-reapply); kebijakan dhcpd.conf utuh; kedelapan klien tidak terpengaruh (IP/gateway/ping + konektivitas lintas subnet itadori>>tengen); renew pembuktian: itadori `.2.10` (pool1), ino lease 1800s, kugisaki `.3.99` (fixed).

di tengen dan jichi
```sh
./soal_10.sh
```

restart kedua node tersebut, lalu di tengen
```sh
pgrep -a dhcpd
grep -c "host kugisaki" /etc/dhcp/dhcpd.conf
grep -E "pool|range" /etc/dhcp/dhcpd.conf | head -4
```

di jichi
```sh
pgrep -a dhcrelay
ip -4 addr show eth1 | grep inet && ip -4 addr show eth2 | grep inet && ip -4 addr show eth3 | grep inet && ip -4 addr show eth4 | grep inet
sysctl net.ipv4.ip_forward
iptables -t nat -L POSTROUTING -v | grep MASQUERADE
```

![](assets/10_soal10_service_status.png)

cek itadori
```sh
ip -4 addr show dev eth0 && ip route | grep default
ping -c3 192.220.2.2
ping -c3 192.220.4.10
```

renew lease
```sh
ifdown eth0 2>&1; sleep 2; ifup eth0
```

![](assets/10_soal10_client_lease.png)

---


### Soal 11 - Konfigurasi DNS Master dan Slave (BIND9)

Layanan translasi nama domain Jujutsu High dibangun menggunakan BIND9 dengan skema redundansi Master-Slave di zona DMZ (Network 1). **utahime** (`192.220.1.2`) bertindak sebagai DNS Master dan **shoko** (`192.220.1.3`) bertindak sebagai DNS Slave untuk domain internal `jujutsu.k18.com`. DNS forwarder disiapkan mengarah ke `192.168.122.1` agar query domain eksternal/internet tetap dapat diresolusi.

**Konfigurasi** (`scripts/soal_11.sh`):

Di **utahime** (Master):
```text
# /etc/bind/named.conf.options
options {
    directory "/var/cache/bind";
    forwarders {
        192.168.122.1;
    };
    allow-query { any; };
    auth-nxdomain no;
    listen-on-v6 { any; };
};

# /etc/bind/named.conf.local
zone "jujutsu.k18.com" {
    type master;
    file "/etc/bind/jujutsu/jujutsu.k18.com";
    notify yes;
    allow-transfer { 192.220.1.3; };
};
```

File zona `/etc/bind/jujutsu/jujutsu.k18.com`:
```text
$TTL    604800
@       IN      SOA     jujutsu.k18.com. root.jujutsu.k18.com. (
                              2026101501 ; Serial
                                  604800 ; Refresh
                                   86400 ; Retry
                                 2419200 ; Expire
                                  604800 ) ; Negative Cache TTL
;
@       IN      NS      utahime.jujutsu.k18.com.
@       IN      NS      shoko.jujutsu.k18.com.
utahime IN      A       192.220.1.2
shoko   IN      A       192.220.1.3
```

Di **shoko** (Slave):
```text
# /etc/bind/named.conf.local
zone "jujutsu.k18.com" {
    type slave;
    file "/var/lib/bind/jujutsu.k18.com";
    masters { 192.220.1.2; };
};
```

Temuan & Catatan Teknis: Direktori berkas zona slave diletakkan di `/var/lib/bind/` karena *daemon* BIND9 di Debian/Ubuntu berjalan di bawah pengguna `bind` yang secara *default* memiliki hak tulis pada direktori tersebut ketika menerima replikasi *zone transfer*.

**Validasi:** Pengujian sintaks konfigurasi, pengecekan status service, dan pengujian sinkronisasi zona:
```sh
# Di utahime:
named-checkconf /etc/bind/named.conf
named-checkzone jujutsu.k18.com /etc/bind/jujutsu/jujutsu.k18.com

# Di client / testing node:
dig @192.220.1.2 jujutsu.k18.com SOA +short
dig @192.220.1.3 jujutsu.k18.com SOA +short
dig @192.220.1.3 axfr jujutsu.k18.com
```

Output membuktikan kedua server menyajikan Serial Number SOA yang identik (`2026101501`), dan slave shoko berhasil mengunduh seluruh record DNS secara otomatis dari master utahime.

![](assets/11_soal11_bind9_master_slave.png)

![](assets/11_soal11_dig_zone_transfer.png)

---

### Soal 12 - DNS Records (A, CNAME, Reverse PTR) dan Forwarder

Domain utama `jujutsu.k18.com` diarahkan ke pintu gerbang *reverse proxy* publik **gojo** (`192.220.1.4`). Selain itu, ditambahkan alias CNAME `www`, zona reverse PTR `1.220.192.in-addr.arpa`, dan forwarder ke gateway `192.168.122.1`.

**Konfigurasi** (`scripts/soal_12.sh`):

Di **utahime** (Master) - pembaruan record zona dan penambahan reverse zone:
```text
# /etc/bind/jujutsu/jujutsu.k18.com
@       IN      A       192.220.1.4
www     IN      CNAME   jujutsu.k18.com.

# /etc/bind/named.conf.local (Zona Reverse)
zone "1.220.192.in-addr.arpa" {
    type master;
    file "/etc/bind/jujutsu/1.220.192.in-addr.arpa";
    notify yes;
    allow-transfer { 192.220.1.3; };
};

# /etc/bind/jujutsu/1.220.192.in-addr.arpa
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
```

Di **shoko** (Slave):
```text
zone "1.220.192.in-addr.arpa" {
    type slave;
    file "/var/lib/bind/1.220.192.in-addr.arpa";
    masters { 192.220.1.2; };
};
```

**Validasi:** Pengujian resolusi domain A, CNAME, PTR, dan Forwarder:
```sh
dig @192.220.1.2 jujutsu.k18.com A +short
dig @192.220.1.2 www.jujutsu.k18.com +short
dig -x 192.220.1.4 @192.220.1.2 +short
dig @192.220.1.2 google.com +short
```

Hasil resolusi:
- `jujutsu.k18.com` resolve tepat ke `192.220.1.4`.
- `www.jujutsu.k18.com` mengembalikan CNAME `jujutsu.k18.com.` lalu berujung pada `192.220.1.4`.
- PTR record dari IP `192.220.1.4` menghasilkan `jujutsu.k18.com.`.
- Query `google.com` berhasil diteruskan oleh forwarder ke internet.

![](assets/12_soal12_dns_a_cname.png)

![](assets/12_soal12_dns_ptr_forwarder.png)

---

### Soal 13 - Replikasi Database MariaDB (Master-Slave)

Penyimpanan log aktivitas Jujutsu High diamankan dengan arsitektur database clustering Master-Slave di Data Center (Network 4). **yaga** (`192.220.4.8`) bertindak sebagai Database Master dan **inumaki** (`192.220.4.9`) bertindak sebagai Database Slave.

**Konfigurasi** (`scripts/soal_13.sh`):

Di **yaga** (Master):
- Mengaktifkan binary logging dan bind ke seluruh interface:
```text
# /etc/mysql/mariadb.conf.d/50-server.cnf
bind-address = 0.0.0.0
server-id = 1
log_bin = /var/log/mysql/mariadb-bin
```
- Inisialisasi Database, Tabel Log, Akun Replikasi, dan Akun Aplikasi:
```sql
CREATE DATABASE IF NOT EXISTS db_shibuya_k18;
CREATE TABLE IF NOT EXISTS db_shibuya_k18.request_logs (
    id INT AUTO_INCREMENT PRIMARY KEY,
    client_ip VARCHAR(50) NOT NULL,
    endpoint VARCHAR(255) DEFAULT NULL,
    worker_name VARCHAR(100) DEFAULT NULL,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);
CREATE USER IF NOT EXISTS 'replica'@'%' IDENTIFIED BY 'replica123';
GRANT REPLICATION SLAVE ON *.* TO 'replica'@'%';
CREATE USER IF NOT EXISTS 'shibuya_user'@'%' IDENTIFIED BY 'shibuya123';
GRANT ALL PRIVILEGES ON db_shibuya_k18.* TO 'shibuya_user'@'%';
FLUSH PRIVILEGES;
```

Di **inumaki** (Slave):
- `server-id = 2` dan `bind-address = 0.0.0.0` pada `50-server.cnf`.
- Mengaitkan slave ke koordinat binlog master:
```sql
STOP SLAVE;
CHANGE MASTER TO 
    MASTER_HOST='192.220.4.8', 
    MASTER_USER='replica', 
    MASTER_PASSWORD='replica123';
START SLAVE;
```

**Validasi:** Status replikasi dan uji konsistensi data secara real-time:
```sh
# Di yaga (Master):
mariadb -e "SHOW MASTER STATUS\G"

# Di inumaki (Slave):
mariadb -e "SHOW SLAVE STATUS\G"
```

Parameter krusial pada slave terverifikasi:
- `Slave_IO_Running: Yes` (koneksi transfer binlog master aktif).
- `Slave_SQL_Running: Yes` (eksekusi thread SQL slave berjalan lancar).
- `Seconds_Behind_Master: 0` (tidak terjadi lag replikasi).

Uji sinkronisasi dilakukan dengan meng-insert dummy log di `yaga`:
```sql
INSERT INTO db_shibuya_k18.request_logs (client_ip, endpoint, worker_name) VALUES ('192.220.2.10', '/api/test', 'test_worker');
```
Query seketika pada `inumaki` langsung menampilkan record yang sama, membuktikan replikasi database sinkron 100%.

![](assets/13_soal13_mariadb_master_status.png)

![](assets/13_soal13_mariadb_slave_status.png)

![](assets/13_soal13_mariadb_sync_test.png)

---

### Soal 14 - Frontend & API Workers dengan Pembatasan Akses

Di Data Center, beban komputasi web server dipecah menjadi dua klaster independen dengan kontrol akses berbasis IP (`ngx_http_access_module`):
1. **Frontend Workers** (**maki** `192.220.4.3`, **panda** `192.220.4.4`): Menyajikan antarmuka visual dinamis (PHP-FPM). **Hanya boleh diakses oleh reverse proxy gojo (`192.220.1.4`)**.
2. **API Workers** (**nanami** `192.220.4.5`, **todo** `192.220.4.6`, **kirara** `192.220.4.7`): Menyajikan endpoint data JSON dan mencatat riwayat transaksi ke database MariaDB di `yaga`. **Hanya boleh diakses oleh internal load balancer geto (`192.220.4.2`)**.

**Konfigurasi** (`scripts/soal_14.sh`):

Kontrol akses di Frontend (`maki`, `panda`):
```nginx
# /etc/nginx/sites-available/default
server {
    listen 80 default_server;
    server_name jujutsu.k18.com _;

    allow 192.220.1.4; # Hanya Gojo
    allow 127.0.0.1;
    deny all;

    root /var/www/html;
    index index.php index.html;

    location / {
        try_files $uri $uri/ =404;
    }
    location ~ \.php$ {
        include snippets/fastcgi-php.conf;
        fastcgi_pass unix:/run/php/php-fpm.sock;
    }
}
```

Skrip logging & kontrol akses di API Worker (`nanami`, `todo`, `kirara`):
```php
<?php
// /var/www/html/index.php
$client_ip = $_SERVER['HTTP_X_REAL_IP'] ?? $_SERVER['HTTP_X_FORWARDED_FOR'] ?? $_SERVER['REMOTE_ADDR'];
if (strpos($client_ip, ',') !== false) {
    $parts = explode(',', $client_ip);
    $client_ip = trim($parts[0]);
}
$endpoint = $_SERVER['REQUEST_URI'] ?? '/api';
$worker = gethostname(); // nanami / todo / kirara

try {
    $pdo = new PDO("mysql:host=192.220.4.8;dbname=db_shibuya_k18;charset=utf8", "shibuya_user", "shibuya123", [
        PDO::ATTR_TIMEOUT => 2,
        PDO::ATTR_ERRMODE => PDO::ERRMODE_SILENT
    ]);
    $stmt = $pdo->prepare("INSERT INTO request_logs (client_ip, endpoint, worker_name) VALUES (?, ?, ?)");
    $stmt->execute([$client_ip, $endpoint, $worker]);
} catch (Exception $e) {}

header("Content-Type: application/json");
echo json_encode(["status" => "success", "worker" => $worker, "client_ip" => $client_ip, "endpoint" => $endpoint]) . "\n";
?>
```

Nginx API Worker:
```nginx
allow 192.220.4.2; # Hanya Geto
allow 127.0.0.1;
deny all;
```

**Validasi:** Uji keamanan akses langsung vs akses via gateway resmi:
```sh
# Dari itadori (klien luar) mencoba bypass langsung ke worker:
curl -i http://192.220.4.3/   # Frontend maki -> HTTP/1.1 403 Forbidden
curl -i http://192.220.4.5/   # API nanami     -> HTTP/1.1 403 Forbidden

# Dari proxy resmi:
# Gojo -> Maki: HTTP/1.1 200 OK ("Hello from frontend worker: maki")
# Geto -> Nanami: HTTP/1.1 200 OK (JSON status success & logged)
```

Direct access terbukti diblokir secara mutlak (`403 Forbidden`), mengisolasi worker dari paparan langsung jaringan luar.

![](assets/14_soal14_access_denied_403.png)

![](assets/14_soal14_worker_php_response.png)

---

### Soal 15 - Internal Load Balancer Weighted Round Robin 3:1 (geto)

**geto** (`192.220.4.2`) dikonfigurasi sebagai Load Balancer internal yang bertugas membagi request API ke backend cluster dengan algoritma **Weighted Round Robin** rasio **3:1** antara **nanami** (weight 3) dan **todo** (weight 1).

**Konfigurasi** (`scripts/soal_15.sh`, di geto):

```nginx
# /etc/nginx/sites-available/default
upstream api_cluster {
    server 192.220.4.5:80 weight=3; # nanami (75%)
    server 192.220.4.6:80 weight=1; # todo   (25%)
}

server {
    listen 80 default_server;
    server_name jujutsu.k18.com _;

    location / {
        proxy_pass http://api_cluster;
        proxy_set_header Host $host;
        proxy_set_header X-Real-IP $remote_addr;
        proxy_set_header X-Forwarded-For $proxy_add_x_forwarded_for;
    }
}
```

**Validasi:** Pengujian loop 16 request beruntun dari geto:
```sh
for i in $(seq 1 16); do
    curl -s http://192.220.4.2/ | grep -o '"worker":"[^"]*"'
done
```

Distribusi respon:
- `nanami`: 12 kali (75%)
- `todo`: 4 kali (25%)

Pemeriksaan konsistensi pada MariaDB di `yaga`:
```sql
SELECT worker_name, COUNT(*) as total_requests 
FROM db_shibuya_k18.request_logs 
WHERE worker_name IN ('nanami', 'todo') 
GROUP BY worker_name;
```
Hasil query basis data menunjukkan rasio pencatatan tepat 3:1 antara Nanami dan Todo.

![](assets/15_soal15_wrr_test_ratio.png)

![](assets/15_soal15_wrr_db_count.png)

---

### Soal 16 - Public Reverse Proxy dan Path-Based Routing (gojo)

**gojo** (`192.220.1.4`) pada zona DMZ difungsikan sebagai gerbang utama (*Public Reverse Proxy*) domain `jujutsu.k18.com`. Mengimplementasikan perutean berbasis path URL:
- Request root `/` $
ightarrow$ diteruskan ke `frontend_cluster` (**maki** & **panda**) dengan algoritma Round Robin.
- Request `/api` $
ightarrow$ diteruskan ke Internal Load Balancer **geto** (`192.220.4.2`).

**Konfigurasi** (`scripts/soal_16.sh`, di gojo):

```nginx
# /etc/nginx/sites-available/default
upstream frontend_cluster {
    server 192.220.4.3:80; # maki
    server 192.220.4.4:80; # panda
}

server {
    listen 80 default_server;
    server_name jujutsu.k18.com www.jujutsu.k18.com jujutsu.K18.com www.jujutsu.K18.com _;

    # Path-based routing: / -> frontend_cluster
    location / {
        proxy_pass http://frontend_cluster;
        proxy_set_header Host $host;
        proxy_set_header X-Real-IP $remote_addr;
        proxy_set_header X-Forwarded-For $proxy_add_x_forwarded_for;
    }

    # Path-based routing: /api -> geto (Internal Load Balancer)
    location /api {
        proxy_pass http://192.220.4.2;
        proxy_set_header Host $host;
        proxy_set_header X-Real-IP $remote_addr;
        proxy_set_header X-Forwarded-For $proxy_add_x_forwarded_for;
    }
}
```

**Validasi:** Pengujian perutean dari klien `itadori`:
```sh
# Uji path root / (bergantian maki dan panda):
curl -s http://jujutsu.k18.com/
# Output: "Hello from frontend worker: maki"
curl -s http://jujutsu.k18.com/
# Output: "Hello from frontend worker: panda"

# Uji path /api (diteruskan ke geto lalu ke worker API):
curl -s http://jujutsu.k18.com/api
# Output: {"status":"success","worker":"nanami",...}
```

Path root `/` terbukti bergantian secara adil antara Maki dan Panda, sedangkan `/api` terisolasi dan dialihkan dengan sempurna ke Geto.

![](assets/16_soal16_path_routing_frontend.png)

![](assets/16_soal16_path_routing_api.png)

---

### Soal 17 - Preservasi Real Client IP Logging

Pada arsitektur *multi-tier proxy* (Klien $
ightarrow$ Gojo $
ightarrow$ Geto $
ightarrow$ Worker), tanpa manipulasi header, worker di Data Center akan mendeteksi IP `geto` (`192.220.4.2`) sebagai alamat asal request. Mekanisme penerusan identitas klien asli diimplementasikan menggunakan header `X-Real-IP` dan `X-Forwarded-For` serta modul `ngx_http_realip_module`.

**Konfigurasi** (`scripts/soal_17.sh`):

Di **gojo**:
```nginx
proxy_set_header X-Real-IP $remote_addr;
proxy_set_header X-Forwarded-For $proxy_add_x_forwarded_for;
```

Di **geto** (mempercayai proxy Gojo dan mengurai header Forwarded):
```nginx
# /etc/nginx/sites-available/default
set_real_ip_from 192.220.1.4; # IP Gojo yang dipercaya
real_ip_header X-Forwarded-For;
real_ip_recursive on;
```

Di **Worker API PHP**: Membaca elemen pertama dari rantai IP yang diteruskan untuk mengisolasi IP asli pengirim.

**Validasi:** Pengujian dilakukan dengan mengirim request dari dua klien di divisi berbeda:
1. `itadori` (Divisi A, IP: `192.220.2.10`)
2. `kusakabe` (Divisi B, IP: `192.220.3.91`)

```sh
# Dari itadori:
curl -s http://jujutsu.k18.com/api

# Dari kusakabe:
curl -s http://jujutsu.k18.com/api
```

Pemeriksaan rekaman log pada database MariaDB di `yaga`:
```sql
SELECT id, client_ip, endpoint, worker_name, created_at 
FROM db_shibuya_k18.request_logs 
ORDER BY id DESC LIMIT 2;
```

| ID | client_ip | endpoint | worker_name | created_at |
|:---:|:---:|:---:|:---:|:---:|
| 104 | 192.220.3.91 | /api | nanami | 2026-10-15 13:20:11 |
| 103 | 192.220.2.10 | /api | todo | 2026-10-15 13:20:08 |

Kolom `client_ip` mencatat alamat IP asli klien secara akurat (`192.220.2.10` dan `192.220.3.91`), membuktikan rantai preservasi Real IP berhasil beroperasi menembus dua lapisan reverse proxy.

![](assets/17_soal17_real_ip_curl.png)

![](assets/17_soal17_real_ip_db_log.png)

---

### Soal 18 - Kirara sebagai Backup Worker & Passive Health Check

Untuk menjamin ketersediaan tinggi (*High Availability*), **kirara** (`192.220.4.7`) dikonfigurasi sebagai *backup worker* pada cluster API di geto. Jika worker utama (`nanami` dan `todo`) mengalami *failure*, geto secara otomatis mengalihkan beban ke kirara secara *seamless* tanpa memicu error `502 Bad Gateway`.

**Konfigurasi** (`scripts/soal_18.sh`, di geto):

```nginx
# /etc/nginx/sites-available/default
upstream api_cluster {
    server 192.220.4.5:80 weight=3 max_fails=2 fail_timeout=5s; # nanami
    server 192.220.4.6:80 weight=1 max_fails=2 fail_timeout=5s; # todo
    server 192.220.4.7:80 backup;                               # kirara (standby)
}

server {
    listen 80 default_server;
    server_name jujutsu.k18.com _;

    location / {
        proxy_pass http://api_cluster;
        # Failover otomatis jika upstream bermasalah
        proxy_next_upstream error timeout invalid_header http_500 http_502 http_503 http_504;
        proxy_set_header Host $host;
        proxy_set_header X-Real-IP $remote_addr;
        proxy_set_header X-Forwarded-For $proxy_add_x_forwarded_for;
    }
}
```

**Validasi:** Pengujian *failover* pasif:
1. **Kondisi Normal:** Kirara tidak menerima trafik sama sekali.
2. **Simulasi Downtime:** Layanan Nginx dihentikan pada worker utama:
   ```sh
   # Di nanami & todo:
   service nginx stop
   ```
3. **Pengujian Klien:** Klien `itadori` mengirim request ke `http://jujutsu.k18.com/api`.
   Respon yang diterima:
   ```json
   {"status":"success","worker":"kirara","client_ip":"192.220.2.10","endpoint":"/api"}
   ```
   Status kode HTTP tetap `200 OK` tanpa adanya request yang drop / 502.
4. **Verifikasi Database:** Record baru tercatat di MariaDB `yaga` dengan `worker_name = 'kirara'`.
5. **Pemulihan (*Recovery*):** Begitu Nginx di nanami dan todo dinyalakan kembali, trafik otomatis kembali ke Nanami dan Todo, sedangkan Kirara kembali ke status *standby*.

![](assets/18_soal18_failover_test.png)

![](assets/18_soal18_kirara_db_records.png)

---

### Soal 19 - Proxy Caching dan Rate Limiting (gojo)

Untuk mengoptimalkan performa gerbang publik dan memitigasi potensi serangan DoS (*Denial of Service*), dua mekanisme diterapkan pada **gojo**:
1. **Proxy Caching:** Konten visual frontend pada path `/` di-*cache* selama 10 menit (`proxy_cache_valid 200 302 10m`) untuk mengurangi latensi dan beban server backend.
2. **Rate Limiting:** Akses ke endpoint sensitif `/api` dibatasi maksimal **10 request per detik** per IP klien (`rate=10r/s`), dengan toleransi lonjakan burst 5 request (`nodelay`). Kelebihan request langsung dipotong dengan respon HTTP `503 Service Unavailable`.

**Konfigurasi** (`scripts/soal_19.sh`, di gojo):

Zona memori cache dan rate limit di `/etc/nginx/conf.d/cache_and_limit.conf`:
```nginx
# Cache zone 10MB di disk /var/cache/nginx/web
proxy_cache_path /var/cache/nginx/web levels=1:2 keys_zone=web_cache:10m max_size=100m inactive=60m use_temp_path=off;

# Rate limit zone 10MB berbasis IP klien
limit_req_zone $binary_remote_addr zone=api_limit:10m rate=10r/s;
```

Blok server di `/etc/nginx/sites-available/default`:
```nginx
location / {
    proxy_pass http://frontend_cluster;
    proxy_cache web_cache;
    proxy_cache_valid 200 302 10m;
    proxy_cache_use_stale error timeout updating http_500 http_502 http_503 http_504;
    proxy_ignore_headers Cache-Control Expires Set-Cookie;
    proxy_hide_header Set-Cookie;
    add_header X-Cache-Status $upstream_cache_status always;
}

location /api {
    # Rate Limiting
    limit_req zone=api_limit burst=5 nodelay;
    limit_req_status 503;

    proxy_pass http://192.220.4.2;
    proxy_set_header Host $host;
    proxy_set_header X-Real-IP $remote_addr;
    proxy_set_header X-Forwarded-For $proxy_add_x_forwarded_for;
}
```

**Validasi:**

1. **Uji Caching Frontend:**
```sh
# Request pertama (Cache belum ada):
curl -s -i http://jujutsu.k18.com/ | grep -E "HTTP/|X-Cache-Status"
# HTTP/1.1 200 OK
# X-Cache-Status: MISS

# Request kedua (Disajikan dari cache):
curl -s -i http://jujutsu.k18.com/ | grep -E "HTTP/|X-Cache-Status"
# HTTP/1.1 200 OK
# X-Cache-Status: HIT
```

2. **Uji Rate Limiting API (20 Request Cepat):**
```sh
for i in $(seq 1 20); do
    curl -s -o /dev/null -w "%{http_code} " http://jujutsu.k18.com/api
done
```
Output:
```text
200 200 200 200 200 200 200 200 503 503 503 503 503 200 503 503 503 503 503 503
```
Analisis: 8 request pertama lolos (kuota awal + burst), kemudian request ke-9 dan seterusnya ditolak langsung dengan kode status `503 Service Unavailable`, membuktikan algoritma *leaky bucket* Nginx aktif melindungi backend.

![](assets/19_soal19_cache_miss_hit.png)

![](assets/19_soal19_rate_limiting_burst.png)

---

### Soal 20 - Uji Beban & Performa Menggunakan Apache Benchmark

Kinerja arsitektur yang telah diimplementasikan diuji secara terukur dari node klien **kusakabe** (`192.220.3.91`) menggunakan utilitas `ab` (*Apache Benchmark*) dengan skenario beban tinggi: **600 request total** dengan **30 request bersamaan** (`ab -n 600 -c 30`).

**Konfigurasi** (`scripts/soal_20.sh`, di kusakabe):
```sh
apk update && apk add apache2-utils

# Uji 1: Frontend Caching
ab -n 600 -c 30 http://jujutsu.k18.com/ > /root/benchmark_frontend.txt 2>&1

# Uji 2: API Rate Limiting
ab -n 600 -c 30 http://jujutsu.k18.com/api > /root/benchmark_api.txt 2>&1
```

**Hasil Pengujian & Analisis:**

#### **1. Benchmark Frontend Caching (`http://jujutsu.k18.com/`)**
```text
Concurrency Level:      30
Time taken for tests:   0.083 seconds
Complete requests:      600
Failed requests:        0
HTML transferred:       19800 bytes
Requests per second:    7186.49 [#/sec] (mean)
Time per request:       4.175 [ms] (mean)
Time per request:       0.139 [ms] (mean, across all concurrent requests)
Transfer rate:          2386.45 [Kbytes/sec] received
```
* **Analisis Kinerja:** 100% request sukses tanpa kegagalan (0 *failed requests*). Karena Gojo menyajikan halaman langsung dari memori *Proxy Cache*, server mampu mencapai *throughput* fantastis sebesar **7.186,49 Requests/detik** dengan rata-rata waktu respon hanya **4,17 ms**. Backend worker Maki dan Panda sama sekali tidak terbebani oleh lonjakan 600 request ini.

#### **2. Benchmark API Rate Limiting (`http://jujutsu.k18.com/api`)**
```text
Concurrency Level:      30
Time taken for tests:   0.106 seconds
Complete requests:      600
Failed requests:        595
Non-2xx responses:      593
Requests per second:    5660.75 [#/sec] (mean)
Time per request:       5.300 [ms] (mean)
Time per request:       0.177 [ms] (mean, across all concurrent requests)
```
* **Analisis Pertahanan:** Dari 600 request yang dikirimkan secara serentak, sebanyak 593 request ditolak dengan kode status HTTP `503 Service Unavailable`. Nginx pada Gojo membatasi aliran trafik sesuai kuota (10 r/s burst 5), sehingga hanya request yang sah yang diteruskan ke Geto dan Database Yaga. Hal ini menjamin infrastruktur Data Center terhindar dari *crash* atau *starvation* akibat banjir request (DoS).

#### **3. Bukti Verifikasi Access Log pada Gojo (`/var/log/nginx/access.log`)**
```text
192.220.3.91 - - [15/Oct/2026:13:24:55 +0000] "GET /api HTTP/1.0" 503 190 "-" "ApacheBench/2.3"
192.220.3.91 - - [15/Oct/2026:13:24:55 +0000] "GET /api HTTP/1.0" 503 190 "-" "ApacheBench/2.3"
...
192.220.3.91 - - [15/Oct/2026:13:24:55 +0000] "GET /api HTTP/1.0" 200 84 "-" "ApacheBench/2.3"
```
Log akses pada reverse proxy Gojo mengonfirmasi bahwa penolakan lonjakan request dicatat dengan kode status `503`, dan kembali menyajikan kode status `200` saat jendela waktu laju request (*rate window*) kembali tersedia.

![](assets/20_soal20_ab_frontend.png)

![](assets/20_soal20_ab_api.png)

![](assets/20_soal20_access_log.png)
