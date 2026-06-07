# ============================================================
# BLOCK 1: ROUTER – MikroTik CCR2004-16G-2S+
# RouterOS v7
# ============================================================
#
# VLAN MAPPING TABLE:
# +------+-------------+--------------------+------------------------------+------+
# | VLAN | Name        | Gateway/Prefix     | DHCP Pool                    | DHCP |
# +------+-------------+--------------------+------------------------------+------+
# |   10 | Management  | 192.168.10.1/24    | (static only)                |  No  |
# |   20 | Wifi Guest  | 172.16.20.1/22     | 172.16.20.100-172.16.23.200  |  Yes |
# |   40 | IPTV Cloud  | 172.16.40.1/24     | 172.16.40.100-172.16.40.200  |  Yes |
# |   50 | IP Phone    | 172.16.50.1/24     | 172.16.50.100-172.16.50.200  |  Yes |
# |   60 | Office+WiFi | 192.168.0.1/24     | 192.168.0.100-192.168.0.200  |  Yes |
# |   70 | CCTV        | 192.168.5.1/24     | (static only)                |  No  |
# +------+-------------+--------------------+------------------------------+------+
#
# PORT MAPPING TABLE:
# +----------------+-----------------------------------------------+
# | Interface      | Role                                          |
# +----------------+-----------------------------------------------+
# | sfp-sfpplus2   | WAN PRIMARY – PPPoE Viettel (đường chính)     |
# | ether1         | WAN BACKUP  – PPPoE dự phòng (failover)        |
# | sfp-sfpplus1   | Trunk to Core CRS326 (S+31DLC10D 10G SMF)    |
# | ether2         | VLAN 10 ACCESS – Management (direct PC access)|
# | ether3-ether10 | Reserved (not used)                           |
# | ether11-ether16| VLAN 70 ACCESS – Camera/NVR (untagged pvid=70)|
# +----------------+-----------------------------------------------+
#
# CCTV STATIC IP:
#   NVR-1  : 192.168.5.254  (web port 8054) – internet allowed
#   NVR-2  : 192.168.5.253  (web port 8053) – internet allowed
#   Camera : 192.168.5.1-100               – internet BLOCKED
# ============================================================

# ============================================================
# STEP 1: RESET (chạy TAY trước khi import file này)
# ============================================================
# /system reset-configuration no-defaults=yes skip-backup=yes
# Sau reboot → /import file-name=router-ccr2004.rsc

# ============================================================
# STEP 2: BRIDGE + VLAN FILTERING
# ============================================================
/interface bridge
add name=bridge-lan vlan-filtering=yes priority=8192 \
    igmp-snooping=yes \
    comment="Main LAN bridge – Secondary Root priority=8192"

/interface bridge port
add bridge=bridge-lan interface=sfp-sfpplus1 \
    frame-types=admit-only-vlan-tagged \
    comment="Trunk uplink to Core CRS326"
add bridge=bridge-lan interface=ether2 \
    pvid=10 frame-types=admit-only-untagged-and-priority-tagged \
    comment="VLAN10 Management – direct PC access"
add bridge=bridge-lan interface=ether11 \
    pvid=70 frame-types=admit-only-untagged-and-priority-tagged \
    comment="VLAN70 CCTV access"
add bridge=bridge-lan interface=ether12 \
    pvid=70 frame-types=admit-only-untagged-and-priority-tagged \
    comment="VLAN70 CCTV access"
add bridge=bridge-lan interface=ether13 \
    pvid=70 frame-types=admit-only-untagged-and-priority-tagged \
    comment="VLAN70 CCTV access"
add bridge=bridge-lan interface=ether14 \
    pvid=70 frame-types=admit-only-untagged-and-priority-tagged \
    comment="VLAN70 CCTV access"
add bridge=bridge-lan interface=ether15 \
    pvid=70 frame-types=admit-only-untagged-and-priority-tagged \
    comment="VLAN70 CCTV access"
add bridge=bridge-lan interface=ether16 \
    pvid=70 frame-types=admit-only-untagged-and-priority-tagged \
    comment="VLAN70 CCTV access"

# ============================================================
# STEP 3: BRIDGE VLAN TABLE
# NOTE: "bridge-lan" entry = CPU port (must be tagged for all
#       VLANs so sub-interfaces bridge-lan.XX can receive traffic)
# ============================================================
/interface bridge vlan
add bridge=bridge-lan vlan-ids=10 \
    tagged=bridge-lan,sfp-sfpplus1 \
    untagged=ether2
add bridge=bridge-lan vlan-ids=20 \
    tagged=bridge-lan,sfp-sfpplus1
add bridge=bridge-lan vlan-ids=40 \
    tagged=bridge-lan,sfp-sfpplus1
