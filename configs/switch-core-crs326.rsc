# ============================================================
# BLOCK 2: CORE SWITCH – MikroTik CRS326-24S+2Q+RM
# RouterOS v7 – Layer 2 only
# ============================================================
#
# CRS326-24S+2Q+RM: 24 cổng SFP/SFP+ đều tên sfp-sfpplus1–24
#                   2 cổng QSFP+ (qsfpplus1, qsfpplus2)
#                   KHÔNG có cổng tên "sfp1", "sfp2" v.v.
#
# PORT MAPPING TABLE:
# +------------------+---------------------------------------+------------+
# | Interface        | Connected to                          | Module     |
# +------------------+---------------------------------------+------------+
# | sfp-sfpplus1     | ← Router CCR2004 (uplink)             | S+31DLC10D |
# |                  |   10G Single-mode LC-LC OS2           |            |
# | sfp-sfpplus2     | → CSS610 (downlink)                   | S-31DLC20D |
# |                  |   1G Single-mode LC-LC OS2            |            |
# | sfp-sfpplus3     | → CRS328 (downlink)                   | S-31DLC20D |
# |                  |   1G Single-mode LC-LC OS2            |            |
# | sfp-sfpplus4–14  | Reserved (trunk all VLAN)             | —          |
# | sfp-sfpplus15–24 | Reserved (chưa thêm vào bridge)       | —          |
# +------------------+---------------------------------------+------------+
#
# ALL ACTIVE PORTS: trunk tagged VLAN 10,20,30,40,50,60,70
# Management: 192.168.10.2/24 via VLAN 10
# ============================================================

# ============================================================
# STEP 1: RESET (chạy TAY trước khi import file này)
# ============================================================
# Terminal: /system reset-configuration no-defaults=yes skip-backup=yes
# Đợi reboot → kết nối lại → /import file-name=switch-core-crs326.rsc

# ============================================================
# STEP 2: BRIDGE
# ============================================================
/interface bridge
add name=bridge-core vlan-filtering=yes comment="Core switch bridge – L2 only"

# Add trunk ports (sfp-sfpplus1–14; thêm sfp-sfpplus15–24 nếu cần)
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
    comment="Reserved trunk"
add bridge=bridge-core interface=sfp-sfpplus5 \
    frame-types=admit-only-vlan-tagged \
    comment="Reserved trunk"
add bridge=bridge-core interface=sfp-sfpplus6 \
    frame-types=admit-only-vlan-tagged \
    comment="Reserved trunk"
add bridge=bridge-core interface=sfp-sfpplus7 \
    frame-types=admit-only-vlan-tagged \
    comment="Reserved trunk"
add bridge=bridge-core interface=sfp-sfpplus8 \
    frame-types=admit-only-vlan-tagged \
    comment="Reserved trunk"
add bridge=bridge-core interface=sfp-sfpplus9 \
    frame-types=admit-only-vlan-tagged \
    comment="Reserved trunk"
add bridge=bridge-core interface=sfp-sfpplus10 \
    frame-types=admit-only-vlan-tagged \
    comment="Reserved trunk"
add bridge=bridge-core interface=sfp-sfpplus11 \
    frame-types=admit-only-vlan-tagged \
    comment="Reserved trunk"
add bridge=bridge-core interface=sfp-sfpplus12 \
    frame-types=admit-only-vlan-tagged \
    comment="Reserved trunk"
add bridge=bridge-core interface=sfp-sfpplus13 \
    frame-types=admit-only-vlan-tagged \
    comment="Reserved trunk"
add bridge=bridge-core interface=sfp-sfpplus14 \
    frame-types=admit-only-vlan-tagged \
    comment="Reserved trunk"

# ============================================================
# STEP 3: BRIDGE VLAN TABLE
# CPU port (bridge-core) tagged on VLAN 10 only for management
# ============================================================
/interface bridge vlan
add bridge=bridge-core vlan-ids=10 \
    tagged=bridge-core,sfp-sfpplus1,sfp-sfpplus2,sfp-sfpplus3,sfp-sfpplus4,sfp-sfpplus5,sfp-sfpplus6,sfp-sfpplus7,sfp-sfpplus8,sfp-sfpplus9,sfp-sfpplus10,sfp-sfpplus11,sfp-sfpplus12,sfp-sfpplus13,sfp-sfpplus14
add bridge=bridge-core vlan-ids=20 \
    tagged=sfp-sfpplus1,sfp-sfpplus2,sfp-sfpplus3,sfp-sfpplus4,sfp-sfpplus5,sfp-sfpplus6,sfp-sfpplus7,sfp-sfpplus8,sfp-sfpplus9,sfp-sfpplus10,sfp-sfpplus11,sfp-sfpplus12,sfp-sfpplus13,sfp-sfpplus14
add bridge=bridge-core vlan-ids=30 \
    tagged=sfp-sfpplus1,sfp-sfpplus2,sfp-sfpplus3,sfp-sfpplus4,sfp-sfpplus5,sfp-sfpplus6,sfp-sfpplus7,sfp-sfpplus8,sfp-sfpplus9,sfp-sfpplus10,sfp-sfpplus11,sfp-sfpplus12,sfp-sfpplus13,sfp-sfpplus14
