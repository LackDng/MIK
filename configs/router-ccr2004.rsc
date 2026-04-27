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
# |   30 | Manage Wifi | 172.16.30.1/24     | 172.16.30.100-172.16.30.200  |  Yes |
# |   40 | IPTV Cloud  | 172.16.40.1/24     | 172.16.40.100-172.16.40.200  |  Yes |
# |   50 | IP Phone    | 172.16.50.1/24     | 172.16.50.100-172.16.50.200  |  Yes |
# |   60 | Office      | 192.168.0.1/24     | 192.168.0.100-192.168.0.200  |  Yes |
# |   70 | CCTV        | 192.168.5.1/24     | (static only)                |  No  |
# +------+-------------+--------------------+------------------------------+------+
#
# PORT MAPPING TABLE:
# +----------------+-----------------------------------------------+
# | Interface      | Role                                          |
# +----------------+-----------------------------------------------+
# | ether1         | WAN – PPPoE to ISP modem (copper)             |
# | sfp-sfpplus1   | Trunk to Core CRS326 (S+31DLC10D 10G SMF)    |
# | sfp-sfpplus2   | Reserved (not used)                           |
# | ether2-ether10 | Reserved (not used)                           |
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
# Chạy lệnh sau trong terminal (Winbox hoặc SSH), đợi router reboot:
#   /system reset-configuration no-defaults=yes skip-backup=yes
#
# Sau khi router reboot xong → kết nối lại → chạy:
#   /import file-name=router-ccr2004.rsc
#
# KHÔNG chạy lệnh reset trong file này vì router sẽ reboot giữa chừng
# và các lệnh phía sau sẽ bị lỗi "interface not found" do default bridge.
# ============================================================

# ============================================================
# STEP 2: BRIDGE + VLAN FILTERING
# ============================================================
/interface bridge
add name=bridge-lan vlan-filtering=yes comment="Main LAN bridge"

# Add ports to bridge
/interface bridge port
add bridge=bridge-lan interface=sfp-sfpplus1 \
    frame-types=admit-only-vlan-tagged \
    comment="Trunk uplink to Core CRS326"
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
    tagged=bridge-lan,sfp-sfpplus1
add bridge=bridge-lan vlan-ids=20 \
    tagged=bridge-lan,sfp-sfpplus1
add bridge=bridge-lan vlan-ids=30 \
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
add interface=bridge-lan vlan-id=30 name=bridge-lan.30 comment="VLAN30 Manage Wifi"
add interface=bridge-lan vlan-id=40 name=bridge-lan.40 comment="VLAN40 IPTV Cloud"
add interface=bridge-lan vlan-id=50 name=bridge-lan.50 comment="VLAN50 IP Phone"
add interface=bridge-lan vlan-id=60 name=bridge-lan.60 comment="VLAN60 Office"
add interface=bridge-lan vlan-id=70 name=bridge-lan.70 comment="VLAN70 CCTV"

/ip address
add address=192.168.10.1/24 interface=bridge-lan.10 comment="VLAN10 Management GW"
add address=172.16.20.1/22  interface=bridge-lan.20 comment="VLAN20 Wifi Guest GW"
add address=172.16.30.1/24  interface=bridge-lan.30 comment="VLAN30 Manage Wifi GW"
add address=172.16.40.1/24  interface=bridge-lan.40 comment="VLAN40 IPTV GW"
add address=172.16.50.1/24  interface=bridge-lan.50 comment="VLAN50 IP Phone GW"
add address=192.168.0.1/24  interface=bridge-lan.60 comment="VLAN60 Office GW"
add address=192.168.5.1/24  interface=bridge-lan.70 comment="VLAN70 CCTV GW"

# ============================================================
# STEP 5: PPPOE WAN
# ============================================================
/interface pppoe-client
add interface=ether1 name=pppoe-wan \
    user=abcd password="abcd88qưe" \
    add-default-route=yes use-peer-dns=no \
    disabled=no comment="WAN PPPoE to ISP – 1Gbps"

# ============================================================
# STEP 6: DNS
# ============================================================
/ip dns
set servers=8.8.8.8,1.1.1.1 allow-remote-requests=yes

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

# --- VLAN 30: Manage Wifi ---
/ip pool
add name=pool-vlan30 ranges=172.16.30.100-172.16.30.200
/ip dhcp-server
add name=dhcp-vlan30 interface=bridge-lan.30 address-pool=pool-vlan30 \
    lease-time=1d disabled=no