add bridge=bridge-lan vlan-ids=50 \
    tagged=bridge-lan,sfp-sfpplus1
add bridge=bridge-lan vlan-ids=60 \
    tagged=bridge-lan,sfp-sfpplus1
add bridge=bridge-lan vlan-ids=70 \
    tagged=bridge-lan,sfp-sfpplus1 \
    untagged=ether11,ether12,ether13,ether14,ether15,ether16

# ============================================================
# STEP 4: VLAN SUB-INTERFACES + IP ADDRESSES
# ============================================================
/interface vlan
add interface=bridge-lan vlan-id=10 name=bridge-lan.10 comment="VLAN10 Management"
add interface=bridge-lan vlan-id=20 name=bridge-lan.20 comment="VLAN20 Wifi Guest"
add interface=bridge-lan vlan-id=40 name=bridge-lan.40 comment="VLAN40 IPTV Cloud"
add interface=bridge-lan vlan-id=50 name=bridge-lan.50 comment="VLAN50 IP Phone"
add interface=bridge-lan vlan-id=60 name=bridge-lan.60 comment="VLAN60 Office+WiFi Mgmt"
add interface=bridge-lan vlan-id=70 name=bridge-lan.70 comment="VLAN70 CCTV"

/ip address
add address=192.168.10.1/24 interface=bridge-lan.10 comment="VLAN10 Management GW"
add address=172.16.20.1/22  interface=bridge-lan.20 comment="VLAN20 Wifi Guest GW"
add address=172.16.40.1/24  interface=bridge-lan.40 comment="VLAN40 IPTV GW"
add address=172.16.50.1/24  interface=bridge-lan.50 comment="VLAN50 IP Phone GW"
add address=192.168.0.1/24  interface=bridge-lan.60 comment="VLAN60 Office+WiFi Mgmt GW"
add address=192.168.5.1/24  interface=bridge-lan.70 comment="VLAN70 CCTV GW"

# ============================================================
# STEP 5: PPPOE WAN – PRIMARY (VIETTEL) + BACKUP FAILOVER
# Primary  : sfp-sfpplus2 (distance=1) – đường Viettel chính (ưu tiên)
# Backup   : ether1       (distance=2) – đường dự phòng, tự động lên khi primary down
# RouterOS xóa route distance=1 khi pppoe-wan (Viettel) down → traffic chuyển
# sang pppoe-backup (distance=2) tự động, không cần script thêm.
# ============================================================
/interface pppoe-client
add interface=sfp-sfpplus2 name=pppoe-wan \
    user=abcd password="abcd88qưe" \
    add-default-route=yes default-route-distance=1 \
    use-peer-dns=no disabled=no \
    comment="WAN PRIMARY PPPoE Viettel – sfp-sfpplus2 (đường chính)"
add interface=ether1 name=pppoe-backup \
    user=abcd password="abcd88qưe" \
    add-default-route=yes default-route-distance=2 \
    use-peer-dns=no disabled=no \
    comment="WAN BACKUP PPPoE – ether1 (đường dự phòng, failover)"

# ============================================================
# STEP 6: DNS
# ============================================================
/ip dns
set servers=8.8.8.8,1.1.1.1 allow-remote-requests=no

# ============================================================
# STEP 7: DHCP SERVERS
# ============================================================

# --- VLAN 20: Wifi Guest ---
/ip pool
add name=pool-vlan20 ranges=172.16.20.100-172.16.23.200
/ip dhcp-server
add name=dhcp-vlan20 interface=bridge-lan.20 address-pool=pool-vlan20 \
    lease-time=1d disabled=no
/ip dhcp-server network
add address=172.16.20.0/22 gateway=172.16.20.1 \
    dns-server=8.8.8.8,1.1.1.1 comment="VLAN20 Wifi Guest"

# --- VLAN 40: IPTV Cloud ---
/ip pool
add name=pool-vlan40 ranges=172.16.40.100-172.16.40.200
/ip dhcp-server
add name=dhcp-vlan40 interface=bridge-lan.40 address-pool=pool-vlan40 \
    lease-time=1d disabled=no
/ip dhcp-server network
add address=172.16.40.0/24 gateway=172.16.40.1 \
    dns-server=8.8.8.8,1.1.1.1 comment="VLAN40 IPTV Cloud"

# --- VLAN 50: IP Phone (with Option 66 – SIP provisioning) ---
/ip pool
add name=pool-vlan50 ranges=172.16.50.100-172.16.50.200
/ip dhcp-server option
add name=opt66-sip code=66 value="'172.16.50.10'" comment="SIP provisioning server"
/ip dhcp-server
add name=dhcp-vlan50 interface=bridge-lan.50 address-pool=pool-vlan50 lease-time=1d disabled=no
/ip dhcp-server network
add address=172.16.50.0/24 gateway=172.16.50.1 dns-server=8.8.8.8,1.1.1.1 dhcp-option=opt66-sip comment="VLAN50 IP Phone"

