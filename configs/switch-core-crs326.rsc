# ============================================================
# BLOCK 2: CORE SWITCH – MikroTik CRS326-24S+2Q+RM
# RouterOS v7 – Layer 2 only
# ============================================================
#
# PORT MAPPING TABLE:
# +------------------+-----------------------------------------------+
# | Interface        | Role                                          |
# +------------------+-----------------------------------------------+
# | sfp-sfpplus1     | Uplink → Router CCR2004 (S+31DLC10D 10G SMF) |
# | sfp-sfpplus2     | Downlink → CSS610 (S-31DLC20D 1G SMF)        |
# | sfp-sfpplus3     | Downlink → CRS328 (S-31DLC20D 1G SMF)        |
# | sfp-sfpplus4–13  | In use – trunk all VLAN                       |
# | sfp-sfpplus14–24 | Reserved (not configured)                     |
# +------------------+-----------------------------------------------+
#
# STP: CRS326 là Root Bridge (priority=4096)
#      CCR2004 là Secondary Root (priority=8192)
#      CSS610/CRS328/other switches dùng default (32768)
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
# priority=4096: ép CRS326 làm RSTP Root Bridge
# igmp-snooping=yes: giảm multicast flood (IPTV/camera)
# ============================================================
/interface bridge
add name=bridge-core vlan-filtering=yes priority=4096 \
    igmp-snooping=yes \
    comment="Core switch bridge – Root Bridge priority=4096"

/interface bridge port
add bridge=bridge-core interface=sfp-sfpplus1 \
    frame-types=admit-only-vlan-tagged \
    comment="Uplink to Router CCR2004"
add bridge=bridge-core interface=sfp-sfpplus2 \
    frame-types=admit-only-vlan-tagged \
    comment="Downlink to CSS610"
add bridge=bridge-core interface=sfp-sfpplus3 \
    frame-types=admit-only-vlan-tagged \
    comment="Downlink to CRS328"
add bridge=bridge-core interface=sfp-sfpplus4 \
    frame-types=admit-only-vlan-tagged \
    comment="Trunk port"
add bridge=bridge-core interface=sfp-sfpplus5 \
    frame-types=admit-only-vlan-tagged \
    comment="Trunk port"
add bridge=bridge-core interface=sfp-sfpplus6 \
    frame-types=admit-only-vlan-tagged \
    comment="Trunk port"
add bridge=bridge-core interface=sfp-sfpplus7 \
    frame-types=admit-only-vlan-tagged \
    comment="Trunk port"
add bridge=bridge-core interface=sfp-sfpplus8 \
    frame-types=admit-only-vlan-tagged \
    comment="Trunk port"
add bridge=bridge-core interface=sfp-sfpplus9 \
    frame-types=admit-only-vlan-tagged \
    comment="Trunk port"
add bridge=bridge-core interface=sfp-sfpplus10 \
    frame-types=admit-only-vlan-tagged \
    comment="Trunk port"
add bridge=bridge-core interface=sfp-sfpplus11 \
    frame-types=admit-only-vlan-tagged \
    comment="Trunk port"
add bridge=bridge-core interface=sfp-sfpplus12 \
    frame-types=admit-only-vlan-tagged \
    comment="Trunk port"
add bridge=bridge-core interface=sfp-sfpplus13 \
    frame-types=admit-only-vlan-tagged \
    comment="Trunk port"

# ============================================================
# STEP 3: BRIDGE VLAN TABLE
# CPU port (bridge-core) tagged VLAN10 only for management
# All active ports (sfp-sfpplus1–13) tagged all VLANs
# ============================================================
/interface bridge vlan
add bridge=bridge-core vlan-ids=10 \
    tagged=bridge-core,sfp-sfpplus1,sfp-sfpplus2,sfp-sfpplus3,sfp-sfpplus4,sfp-sfpplus5,sfp-sfpplus6,sfp-sfpplus7,sfp-sfpplus8,sfp-sfpplus9,sfp-sfpplus10,sfp-sfpplus11,sfp-sfpplus12,sfp-sfpplus13
add bridge=bridge-core vlan-ids=20 \
    tagged=sfp-sfpplus1,sfp-sfpplus2,sfp-sfpplus3,sfp-sfpplus4,sfp-sfpplus5,sfp-sfpplus6,sfp-sfpplus7,sfp-sfpplus8,sfp-sfpplus9,sfp-sfpplus10,sfp-sfpplus11,sfp-sfpplus12,sfp-sfpplus13
add bridge=bridge-core vlan-ids=40 \
    tagged=sfp-sfpplus1,sfp-sfpplus2,sfp-sfpplus3,sfp-sfpplus4,sfp-sfpplus5,sfp-sfpplus6,sfp-sfpplus7,sfp-sfpplus8,sfp-sfpplus9,sfp-sfpplus10,sfp-sfpplus11,sfp-sfpplus12,sfp-sfpplus13
add bridge=bridge-core vlan-ids=50 \
    tagged=sfp-sfpplus1,sfp-sfpplus2,sfp-sfpplus3,sfp-sfpplus4,sfp-sfpplus5,sfp-sfpplus6,sfp-sfpplus7,sfp-sfpplus8,sfp-sfpplus9,sfp-sfpplus10,sfp-sfpplus11,sfp-sfpplus12,sfp-sfpplus13