/ip dhcp-server network
add address=172.16.30.0/24 gateway=172.16.30.1 \
    dns-server=8.8.8.8,1.1.1.1 comment="VLAN30 Manage Wifi"

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

# --- VLAN 60: Office ---
/ip pool
add name=pool-vlan60 ranges=192.168.0.100-192.168.0.200
/ip dhcp-server
add name=dhcp-vlan60 interface=bridge-lan.60 address-pool=pool-vlan60 \
    lease-time=1d disabled=no
/ip dhcp-server network
add address=192.168.0.0/24 gateway=192.168.0.1 \
    dns-server=8.8.8.8,1.1.1.1 comment="VLAN60 Office"

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
# Bước 1 – Lấy server public key (gửi cho vanhau):
#   /interface wireguard print
#   → copy giá trị "public-key"
#
# Bước 2 – Vanhau tạo keypair trên client (WireGuard app hoặc CLI):
#   wg genkey | tee privatekey | wg pubkey > publickey
#   → gửi nội dung file "publickey" cho admin
#
# Bước 3 – Admin chạy lệnh sau trên router (thay KEY bằng key thật):
#   /interface wireguard peers
#   add interface=wg-vpn name=vanhau \
#       public-key="<DAN_PUBLIC_KEY_CUA_VANHAU_VAO_DAY>" \
#       allowed-address=10.10.10.2/32 \
#       persistent-keepalive=25

/ip address
add address=10.10.10.1/24 interface=wg-vpn comment="WireGuard VPN server IP"

# ---- CLIENT CONFIG TEMPLATE FOR VANHAU ----
# Generate keypair on client: wg genkey | tee privatekey | wg pubkey > publickey
# Send publickey content to admin to fill in above public-key field
# Save file below as wg-vanhau.conf on client device
#
# [Interface]
# PrivateKey = <VANHAU_PRIVATE_KEY>
# Address    = 10.10.10.2/24
# DNS        = 8.8.8.8
#
# [Peer]
# PublicKey           = <SERVER_PUBLIC_KEY>   # from /interface wireguard print
# Endpoint            = <WAN_IP>:13231         # from /ip address print (pppoe-wan)
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
add name=WAN  comment="WAN interfaces"
add name=LAN  comment="LAN VLAN interfaces"
add name=MGMT comment="Management only – VLAN10"
/interface list member
add interface=pppoe-wan     list=WAN
add interface=bridge-lan.10 list=LAN
add interface=bridge-lan.20 list=LAN
add interface=bridge-lan.30 list=LAN
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
add list=LOCAL_NETS address=172.16.30.0/24  comment="VLAN30 Manage Wifi"
add list=LOCAL_NETS address=172.16.40.0/24  comment="VLAN40 IPTV Cloud"
add list=LOCAL_NETS address=172.16.50.0/24  comment="VLAN50 IP Phone"
add list=LOCAL_NETS address=192.168.0.0/24  comment="VLAN60 Office"
add list=LOCAL_NETS address=192.168.10.0/24 comment="VLAN10 Management"
add list=LOCAL_NETS address=10.10.10.0/24   comment="VPN pool"

# ============================================================
# STEP 12: FIREWALL – CHAIN INPUT
# ============================================================
/ip firewall filter

# R1: Accept established/related (stateful baseline)
add chain=input action=accept \
    connection-state=established,related \
    comment="R1 Accept established/related"

# R2: Drop invalid
add chain=input action=drop \
    connection-state=invalid \
    comment="R2 Drop invalid"

# R3: Accept ICMP from LAN
add chain=input action=accept \
    protocol=icmp in-interface-list=LAN \
    comment="R3 ICMP from LAN"

# R4: Accept DNS from LAN (clients use router as resolver)
add chain=input action=accept \
    protocol=udp dst-port=53 in-interface-list=LAN \
    comment="R4 DNS UDP from LAN"
add chain=input action=accept \
    protocol=tcp dst-port=53 in-interface-list=LAN \
    comment="R4 DNS TCP from LAN"

# R5: Winbox from Management VLAN
add chain=input action=accept \
    protocol=tcp dst-port=8291 src-address=192.168.10.0/24 \
    comment="R5 Winbox from VLAN10"