# --- VLAN 60: Office + WiFi Management ---
/ip pool
add name=pool-vlan60 ranges=192.168.0.100-192.168.0.200
/ip dhcp-server
add name=dhcp-vlan60 interface=bridge-lan.60 address-pool=pool-vlan60 \
    lease-time=1d disabled=no
/ip dhcp-server network
add address=192.168.0.0/24 gateway=192.168.0.1 \
    dns-server=8.8.8.8,1.1.1.1 comment="VLAN60 Office+WiFi Mgmt"

# NOTE: VLAN 10 (Management) – NO DHCP (static only)
# NOTE: VLAN 70 (CCTV)       – NO DHCP (static only)

# ============================================================
# STEP 8: NTP + TIMEZONE
# ============================================================
/system ntp client
set enabled=yes
/system ntp client servers
add address=time.google.com comment="Google NTP"
add address=time.cloudflare.com comment="Cloudflare NTP"
/system clock
set time-zone-name=Asia/Ho_Chi_Minh

# ============================================================
# STEP 9: WIREGUARD VPN
# RouterOS v7 auto-generates private key on creation.
# After applying, run: /interface wireguard print
# Copy "public-key" value and send to VPN peer (vanhau).
# ============================================================
/interface wireguard
add name=wg-vpn listen-port=13231 comment="WireGuard VPN – client-to-site"

# Peer vanhau: chạy tay sau khi có public key từ client
# -------------------------------------------------------
# Bước 1: /interface wireguard print → copy public-key → gửi cho vanhau
# Bước 2: vanhau chạy: wg genkey | tee privatekey | wg pubkey > publickey
# Bước 3: Admin chạy:
#   /interface wireguard peers
#   add interface=wg-vpn name=vanhau \
#       public-key="<DAN_PUBLIC_KEY_CUA_VANHAU_VAO_DAY>" \
#       allowed-address=10.10.10.2/32 \
#       persistent-keepalive=25

/ip address
add address=10.10.10.1/24 interface=wg-vpn comment="WireGuard VPN server IP"

# ---- CLIENT CONFIG TEMPLATE FOR VANHAU ----
# [Interface]
# PrivateKey = <VANHAU_PRIVATE_KEY>
# Address    = 10.10.10.2/24
# DNS        = 8.8.8.8
#
# [Peer]
# PublicKey           = <SERVER_PUBLIC_KEY>
# Endpoint            = <WAN_IP>:13231
# AllowedIPs          = 10.10.10.0/24,
#                       192.168.10.0/24,
#                       192.168.0.0/24,
#                       192.168.5.0/24
# PersistentKeepalive = 25
# ---- END CLIENT CONFIG TEMPLATE ----

# ============================================================
# STEP 10: INTERFACE LISTS
# ============================================================
/interface list
add name=WAN  comment="WAN interfaces – primary + backup"
add name=LAN  comment="LAN VLAN interfaces"
add name=MGMT comment="Management only – VLAN10"
/interface list member
add interface=pppoe-wan     list=WAN
add interface=pppoe-backup  list=WAN
add interface=bridge-lan.10 list=LAN
add interface=bridge-lan.20 list=LAN
add interface=bridge-lan.40 list=LAN
add interface=bridge-lan.50 list=LAN
add interface=bridge-lan.60 list=LAN
add interface=bridge-lan.70 list=LAN
add interface=wg-vpn        list=LAN
add interface=bridge-lan.10 list=MGMT

# ============================================================
# STEP 11: ADDRESS LIST – LOCAL_NETS
# ============================================================
/ip firewall address-list
add list=LOCAL_NETS address=172.16.20.0/22  comment="VLAN20 Wifi Guest"
add list=LOCAL_NETS address=172.16.40.0/24  comment="VLAN40 IPTV Cloud"
add list=LOCAL_NETS address=172.16.50.0/24  comment="VLAN50 IP Phone"
add list=LOCAL_NETS address=192.168.0.0/24  comment="VLAN60 Office+WiFi Mgmt"
add list=LOCAL_NETS address=192.168.10.0/24 comment="VLAN10 Management"
add list=LOCAL_NETS address=10.10.10.0/24   comment="VPN pool"

# ============================================================
# STEP 12: FIREWALL – CHAIN INPUT
# ============================================================
/ip firewall filter

# R1: Accept established/related
add chain=input action=accept \
    connection-state=established,related \
    comment="R1 Accept established/related"

# R2: Drop invalid
add chain=input action=drop \
    connection-state=invalid \
    comment="R2 Drop invalid"