add bridge=bridge-core vlan-ids=60 \
    tagged=sfp-sfpplus1,sfp-sfpplus2,sfp-sfpplus3,sfp-sfpplus4,sfp-sfpplus5,sfp-sfpplus6,sfp-sfpplus7,sfp-sfpplus8,sfp-sfpplus9,sfp-sfpplus10,sfp-sfpplus11,sfp-sfpplus12,sfp-sfpplus13
add bridge=bridge-core vlan-ids=70 \
    tagged=sfp-sfpplus1,sfp-sfpplus2,sfp-sfpplus3,sfp-sfpplus4,sfp-sfpplus5,sfp-sfpplus6,sfp-sfpplus7,sfp-sfpplus8,sfp-sfpplus9,sfp-sfpplus10,sfp-sfpplus11,sfp-sfpplus12,sfp-sfpplus13

# ============================================================
# STEP 4: MANAGEMENT IP (VLAN10)
# ============================================================
/interface vlan
add interface=bridge-core vlan-id=10 name=bridge-core.10 comment="VLAN10 Management"

/ip address
add address=192.168.10.2/24 interface=bridge-core.10 comment="CRS326 management IP"

/ip route
add dst-address=0.0.0.0/0 gateway=192.168.10.1 comment="Default GW via Router"

/ip dns
set servers=8.8.8.8,1.1.1.1

# ============================================================
# STEP 5: NTP + TIMEZONE
# ============================================================
/system ntp client
set enabled=yes
/system ntp client servers
add address=time.google.com comment="Google NTP"
add address=time.cloudflare.com comment="Cloudflare NTP"
/system clock
set time-zone-name=Asia/Ho_Chi_Minh

# ============================================================
# STEP 6: INTERFACE LISTS
# ============================================================
/interface list
add name=MGMT comment="Management – VLAN10 only"
/interface list member
add interface=bridge-core.10 list=MGMT

# ============================================================
# STEP 7: FIREWALL – CHAIN INPUT
# ============================================================
/ip firewall filter

add chain=input action=accept \
    connection-state=established,related \
    comment="R1 Accept established/related"
add chain=input action=drop \
    connection-state=invalid \
    comment="R2 Drop invalid"
add chain=input action=drop \
    src-address-list=brute_force \
    log=yes log-prefix="BF-DROP: " \
    comment="R3 Drop brute-force blacklisted IPs"
add chain=input action=add-src-to-address-list \
    protocol=tcp dst-port=22,8291 connection-state=new \
    src-address-list=bf_stage2 \
    address-list=brute_force address-list-timeout=1h \
    comment="R4 Brute-force stage3 – blacklist 1h"
add chain=input action=add-src-to-address-list \
    protocol=tcp dst-port=22,8291 connection-state=new \
    src-address-list=bf_stage1 \
    address-list=bf_stage2 address-list-timeout=1m \
    comment="R5 Brute-force stage2"
add chain=input action=add-src-to-address-list \
    protocol=tcp dst-port=22,8291 connection-state=new \
    address-list=bf_stage1 address-list-timeout=1m \
    comment="R6 Brute-force stage1"
add chain=input action=accept \
    src-address=192.168.10.0/24 \
    comment="Whitelist VLAN10"
add chain=input action=accept \
    src-address=192.168.0.0/24 \
    comment="Whitelist VLAN60 Office"
add chain=input action=accept \
    src-address=10.10.10.0/24 \
    comment="Whitelist VPN"
add chain=input action=accept \
    protocol=icmp limit=10,5:packet \
    comment="ICMP rate-limited 10pps"
add chain=input action=drop \
    protocol=icmp \
    comment="Drop excess ICMP"
add chain=input action=accept \
    protocol=tcp dst-port=8291 src-address=192.168.10.0/24 \
    comment="Winbox from VLAN10"
add chain=input action=accept \
    protocol=tcp dst-port=22 src-address=192.168.10.0/24 \
    comment="SSH from VLAN10"
add chain=input action=accept \
    protocol=tcp dst-port=8291 src-address=192.168.0.0/24 \
    comment="Winbox from VLAN60"
add chain=input action=accept \
    protocol=tcp dst-port=22 src-address=192.168.0.0/24 \
    comment="SSH from VLAN60"
add chain=input action=accept \
    protocol=tcp dst-port=8291 src-address=10.10.10.0/24 \
    comment="Winbox from VPN"
add chain=input action=accept \
    protocol=tcp dst-port=22 src-address=10.10.10.0/24 \
    comment="SSH from VPN"
add chain=input action=drop \
    log=yes log-prefix="SW-DROP: " \
    comment="Default drop INPUT"

# ============================================================
# STEP 8: SERVICES HARDENING
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
# STEP 9: SYSTEM HARDENING
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
# STEP 10: SCHEDULED BACKUP
# ============================================================
/system scheduler
add name=weekly-backup interval=7d start-time=02:30:00 \
    on-event="/export compact file=crs326-weekly-backup" \
    comment="Weekly config backup"

# ============================================================
# STEP 11: USER ACCOUNT HARDENING
# !! Thực hiện THỦ CÔNG trước khi đưa vào production !!
# ============================================================
# /user add name=<TEN_ADMIN_MOI> password="<MAT_KHAU_MANH>" group=full
# /user remove admin