# R6: SSH from Management VLAN
add chain=input action=accept \
    protocol=tcp dst-port=22 src-address=192.168.10.0/24 \
    comment="R6 SSH from VLAN10"

# R7: Winbox from VPN
add chain=input action=accept \
    protocol=tcp dst-port=8291 src-address=10.10.10.0/24 \
    comment="R7 Winbox from VPN"

# R8: SSH from VPN
add chain=input action=accept \
    protocol=tcp dst-port=22 src-address=10.10.10.0/24 \
    comment="R8 SSH from VPN"

# R9: WireGuard handshake from WAN
add chain=input action=accept \
    protocol=udp dst-port=13231 in-interface=pppoe-wan \
    comment="R9 WireGuard UDP 13231 from WAN"

# R10: Drop all from WAN
add chain=input action=drop \
    in-interface=pppoe-wan \
    comment="R10 Drop all from WAN"

# R11: Default drop INPUT
add chain=input action=drop \
    comment="R11 Default drop INPUT"

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

# R3: VLAN10 admin – full forward access
add chain=forward action=accept \
    src-address=192.168.10.0/24 \
    comment="R3 VLAN10 admin full access"

# R4: VLAN60 Office → VLAN10 Management
add chain=forward action=accept \
    src-address=192.168.0.0/24 dst-address=192.168.10.0/24 \
    comment="R4 VLAN60 can reach VLAN10"

# R5: VPN → VLAN10 Management
add chain=forward action=accept \
    src-address=10.10.10.0/24 dst-address=192.168.10.0/24 \
    comment="R5 VPN access VLAN10"

# R6: VPN → VLAN60 Office
add chain=forward action=accept \
    src-address=10.10.10.0/24 dst-address=192.168.0.0/24 \
    comment="R6 VPN access VLAN60"

# R7: VPN → NVR-1 port 8054
add chain=forward action=accept protocol=tcp \
    src-address=10.10.10.0/24 dst-address=192.168.5.254 dst-port=8054 \
    comment="R7 VPN access NVR-1:8054"

# R8: VPN → NVR-2 port 8053
add chain=forward action=accept protocol=tcp \
    src-address=10.10.10.0/24 dst-address=192.168.5.253 dst-port=8053 \
    comment="R8 VPN access NVR-2:8053"

# R9: Drop remaining VPN traffic
add chain=forward action=drop \
    src-address=10.10.10.0/24 \
    comment="R9 Drop VPN traffic not matched above"

# R10: VLAN20 Guest → internet
add chain=forward action=accept \
    src-address=172.16.20.0/22 out-interface=pppoe-wan \
    comment="R10 VLAN20 Guest internet"

# R11: VLAN40 IPTV → internet
add chain=forward action=accept \
    src-address=172.16.40.0/24 out-interface=pppoe-wan \
    comment="R11 VLAN40 IPTV internet"

# R12: VLAN30 Manage Wifi → internet
add chain=forward action=accept \
    src-address=172.16.30.0/24 out-interface=pppoe-wan \
    comment="R12 VLAN30 Manage Wifi internet"

# R13: VLAN60 Office → internet
add chain=forward action=accept \
    src-address=192.168.0.0/24 out-interface=pppoe-wan \
    comment="R13 VLAN60 Office internet"

# R14: VLAN50 SIP internal (TCP+UDP 5060 → SIP server)
add chain=forward action=accept protocol=tcp \
    src-address=172.16.50.0/24 dst-address=172.16.50.10 dst-port=5060 \
    comment="R14 VoIP SIP TCP internal"
add chain=forward action=accept protocol=udp \
    src-address=172.16.50.0/24 dst-address=172.16.50.10 dst-port=5060 \
    comment="R14 VoIP SIP UDP internal"

# R15: VLAN50 RTP internal
add chain=forward action=accept protocol=udp \
    src-address=172.16.50.0/24 dst-address=172.16.50.10 dst-port=10000-20000 \
    comment="R15 VoIP RTP internal"

# R16: VLAN50 SIP → WAN
add chain=forward action=accept protocol=tcp \
    src-address=172.16.50.0/24 out-interface=pppoe-wan dst-port=5060 \
    comment="R16 VoIP SIP TCP to WAN"