# R3: Drop IP trong blacklist brute-force
add chain=input action=drop \
    src-address-list=brute_force \
    log=yes log-prefix="BF-DROP: " \
    comment="R3 Drop brute-force blacklisted IPs"

# R4: Stage 3 – blacklist 1h
add chain=input action=add-src-to-address-list \
    protocol=tcp dst-port=22,8291 connection-state=new \
    src-address-list=bf_stage2 \
    address-list=brute_force address-list-timeout=1h \
    comment="R4 Brute-force stage3 – blacklist 1h"

# R5: Stage 2
add chain=input action=add-src-to-address-list \
    protocol=tcp dst-port=22,8291 connection-state=new \
    src-address-list=bf_stage1 \
    address-list=bf_stage2 address-list-timeout=1m \
    comment="R5 Brute-force stage2"

# R6: Stage 1
add chain=input action=add-src-to-address-list \
    protocol=tcp dst-port=22,8291 connection-state=new \
    address-list=bf_stage1 address-list-timeout=1m \
    comment="R6 Brute-force stage1"

# R7: ICMP from LAN rate-limited
add chain=input action=accept \
    protocol=icmp in-interface-list=LAN \
    limit=10,5:packet \
    comment="R7 ICMP from LAN rate-limited 10pps"

# R8: Drop excess ICMP
add chain=input action=drop \
    protocol=icmp in-interface-list=LAN \
    comment="R8 Drop excess ICMP from LAN"

# R9: Winbox từ VLAN10
add chain=input action=accept \
    protocol=tcp dst-port=8291 src-address=192.168.10.0/24 \
    comment="R9 Winbox from VLAN10"

# R10: SSH từ VLAN10
add chain=input action=accept \
    protocol=tcp dst-port=22 src-address=192.168.10.0/24 \
    comment="R10 SSH from VLAN10"

# R9b: Winbox từ VLAN60 Office
add chain=input action=accept \
    protocol=tcp dst-port=8291 src-address=192.168.0.0/24 \
    comment="R9b Winbox from VLAN60 Office"

# R10b: SSH từ VLAN60 Office
add chain=input action=accept \
    protocol=tcp dst-port=22 src-address=192.168.0.0/24 \
    comment="R10b SSH from VLAN60 Office"

# R11: Winbox từ VPN
add chain=input action=accept \
    protocol=tcp dst-port=8291 src-address=10.10.10.0/24 \
    comment="R11 Winbox from VPN"

# R12: SSH từ VPN
add chain=input action=accept \
    protocol=tcp dst-port=22 src-address=10.10.10.0/24 \
    comment="R12 SSH from VPN"

# R13: WireGuard handshake từ WAN
add chain=input action=accept \
    protocol=udp dst-port=13231 in-interface-list=WAN \
    comment="R13 WireGuard UDP 13231 from WAN"

# R14: Block Winbox từ WAN
add chain=input action=drop \
    protocol=tcp dst-port=8291 in-interface-list=WAN \
    log=yes log-prefix="WAN-WINBOX: " \
    comment="R14 Drop Winbox from WAN"

# R15: Block SSH từ WAN
add chain=input action=drop \
    protocol=tcp dst-port=22 in-interface-list=WAN \
    log=yes log-prefix="WAN-SSH: " \
    comment="R15 Drop SSH from WAN"

# R16: Block Telnet từ WAN
add chain=input action=drop \
    protocol=tcp dst-port=23 in-interface-list=WAN \
    log=yes log-prefix="WAN-TELNET: " \
    comment="R16 Drop Telnet from WAN"

# R17: Block API từ WAN
add chain=input action=drop \
    protocol=tcp dst-port=8728,8729 in-interface-list=WAN \
    log=yes log-prefix="WAN-API: " \
    comment="R17 Drop API/API-SSL from WAN"

# R18: Block HTTP/HTTPS management từ WAN
add chain=input action=drop \
    protocol=tcp dst-port=80,443 in-interface-list=WAN \
    log=yes log-prefix="WAN-HTTP: " \
    comment="R18 Drop HTTP/HTTPS from WAN"

# R19: Drop tất cả WAN còn lại
add chain=input action=drop \
    in-interface-list=WAN \
    log=yes log-prefix="WAN-INPUT-DROP: " \
    comment="R19 Drop all from WAN"

# R20: Default drop INPUT
add chain=input action=drop \
    comment="R20 Default drop INPUT"

# ============================================================
# STEP 13: FIREWALL – CHAIN FORWARD
# ============================================================

# R1: Accept established/related
add chain=forward action=accept \
    connection-state=established,related \
    comment="R1 Accept established/related"

# R2: Drop invalid
add chain=forward action=drop \
    connection-state=invalid \
    comment="R2 Drop invalid"

