# ============================================================
# BLOCK 2: CORE SWITCH – MikroTik CRS326-24S+2Q+RM
# RouterOS v7
# ============================================================
#
# VLAN MAPPING TABLE:
# +------+-------------+--------------------+
# | VLAN | Name        | Notes              |
# +------+-------------+--------------------+
# |   10 | Management  | Tagged all ports   |
# |   20 | Wifi Guest  | Tagged all ports   |
# |   40 | IPTV Cloud  | Tagged all ports   |
# |   50 | IP Phone    | Tagged all ports   |
# |   60 | Office+WiFi | Tagged all ports   |
# |   70 | CCTV        | Tagged all ports   |
# +------+-------------+--------------------+
#
# PORT MAPPING TABLE:
# +----------------+-----------------------------------------------+
# | Interface      | Role                                          |
# +----------------+-----------------------------------------------+
# | sfp-sfpplus1   | Uplink → Router CCR2004 (S+31DLC10D 10G SMF) |
# | sfp1           | Downlink → CSS610 (S-31DLC20D 1G SMF)        |
# | sfp2           | Downlink → CRS328 (S-31DLC20D 1G SMF)        |
# | sfp3-sfp12     | Reserved – trunk all VLAN (spare)             |
# | sfp-sfpplus2   | Reserved – trunk all VLAN (spare)             |
# +----------------+-----------------------------------------------+
#
# MANAGEMENT IP: 192.168.10.2/24 (VLAN10), GW: 192.168.10.1
# ============================================================

# ============================================================
# STEP 1: RESET (chạy TAY trước khi import file này)
# ============================================================
# /system reset-configuration no-defaults=yes skip-backup=yes
# Sau reboot → /import file-name=switch-core-crs326.rsc

# ============================================================
# STEP 2: BRIDGE + VLAN FILTERING
# ============================================================
/interface bridge
add name=bridge-core vlan-filtering=yes comment="Core switch bridge"

/interface bridge port
add bridge=bridge-core interface=sfp-sfpplus1 \
    frame-types=admit-only-vlan-tagged \
    comment="Uplink to Router CCR2004"
add bridge=bridge-core interface=sfp1 \
    frame-types=admit-only-vlan-tagged \
    comment="Downlink to CSS610"
add bridge=bridge-core interface=sfp2 \
    frame-types=admit-only-vlan-tagged \
    comment="Downlink to CRS328"
add bridge=bridge-core interface=sfp3 \
    frame-types=admit-only-vlan-tagged \
    comment="Reserved spare trunk"
add bridge=bridge-core interface=sfp4 \
    frame-types=admit-only-vlan-tagged \
    comment="Reserved spare trunk"
add bridge=bridge-core interface=sfp5 \
    frame-types=admit-only-vlan-tagged \
    comment="Reserved spare trunk"
add bridge=bridge-core interface=sfp6 \
    frame-types=admit-only-vlan-tagged \
    comment="Reserved spare trunk"
add bridge=bridge-core interface=sfp7 \
    frame-types=admit-only-vlan-tagged \
    comment="Reserved spare trunk"
add bridge=bridge-core interface=sfp8 \
    frame-types=admit-only-vlan-tagged \
    comment="Reserved spare trunk"
add bridge=bridge-core interface=sfp9 \
    frame-types=admit-only-vlan-tagged \
    comment="Reserved spare trunk"
add bridge=bridge-core interface=sfp10 \
    frame-types=admit-only-vlan-tagged \
    comment="Reserved spare trunk"
add bridge=bridge-core interface=sfp11 \
    frame-types=admit-only-vlan-tagged \
    comment="Reserved spare trunk"
add bridge=bridge-core interface=sfp12 \
    frame-types=admit-only-vlan-tagged \
    comment="Reserved spare trunk"
add bridge=bridge-core interface=sfp-sfpplus2 \
    frame-types=admit-only-vlan-tagged \
    comment="Reserved spare trunk"

# ============================================================
# STEP 3: BRIDGE VLAN TABLE
# All ports are trunk – tagged for all VLANs
# bridge-core = CPU port (tagged for management VLAN10)
# ============================================================
/interface bridge vlan
add bridge=bridge-core vlan-ids=10 \
    tagged=bridge-core,sfp-sfpplus1,sfp1,sfp2,sfp3,sfp4,sfp5,sfp6,sfp7,sfp8,sfp9,sfp10,sfp11,sfp12,sfp-sfpplus2
add bridge=bridge-core vlan-ids=20 \
    tagged=sfp-sfpplus1,sfp1,sfp2,sfp3,sfp4,sfp5,sfp6,sfp7,sfp8,sfp9,sfp10,sfp11,sfp12,sfp-sfpplus2
add bridge=bridge-core vlan-ids=40 \
    tagged=sfp-sfpplus1,sfp1,sfp2,sfp3,sfp4,sfp5,sfp6,sfp7,sfp8,sfp9,sfp10,sfp11,sfp12,sfp-sfpplus2