add chain=forward action=accept protocol=udp \
    src-address=172.16.50.0/24 out-interface=pppoe-wan dst-port=5060 \
    comment="R16 VoIP SIP UDP to WAN"

# R17: VLAN50 RTP → WAN
add chain=forward action=accept protocol=udp \
    src-address=172.16.50.0/24 out-interface=pppoe-wan dst-port=10000-20000 \
    comment="R17 VoIP RTP to WAN"

# R18: NVR-1 → internet (cloud CCTV / port forwarding)
add chain=forward action=accept \
    src-address=192.168.5.254 out-interface=pppoe-wan \
    comment="R18 NVR-1 internet access"

# R19: NVR-2 → internet
add chain=forward action=accept \
    src-address=192.168.5.253 out-interface=pppoe-wan \
    comment="R19 NVR-2 internet access"

# R20: Block cameras (192.168.5.1-100) from internet
# NVR (.253/.254) already accepted above – this drops remaining VLAN70
add chain=forward action=drop \
    src-address=192.168.5.0/24 out-interface=pppoe-wan \
    comment="R20 Drop CCTV cameras to internet"

# R21: VLAN10 admin full access to VLAN70 CCTV
add chain=forward action=accept \
    src-address=192.168.10.0/24 dst-address=192.168.5.0/24 \
    comment="R21 VLAN10 admin full access to CCTV"

# R22: LOCAL_NETS → NVR-1:8054 (Hairpin Option A – direct IP, ENABLED)
add chain=forward action=accept protocol=tcp \
    src-address-list=LOCAL_NETS dst-address=192.168.5.254 dst-port=8054 \
    comment="R22 LOCAL_NETS NVR-1:8054 [Hairpin A – ENABLED]"

# R23: LOCAL_NETS → NVR-2:8053 (Hairpin Option A – ENABLED)
add chain=forward action=accept protocol=tcp \
    src-address-list=LOCAL_NETS dst-address=192.168.5.253 dst-port=8053 \
    comment="R23 LOCAL_NETS NVR-2:8053 [Hairpin A – ENABLED]"

# R24: Default deny all forward
add chain=forward action=drop \
    comment="R24 Default deny FORWARD"

# ============================================================
# STEP 14: NAT – DST-NAT (Port Forwarding)
# ============================================================
/ip firewall nat

# WAN:8054 → NVR-1
add chain=dstnat action=dst-nat \
    in-interface=pppoe-wan protocol=tcp dst-port=8054 \
    to-addresses=192.168.5.254 to-ports=8054 \
    comment="DSTNAT WAN:8054 to NVR-1"

# WAN:8053 → NVR-2
add chain=dstnat action=dst-nat \
    in-interface=pppoe-wan protocol=tcp dst-port=8053 \
    to-addresses=192.168.5.253 to-ports=8053 \
    comment="DSTNAT WAN:8053 to NVR-2"

# ---- Hairpin Option B DST-NAT (DISABLED) ----
# Enable these + corresponding SRCNAT rules below to allow accessing
# NVR via WAN IP from internal network (not needed if using direct IP)
#
# add chain=dstnat action=dst-nat disabled=yes \
#     src-address-list=LOCAL_NETS protocol=tcp dst-port=8054 \
#     to-addresses=192.168.5.254 to-ports=8054 \
#     comment="DSTNAT Hairpin-B NVR-1 [DISABLED]"
#
# add chain=dstnat action=dst-nat disabled=yes \
#     src-address-list=LOCAL_NETS protocol=tcp dst-port=8053 \
#     to-addresses=192.168.5.253 to-ports=8053 \
#     comment="DSTNAT Hairpin-B NVR-2 [DISABLED]"

# ============================================================
# STEP 15: NAT – SRC-NAT (Masquerade)
# ============================================================

# Masquerade all outbound WAN traffic
add chain=srcnat action=masquerade \
    out-interface=pppoe-wan \
    comment="SRCNAT Masquerade to WAN"

# ---- Hairpin Option B SRC-NAT (DISABLED) ----
# add chain=srcnat action=masquerade disabled=yes \
#     src-address-list=LOCAL_NETS dst-address=192.168.5.254 \
#     comment="SRCNAT Hairpin-B NVR-1 [DISABLED]"
#
# add chain=srcnat action=masquerade disabled=yes \
#     src-address-list=LOCAL_NETS dst-address=192.168.5.253 \
#     comment="SRCNAT Hairpin-B NVR-2 [DISABLED]"