# R2a: Drop SYN flood blacklist
add chain=forward action=drop \
    src-address-list=syn_flood \
    in-interface-list=WAN \
    log=yes log-prefix="SYN-FLOOD-DROP: " \
    comment="R2a Drop SYN flood blacklisted IPs"

# R2b: Detect SYN flood >50/s
add chain=forward action=add-src-to-address-list \
    protocol=tcp tcp-flags=syn connection-state=new \
    in-interface-list=WAN \
    limit=50,100:packet \
    address-list=syn_flood address-list-timeout=2m \
    comment="R2b Detect SYN flood >50/s per IP"

# R2c: Connection limit >100
add chain=forward action=drop \
    protocol=tcp connection-limit=100,32 \
    in-interface-list=WAN \
    log=yes log-prefix="CONN-LIMIT: " \
    comment="R2c Drop if WAN src >100 concurrent TCP connections"

# R2d: Accept port-forwarding (DSTNAT) từ WAN
add chain=forward action=accept \
    in-interface-list=WAN connection-state=new \
    connection-nat-state=dstnat \
    comment="R2d Accept new WAN connections via DSTNAT (port forwarding)"

# R2e: Drop WAN mới không qua DSTNAT
add chain=forward action=drop \
    in-interface-list=WAN connection-state=new \
    log=yes log-prefix="WAN-NEW-DROP: " \
    comment="R2e Drop new connections from WAN (not DSTNAT'd)"

# R3: VLAN10 admin full access
add chain=forward action=accept \
    src-address=192.168.10.0/24 \
    comment="R3 VLAN10 admin full access"

# R4: VLAN60 → VLAN10
add chain=forward action=accept \
    src-address=192.168.0.0/24 dst-address=192.168.10.0/24 \
    comment="R4 VLAN60 can reach VLAN10"

# R5: VPN → VLAN10
add chain=forward action=accept \
    src-address=10.10.10.0/24 dst-address=192.168.10.0/24 \
    comment="R5 VPN access VLAN10"

# R6: VPN → VLAN60
add chain=forward action=accept \
    src-address=10.10.10.0/24 dst-address=192.168.0.0/24 \
    comment="R6 VPN access VLAN60"

# R7: VPN → NVR-1:8054
add chain=forward action=accept protocol=tcp \
    src-address=10.10.10.0/24 dst-address=192.168.5.254 dst-port=8054 \
    comment="R7 VPN access NVR-1:8054"

# R8: VPN → NVR-2:8053
add chain=forward action=accept protocol=tcp \
    src-address=10.10.10.0/24 dst-address=192.168.5.253 dst-port=8053 \
    comment="R8 VPN access NVR-2:8053"

# R9: Drop VPN còn lại
add chain=forward action=drop \
    src-address=10.10.10.0/24 \
    comment="R9 Drop VPN traffic not matched above"

# R10: VLAN20 Guest → internet
add chain=forward action=accept \
    src-address=172.16.20.0/22 out-interface-list=WAN \
    comment="R10 VLAN20 Guest internet"

# R11: VLAN40 IPTV → internet
add chain=forward action=accept \
    src-address=172.16.40.0/24 out-interface-list=WAN \
    comment="R11 VLAN40 IPTV internet"

# R12: VLAN60 Office → internet
add chain=forward action=accept \
    src-address=192.168.0.0/24 out-interface-list=WAN \
    comment="R12 VLAN60 Office internet"

# R13: VLAN50 SIP nội bộ
add chain=forward action=accept protocol=tcp \
    src-address=172.16.50.0/24 dst-address=172.16.50.10 dst-port=5060 \
    comment="R13 VoIP SIP TCP internal"
add chain=forward action=accept protocol=udp \
    src-address=172.16.50.0/24 dst-address=172.16.50.10 dst-port=5060 \
    comment="R13 VoIP SIP UDP internal"

# R14: VLAN50 RTP nội bộ
add chain=forward action=accept protocol=udp \
    src-address=172.16.50.0/24 dst-address=172.16.50.10 dst-port=10000-20000 \
    comment="R14 VoIP RTP internal"

# R15: VLAN50 SIP → WAN
add chain=forward action=accept protocol=tcp \
    src-address=172.16.50.0/24 out-interface-list=WAN dst-port=5060 \
    comment="R15 VoIP SIP TCP to WAN"
add chain=forward action=accept protocol=udp \
    src-address=172.16.50.0/24 out-interface-list=WAN dst-port=5060 \
    comment="R15 VoIP SIP UDP to WAN"

# R16: VLAN50 RTP → WAN
add chain=forward action=accept protocol=udp \
    src-address=172.16.50.0/24 out-interface-list=WAN dst-port=10000-20000 \
    comment="R16 VoIP RTP to WAN"