add bridge=bridge-core vlan-ids=50 \
    tagged=sfp-sfpplus1,sfp1,sfp2,sfp3,sfp4,sfp5,sfp6,sfp7,sfp8,sfp9,sfp10,sfp11,sfp12,sfp-sfpplus2
add bridge=bridge-core vlan-ids=60 \
    tagged=sfp-sfpplus1,sfp1,sfp2,sfp3,sfp4,sfp5,sfp6,sfp7,sfp8,sfp9,sfp10,sfp11,sfp12,sfp-sfpplus2
add bridge=bridge-core vlan-ids=70 \
    tagged=sfp-sfpplus1,sfp1,sfp2,sfp3,sfp4,sfp5,sfp6,sfp7,sfp8,sfp9,sfp10,sfp11,sfp12,sfp-sfpplus2

# ============================================================
# STEP 4: MANAGEMENT IP (VLAN10)
# ============================================================
/interface vlan
add interface=bridge-core vlan-id=10 name=bridge-core.10 comment="VLAN10 Management"

/ip address
add address=192.168.10.2/24 interface=bridge-core.10 comment="VLAN10 Management IP"

/ip route
add dst-address=0.0.0.0/0 gateway=192.168.10.1 comment="Default GW via Router"

# ============================================================
# STEP 5: DNS
# ============================================================
/ip dns
set servers=8.8.8.8,1.1.1.1

# ============================================================
# STEP 6: NTP + TIMEZONE
# ============================================================
/system ntp client
set enabled=yes
/system ntp client servers
add address=time.google.com comment="Google NTP"
add address=time.cloudflare.com comment="Cloudflare NTP"
/system clock
set time-zone-name=Asia/Ho_Chi_Minh

# ============================================================
# STEP 7: INTERFACE LISTS
# ============================================================
/interface list
add name=MGMT comment="Management – VLAN10 only"
/interface list member
add interface=bridge-core.10 list=MGMT

# ============================================================
# STEP 8: FIREWALL – CHAIN INPUT
# Chỉ cho phép quản trị từ VLAN10 và VPN, block everything else
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

# Whitelist bypass brute-force check for trusted sources
add chain=input action=accept \
    src-address=192.168.10.0/24 \
    comment="Whitelist VLAN10 – bypass brute-force check"
add chain=input action=accept \
    src-address=10.10.10.0/24 \
    comment="Whitelist VPN – bypass brute-force check"
add chain=input action=accept \
    src-address=192.168.0.0/24 \
    comment="Whitelist VLAN60 Office – bypass brute-force check"

# R7: ICMP from MGMT
add chain=input action=accept \
    protocol=icmp in-interface-list=MGMT \
    comment="R7 ICMP from MGMT"

# R8: Winbox từ VLAN10
add chain=input action=accept \
    protocol=tcp dst-port=8291 src-address=192.168.10.0/24 \
    comment="R8 Winbox from VLAN10"

# R9: SSH từ VLAN10
add chain=input action=accept \
    protocol=tcp dst-port=22 src-address=192.168.10.0/24 \
    comment="R9 SSH from VLAN10"

# R10: Winbox từ VLAN60 Office
add chain=input action=accept \
    protocol=tcp dst-port=8291 src-address=192.168.0.0/24 \
    comment="R10 Winbox from VLAN60 Office"

# R11: SSH từ VLAN60 Office
add chain=input action=accept \
    protocol=tcp dst-port=22 src-address=192.168.0.0/24 \
    comment="R11 SSH from VLAN60 Office"

# R12: Winbox từ VPN
add chain=input action=accept \
    protocol=tcp dst-port=8291 src-address=10.10.10.0/24 \
    comment="R12 Winbox from VPN"

# R13: SSH từ VPN
add chain=input action=accept \
    protocol=tcp dst-port=22 src-address=10.10.10.0/24 \
    comment="R13 SSH from VPN"

# R14: Default drop INPUT
add chain=input action=drop \
    log=yes log-prefix="INPUT-DROP: " \
    comment="R14 Default drop INPUT"

# ============================================================
# STEP 9: SERVICES HARDENING
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
# STEP 10: SYSTEM HARDENING
# ============================================================
/system identity
set name=CRS326-Core

/tool bandwidth-server
set enabled=no

/tool mac-server
set allowed-interface-list=MGMT

/tool mac-server mac-winbox
set allowed-interface-list=MGMT

/ip neighbor discovery-settings
set discover-interface-list=MGMT

# ============================================================
# STEP 11: SCHEDULED BACKUP
# ============================================================
/system scheduler
add name=weekly-backup interval=7d start-time=02:00:00 \
    on-event="/export compact file=crs326-weekly-backup" \
    comment="Weekly config backup to switch flash"

# ============================================================
# STEP 12: USER ACCOUNT HARDENING
# !! Bắt buộc thực hiện THỦ CÔNG trước khi đưa vào production !!
# ============================================================
# /user add name=<TEN_ADMIN_MOI> password="<MAT_KHAU_MANH>" group=full
# /user remove admin