add bridge=bridge-core vlan-ids=40 \
    tagged=sfp-sfpplus1,sfp-sfpplus2,sfp-sfpplus3,sfp-sfpplus4,sfp-sfpplus5,sfp-sfpplus6,sfp-sfpplus7,sfp-sfpplus8,sfp-sfpplus9,sfp-sfpplus10,sfp-sfpplus11,sfp-sfpplus12,sfp-sfpplus13,sfp-sfpplus14
add bridge=bridge-core vlan-ids=50 \
    tagged=sfp-sfpplus1,sfp-sfpplus2,sfp-sfpplus3,sfp-sfpplus4,sfp-sfpplus5,sfp-sfpplus6,sfp-sfpplus7,sfp-sfpplus8,sfp-sfpplus9,sfp-sfpplus10,sfp-sfpplus11,sfp-sfpplus12,sfp-sfpplus13,sfp-sfpplus14
add bridge=bridge-core vlan-ids=60 \
    tagged=sfp-sfpplus1,sfp-sfpplus2,sfp-sfpplus3,sfp-sfpplus4,sfp-sfpplus5,sfp-sfpplus6,sfp-sfpplus7,sfp-sfpplus8,sfp-sfpplus9,sfp-sfpplus10,sfp-sfpplus11,sfp-sfpplus12,sfp-sfpplus13,sfp-sfpplus14
add bridge=bridge-core vlan-ids=70 \
    tagged=sfp-sfpplus1,sfp-sfpplus2,sfp-sfpplus3,sfp-sfpplus4,sfp-sfpplus5,sfp-sfpplus6,sfp-sfpplus7,sfp-sfpplus8,sfp-sfpplus9,sfp-sfpplus10,sfp-sfpplus11,sfp-sfpplus12,sfp-sfpplus13,sfp-sfpplus14

# ============================================================
# STEP 4: MANAGEMENT IP (VLAN 10)
# ============================================================
/interface vlan
add interface=bridge-core vlan-id=10 name=vlan10-mgmt \
    comment="VLAN10 Management"

/ip address
add address=192.168.10.2/24 interface=vlan10-mgmt \
    comment="CRS326 management IP"

/ip route
add dst-address=0.0.0.0/0 gateway=192.168.10.1 \
    comment="Default route via Router"

/ip dns
set servers=8.8.8.8,1.1.1.1

# ============================================================
# STEP 5: FIREWALL – restrict management access
# ============================================================
/ip firewall filter
add chain=input action=accept \
    connection-state=established,related \
    comment="Accept established/related"
add chain=input action=drop \
    connection-state=invalid \
    comment="Drop invalid"
add chain=input action=drop \
    src-address-list=brute_force \
    log=yes log-prefix="BF-DROP: " \
    comment="Drop brute-force blacklisted IPs"
add chain=input action=add-src-to-address-list \
    protocol=tcp dst-port=22,8291 connection-state=new \
    src-address-list=bf_stage2 \
    address-list=brute_force address-list-timeout=1h \
    comment="Brute-force stage3 – blacklist 1h"
add chain=input action=add-src-to-address-list \
    protocol=tcp dst-port=22,8291 connection-state=new \
    src-address-list=bf_stage1 \
    address-list=bf_stage2 address-list-timeout=1m \
    comment="Brute-force stage2"
add chain=input action=add-src-to-address-list \
    protocol=tcp dst-port=22,8291 connection-state=new \
    address-list=bf_stage1 address-list-timeout=1m \
    comment="Brute-force stage1"
add chain=input action=accept \
    protocol=icmp limit=10,5:packet \
    comment="ICMP rate-limited 10pps"
add chain=input action=drop \
    protocol=icmp \
    comment="Drop excess ICMP"
add chain=input action=accept \
    protocol=tcp dst-port=22,8291 src-address=192.168.10.0/24 \
    comment="Allow Winbox/SSH from VLAN10"
add chain=input action=accept \
    protocol=tcp dst-port=22,8291 src-address=10.10.10.0/24 \
    comment="Allow Winbox/SSH from VPN"
add chain=input action=drop \
    log=yes log-prefix="SW-DROP: " \
    comment="Default drop all other input"

# ============================================================
# STEP 6: SERVICES HARDENING
# ============================================================
/ip service
set telnet   disabled=yes
set ftp      disabled=yes
set www      disabled=yes
set www-ssl  disabled=yes
set api      disabled=yes
set api-ssl  disabled=yes
set ssh      port=22   address=192.168.10.0/24,10.10.10.0/24
set winbox   port=8291 address=192.168.10.0/24,10.10.10.0/24

/tool bandwidth-server
set enabled=no

/tool mac-server
set allowed-interface-list=none

/tool mac-server mac-winbox
set allowed-interface-list=none

# ============================================================
# STEP 7: NTP + SYSTEM
# ============================================================
/system identity
set name=CRS326-Core

/system ntp client
set enabled=yes
/system ntp client servers
add address=time.google.com
add address=time.cloudflare.com
/system clock
set time-zone-name=Asia/Ho_Chi_Minh

/system scheduler
add name=weekly-backup interval=7d start-time=02:30:00 \
    on-event="/export compact file=crs326-weekly-backup" \
    comment="Weekly config backup"

# !! Đổi tài khoản admin mặc định trước khi production:
# /user add name=<TEN_MOI> password="<MAT_KHAU_MANH>" group=full
# /user remove admin