# ============================================================
# STEP 16: QoS – MANGLE (mark packets in prerouting)
# ============================================================
/ip firewall mangle

add chain=prerouting action=mark-packet new-packet-mark=voip passthrough=yes \
    src-address=172.16.50.0/24 comment="QoS mark VoIP"
add chain=prerouting action=mark-packet new-packet-mark=iptv passthrough=yes \
    src-address=172.16.40.0/24 comment="QoS mark IPTV"
add chain=prerouting action=mark-packet new-packet-mark=wifi-mgmt passthrough=yes \
    src-address=172.16.30.0/24 comment="QoS mark Manage Wifi"
add chain=prerouting action=mark-packet new-packet-mark=office passthrough=yes \
    src-address=192.168.0.0/24 comment="QoS mark Office"
add chain=prerouting action=mark-packet new-packet-mark=cctv passthrough=yes \
    src-address=192.168.5.0/24 comment="QoS mark CCTV"
add chain=prerouting action=mark-packet new-packet-mark=guest passthrough=yes \
    src-address=172.16.20.0/22 comment="QoS mark Guest"

# ============================================================
# STEP 17: QoS – QUEUE TREE (upload on pppoe-wan)
# +-------------+----------+----------+-----------+
# | Queue       | Priority | limit-at | max-limit |
# +-------------+----------+----------+-----------+
# | voip        |    1     |   2M     |  1000M    |
# | iptv        |    2     |  50M     |  1000M    |
# | wifi-mgmt   |    3     |  10M     |   200M    |
# | office      |    4     | 100M     |  1000M    |
# | cctv        |    5     |  20M     |   100M    |
# | guest       |    8     |   5M     |    50M    |
# +-------------+----------+----------+-----------+
# ============================================================
/queue tree
add name=wan-upload parent=pppoe-wan max-limit=1000M \
    comment="WAN upload parent – 1Gbps"

add name=q-voip      parent=wan-upload packet-mark=voip \
    priority=1 limit-at=2M   max-limit=1000M \
    comment="QoS VoIP"
add name=q-iptv      parent=wan-upload packet-mark=iptv \
    priority=2 limit-at=50M  max-limit=1000M \
    comment="QoS IPTV"
add name=q-wifi-mgmt parent=wan-upload packet-mark=wifi-mgmt \
    priority=3 limit-at=10M  max-limit=200M \
    comment="QoS Manage Wifi"
add name=q-office    parent=wan-upload packet-mark=office \
    priority=4 limit-at=100M max-limit=1000M \
    comment="QoS Office"
add name=q-cctv      parent=wan-upload packet-mark=cctv \
    priority=5 limit-at=20M  max-limit=100M \
    comment="QoS CCTV"
add name=q-guest     parent=wan-upload packet-mark=guest \
    priority=8 limit-at=5M   max-limit=50M \
    comment="QoS Guest"

# Simple Queue – Guest total bandwidth cap (upload + download)
/queue simple
add name=guest-limit target=172.16.20.0/22 \
    max-limit=50M/50M priority=8/8 \
    comment="Guest 50Mbps up+down cap"

# ============================================================
# STEP 18: SERVICES HARDENING (/ip service)
# Lớp bảo vệ thứ 1 – cấp dịch vụ, độc lập với firewall
# ============================================================
/ip service
set telnet   disabled=yes
set ftp      disabled=yes
set www      disabled=yes
set www-ssl  disabled=yes
set api      disabled=yes
set api-ssl  disabled=yes
set ssh      port=22   allowed-from=192.168.10.0/24,10.10.10.0/24
set winbox   port=8291 allowed-from=192.168.10.0/24,10.10.10.0/24

# ============================================================
# STEP 19: SYSTEM HARDENING
# ============================================================
/system identity
set name=CCR2004-Router

# Tắt bandwidth test server (không dùng, tránh bị lợi dụng)
/tool bandwidth-server
set enabled=no

# MAC server chỉ trên VLAN10 – tránh Winbox MAC login từ VLAN khác
/tool mac-server
set allowed-interface-list=MGMT

/tool mac-server mac-winbox
set allowed-interface-list=MGMT

# Neighbor discovery chỉ nội bộ LAN (không quảng bá ra WAN)
/ip neighbor discovery-settings
set discover-interface-list=LAN