# R17: NVR-1 → internet
add chain=forward action=accept \
    src-address=192.168.5.254 out-interface-list=WAN \
    comment="R17 NVR-1 internet access"

# R18: NVR-2 → internet
add chain=forward action=accept \
    src-address=192.168.5.253 out-interface-list=WAN \
    comment="R18 NVR-2 internet access"

# R19: Block camera khỏi internet (NVR đã accept ở R17/R18)
add chain=forward action=drop \
    src-address=192.168.5.0/24 out-interface-list=WAN \
    comment="R19 Drop CCTV cameras to internet"

# R20: VLAN10 → VLAN70 CCTV
add chain=forward action=accept \
    src-address=192.168.10.0/24 dst-address=192.168.5.0/24 \
    comment="R20 VLAN10 admin full access to CCTV"

# R21: LOCAL_NETS → NVR-1:8054 (Hairpin A + B – ENABLED)
# Dùng cho cả Option A (direct LAN IP) và Option B (sau DSTNAT Hairpin-B)
add chain=forward action=accept protocol=tcp \
    src-address-list=LOCAL_NETS dst-address=192.168.5.254 dst-port=8054 \
    comment="R21 LOCAL_NETS NVR-1:8054 [Hairpin A+B]"

# R22: LOCAL_NETS → NVR-2:8053 (Hairpin A + B – ENABLED)
add chain=forward action=accept protocol=tcp \
    src-address-list=LOCAL_NETS dst-address=192.168.5.253 dst-port=8053 \
    comment="R22 LOCAL_NETS NVR-2:8053 [Hairpin A+B]"

# R23: Default deny FORWARD
add chain=forward action=drop \
    log=yes log-prefix="FWD-DROP: " \
    comment="R23 Default deny FORWARD"

# ============================================================
# STEP 14: NAT – DST-NAT (Port Forwarding + Hairpin)
#
# Option A (R21/R22 FORWARD): LAN → NVR LAN IP trực tiếp (không cần NAT)
# Option B (bên dưới): LAN → IP public → redirect về NVR LAN IP
#   → Dùng khi client dùng IP public (VD: 117.2.11.52:8054) từ nội bộ
# ============================================================
/ip firewall nat

# WAN Port Forwarding (internet → NVR)
add chain=dstnat action=dst-nat \
    in-interface-list=WAN protocol=tcp dst-port=8054 \
    to-addresses=192.168.5.254 to-ports=8054 \
    comment="DSTNAT WAN:8054 to NVR-1"

add chain=dstnat action=dst-nat \
    in-interface-list=WAN protocol=tcp dst-port=8053 \
    to-addresses=192.168.5.253 to-ports=8053 \
    comment="DSTNAT WAN:8053 to NVR-2"

# Hairpin Option B – LAN truy cập NVR qua IP public (ENABLED)
# Bắt gói tin từ LOCAL_NETS đến port 8054/8053 (dù dst-address là IP public nào)
# và redirect về IP LAN của NVR. Không cần hardcode IP public (dynamic-safe).
add chain=dstnat action=dst-nat \
    src-address-list=LOCAL_NETS protocol=tcp dst-port=8054 \
    to-addresses=192.168.5.254 to-ports=8054 \
    comment="DSTNAT Hairpin-B NVR-1 (LAN → public IP → NVR, ENABLED)"

add chain=dstnat action=dst-nat \
    src-address-list=LOCAL_NETS protocol=tcp dst-port=8053 \
    to-addresses=192.168.5.253 to-ports=8053 \
    comment="DSTNAT Hairpin-B NVR-2 (LAN → public IP → NVR, ENABLED)"

# ============================================================
# STEP 15: NAT – SRC-NAT (Masquerade)
# ============================================================

add chain=srcnat action=masquerade \
    out-interface-list=WAN \
    comment="SRCNAT Masquerade to WAN"

# Hairpin Option B SRC-NAT – masquerade để NVR reply về router (ENABLED)
# Sau DSTNAT, NVR nhận gói src=192.168.0.x → reply về 192.168.0.x qua GW.
# Masquerade đổi src→192.168.5.1 (router VLAN70 IP) đảm bảo NVR luôn
# reply về router → router conntrack restore lại địa chỉ gốc cho client.
add chain=srcnat action=masquerade \
    src-address-list=LOCAL_NETS dst-address=192.168.5.254 \
    comment="SRCNAT Hairpin-B NVR-1 (ENABLED)"

add chain=srcnat action=masquerade \
    src-address-list=LOCAL_NETS dst-address=192.168.5.253 \
    comment="SRCNAT Hairpin-B NVR-2 (ENABLED)"

# ============================================================
# STEP 16: QoS – MANGLE
# ============================================================
/ip firewall mangle

