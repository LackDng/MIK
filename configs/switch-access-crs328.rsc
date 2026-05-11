# ============================================================
# BLOCK 3: ACCESS SWITCH – MikroTik CRS328-24P-4S+RM
# RouterOS v7 – Layer 2 only
# ============================================================
#
# PORT MAPPING TABLE:
# +----------------+---------------------------------------+------------+
# | Interface      | Connected to                          | Module     |
# +----------------+---------------------------------------+------------+
# | sfp-sfpplus1   | ← Core CRS326 (uplink trunk all VLAN) | S-31DLC20D |
# |                |   1G SFP in 10G port – auto-neg to 1G |            |
# | ether1–ether24 | Not configured (PoE access ports)     | —          |
# +----------------+---------------------------------------+------------+
#
# NOTE: S-31DLC20D is a 1G SFP module in sfp-sfpplus1 (10G port).
#       RouterOS auto-negotiates to 1G – this is expected behavior.
#
# Management: 192.168.10.3/24 via VLAN 10
# ============================================================

# ============================================================
# STEP 1: RESET (chạy TAY trước khi import file này)
# ============================================================
# Terminal: /system reset-configuration no-defaults=yes skip-backup=yes
# Đợi reboot → kết nối lại → /import file-name=switch-access-crs328.rsc

# ============================================================
# STEP 2: BRIDGE
# ============================================================
/interface bridge
add name=bridge-access vlan-filtering=yes comment="Access switch bridge"

# Uplink trunk port only (ether1-24 not yet assigned)
/interface bridge port
add bridge=bridge-access interface=sfp-sfpplus1 \
    frame-types=admit-only-vlan-tagged \
    comment="Uplink to Core CRS326 – trunk all VLAN"

# ether1-24: add access ports here when needed
# Example – to assign etherX as access port for VLAN YY:
#   /interface bridge port
#   add bridge=bridge-access interface=etherX \
#       pvid=YY frame-types=admit-only-untagged-and-priority-tagged
#   /interface bridge vlan
#   add bridge=bridge-access vlan-ids=YY untagged=etherX

# ============================================================
# STEP 3: BRIDGE VLAN TABLE
# CPU port (bridge-access) tagged on VLAN 10 only for management
# ============================================================
/interface bridge vlan
add bridge=bridge-access vlan-ids=10 tagged=bridge-access,sfp-sfpplus1
add bridge=bridge-access vlan-ids=20 tagged=sfp-sfpplus1
add bridge=bridge-access vlan-ids=30 tagged=sfp-sfpplus1
add bridge=bridge-access vlan-ids=40 tagged=sfp-sfpplus1
add bridge=bridge-access vlan-ids=50 tagged=sfp-sfpplus1
add bridge=bridge-access vlan-ids=60 tagged=sfp-sfpplus1
add bridge=bridge-access vlan-ids=70 tagged=sfp-sfpplus1

# ============================================================
# STEP 4: MANAGEMENT IP (VLAN 10)
# ============================================================
/interface vlan
add interface=bridge-access vlan-id=10 name=vlan10-mgmt \
    comment="VLAN10 Management"

/ip address
add address=192.168.10.3/24 interface=vlan10-mgmt \
    comment="CRS328 management IP"

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
add chain=input action=accept \
    src-address=192.168.10.0/24 \
    comment="Whitelist VLAN10 – bypass brute-force check"
add chain=input action=accept \
    src-address=10.10.10.0/24 \
    comment="Whitelist VPN – bypass brute-force check"
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
set name=CRS328-Access

/system ntp client
set enabled=yes
/system ntp client servers
add address=time.google.com
add address=time.cloudflare.com
/system clock
set time-zone-name=Asia/Ho_Chi_Minh

/system scheduler
add name=weekly-backup interval=7d start-time=03:00:00 \
    on-event="/export compact file=crs328-weekly-backup" \
    comment="Weekly config backup"

# !! Đổi tài khoản admin mặc định trước khi production:
# /user add name=<TEN_MOI> password="<MAT_KHAU_MANH>" group=full
# /user remove admin