add chain=prerouting action=mark-packet new-packet-mark=voip passthrough=yes \
    src-address=172.16.50.0/24 comment="QoS mark VoIP"
add chain=prerouting action=mark-packet new-packet-mark=iptv passthrough=yes \
    src-address=172.16.40.0/24 comment="QoS mark IPTV"
add chain=prerouting action=mark-packet new-packet-mark=office passthrough=yes \
    src-address=192.168.0.0/24 comment="QoS mark Office+WiFi"
add chain=prerouting action=mark-packet new-packet-mark=cctv passthrough=yes \
    src-address=192.168.5.0/24 comment="QoS mark CCTV"
add chain=prerouting action=mark-packet new-packet-mark=guest passthrough=yes \
    src-address=172.16.20.0/22 comment="QoS mark Guest"

# ============================================================
# STEP 17: QoS – QUEUE TREE
# +-------------+----------+----------+-----------+
# | Queue       | Priority | limit-at | max-limit |
# +-------------+----------+----------+-----------+
# | voip        |    1     |   2M     |  1000M    |
# | iptv        |    2     |  50M     |  1000M    |
# | office      |    4     | 100M     |  1000M    |
# | cctv        |    5     |  20M     |   100M    |
# | guest       |    8     |   5M     |    50M    |
# +-------------+----------+----------+-----------+
# ============================================================
/queue tree

# PRIMARY WAN queues
add name=wan-upload parent=pppoe-wan max-limit=1000M \
    comment="WAN PRIMARY upload parent – 1Gbps"
add name=q-voip   parent=wan-upload packet-mark=voip   priority=1 limit-at=2M   max-limit=1000M comment="QoS VoIP"
add name=q-iptv   parent=wan-upload packet-mark=iptv   priority=2 limit-at=50M  max-limit=1000M comment="QoS IPTV"
add name=q-office parent=wan-upload packet-mark=office priority=4 limit-at=100M max-limit=1000M comment="QoS Office+WiFi"
add name=q-cctv   parent=wan-upload packet-mark=cctv   priority=5 limit-at=20M  max-limit=100M  comment="QoS CCTV"
add name=q-guest  parent=wan-upload packet-mark=guest  priority=8 limit-at=5M   max-limit=50M   comment="QoS Guest"

# BACKUP WAN queues (cùng cấu hình – áp dụng khi failover)
add name=wan-upload-bk parent=pppoe-backup max-limit=1000M \
    comment="WAN BACKUP upload parent – 1Gbps"
add name=q-voip-bk   parent=wan-upload-bk packet-mark=voip   priority=1 limit-at=2M   max-limit=1000M comment="QoS VoIP backup"
add name=q-iptv-bk   parent=wan-upload-bk packet-mark=iptv   priority=2 limit-at=50M  max-limit=1000M comment="QoS IPTV backup"
add name=q-office-bk parent=wan-upload-bk packet-mark=office priority=4 limit-at=100M max-limit=1000M comment="QoS Office+WiFi backup"
add name=q-cctv-bk   parent=wan-upload-bk packet-mark=cctv   priority=5 limit-at=20M  max-limit=100M  comment="QoS CCTV backup"
add name=q-guest-bk  parent=wan-upload-bk packet-mark=guest  priority=8 limit-at=5M   max-limit=50M   comment="QoS Guest backup"

/queue simple
add name=guest-limit target=172.16.20.0/22 \
    max-limit=50M/50M priority=8/8 \
    comment="Guest 50Mbps up+down cap"

# ============================================================
# STEP 18: SERVICES HARDENING
# ============================================================
/ip service
set telnet   disabled=yes
set ftp      disabled=yes
set www      disabled=yes
set www-ssl  disabled=yes
set api      disabled=yes
set api-ssl  disabled=yes
set ssh      port=22   address=192.168.10.0/24,192.168.0.0/24,10.10.10.0/24
set winbox   port=8291 address=192.168.10.0/24,192.168.0.0/24,10.10.10.0/24

# ============================================================
# STEP 19: SYSTEM HARDENING
# ============================================================
/system identity
set name=CCR2004-Router

/tool bandwidth-server
set enabled=no

/tool mac-server
set allowed-interface-list=MGMT

/tool mac-server mac-winbox
set allowed-interface-list=MGMT

/ip neighbor discovery-settings
set discover-interface-list=LAN

# ============================================================
# STEP 20: SCHEDULED BACKUP
# ============================================================
/system scheduler
add name=weekly-backup interval=7d start-time=02:00:00 \
    on-event="/export compact file=router-weekly-backup" \
    comment="Weekly config backup to router flash"

# ============================================================
# STEP 21: WAN FAILOVER – AUTO-MONITORING VIETTEL → VNPT
#
# Cơ chế hoạt động:
#   1. Tạo routing table riêng "wan-check-viettel" + route 8.8.8.8 qua pppoe-wan
#      → netwatch ping 8.8.8.8 riêng qua đường Viettel, không bị ảnh hưởng bởi backup
#   2. Viettel DOWN (PPPoE rớt hoặc mất internet):
#        → down-script: disable pppoe-wan
#        → RouterOS tự dùng route distance=2 (pppoe-backup VNPT) ngay lập tức
#   3. Recovery: scheduler chạy mỗi 5 phút, thử re-enable pppoe-wan
#        → Nếu reconnect OK → netwatch up-script → Viettel primary (distance=1) active lại
#   4. Thời gian phát hiện sự cố: ≤30 giây (interval netwatch)
#
# LƯU Ý: Sau khi import, nhập scripts thủ công qua Winbox Terminal
#          hoặc SSH nếu source= multiline không import được tự động.
# ============================================================

# Routing table riêng để kiểm tra internet qua Viettel độc lập
/routing table
add name=wan-check-viettel fib \
    comment="Routing table Viettel health check – dùng bởi netwatch"

# Route 8.8.8.8 chỉ đi qua pppoe-wan (Viettel)
# Route này tự động mất khi pppoe-wan down → netwatch phát hiện ngay
/ip route
add dst-address=8.8.8.8/32 gateway=pppoe-wan \
    routing-table=wan-check-viettel scope=10 \
    comment="Viettel health check route – active khi pppoe-wan UP"

# ---- SCRIPTS ----
# Script 1: Kích hoạt khi Viettel DOWN (netwatch down-script)
/system script
add name=wan-viettel-down \
    policy=read,write,policy,test \
    comment="WAN failover: disable Viettel khi mất internet, VNPT backup active" \
    source=":log warning \"WAN-FAILOVER: Viettel DOWN - disabling pppoe-wan, switching to VNPT backup\"\n/interface pppoe-client disable [find name=pppoe-wan]"

# Script 2: Kích hoạt khi Viettel UP trở lại (netwatch up-script)
add name=wan-viettel-up \
    policy=read,write,policy,test \
    comment="WAN restore: enable Viettel khi phục hồi, Viettel primary active lại" \
    source=":log warning \"WAN-FAILOVER: Viettel UP - enabling pppoe-wan, reverting to Viettel as primary\"\n/interface pppoe-client enable [find name=pppoe-wan]"

# Script 3: Thử phục hồi Viettel định kỳ (dùng bởi scheduler bên dưới)
# Logic: nếu pppoe-wan đang disabled → enable → chờ 20s → kiểm tra running
#        Nếu vẫn không connect → disable lại → thử lại sau 5 phút
add name=wan-viettel-recovery \
    policy=read,write,policy,test \
    comment="Thử re-enable pppoe-wan mỗi 5 phút khi đang failover sang VNPT" \
    source={
:local disabled [/interface pppoe-client get [find name=pppoe-wan] disabled]
:if ($disabled = true) do={
    :log info "WAN-RECOVERY: pppoe-wan disabled, testing Viettel reconnect..."
    /interface pppoe-client enable [find name=pppoe-wan]
    :delay 20s
    :local running [/interface pppoe-client get [find name=pppoe-wan] running]
    :if ($running = false) do={
        :log info "WAN-RECOVERY: Viettel still unreachable, disabling pppoe-wan again"
        /interface pppoe-client disable [find name=pppoe-wan]
    } else={
        :log warning "WAN-RECOVERY: Viettel reconnected OK, netwatch will confirm and activate primary"
    }
}
}

# ---- NETWATCH ----
# Ping 8.8.8.8 qua wan-check-viettel mỗi 30s, timeout 5s
# → down-script khi fail, up-script khi recover
/tool netwatch
add host=8.8.8.8 interval=30s timeout=5s \
    routing-table=wan-check-viettel \
    up-script="/system script run wan-viettel-up" \
    down-script="/system script run wan-viettel-down" \
    comment="Monitor Viettel – ping 8.8.8.8 via wan-check-viettel routing table"

# ---- SCHEDULER ----
# Scheduler thử phục hồi Viettel mỗi 5 phút
# (Xử lý trường hợp pppoe-wan đang disabled → netwatch không thể tự detect recovery)
/system scheduler
add name=viettel-recovery-check interval=5m start-time=startup \
    on-event="/system script run wan-viettel-recovery" \
    comment="Periodic Viettel recovery attempt while in VNPT failover mode"

# ============================================================
# STEP 22: USER ACCOUNT HARDENING
# !! Bắt buộc thực hiện THỦ CÔNG trước khi đưa vào production !!
# ============================================================
# /user add name=<TEN_ADMIN_MOI> password="<MAT_KHAU_MANH>" group=full
# /user remove admin
