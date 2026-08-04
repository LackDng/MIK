# ============================================================
# DELTA – CCR2004-Router (backup R04082026)
# Paste từng khối vào Winbox Terminal (KHÔNG /import, không reset)
# Đưa router đang chạy về đúng thiết kế hiện tại
# ============================================================

# ------------------------------------------------------------
# 1. BRIDGE: set Secondary Root priority + IGMP snooping
#    (backup cho thấy bridge còn priority mặc định 32768)
# ------------------------------------------------------------
/interface bridge set [find name=bridge-lan] priority=8192 igmp-snooping=yes \
    comment="Main LAN bridge - Secondary Root priority=8192"

# ------------------------------------------------------------
# 2. INPUT: thêm quyền quản trị từ VLAN60 (backup thiếu hoàn toàn)
#    Chèn trước rule "R11 Winbox from VPN"
# ------------------------------------------------------------
/ip firewall filter
add chain=input action=accept protocol=tcp dst-port=8291 src-address=192.168.0.0/24 \
    comment="R10b Winbox from VLAN60 Office" place-before=[find comment="R11 Winbox from VPN"]
add chain=input action=accept protocol=tcp dst-port=22 src-address=192.168.0.0/24 \
    comment="R10c SSH from VLAN60 Office" place-before=[find comment="R11 Winbox from VPN"]

# ------------------------------------------------------------
# 3. /ip service: cho phép VLAN60 truy cập SSH/Winbox
# ------------------------------------------------------------
/ip service set ssh    address=192.168.10.0/24,192.168.0.0/24,10.10.10.0/24
/ip service set winbox address=192.168.10.0/24,192.168.0.0/24,10.10.10.0/24

# ------------------------------------------------------------
# 4. GỠ BỎ VLAN30 (backup còn nguyên: sub-if, DHCP, QoS wifi-mgmt)
# !! LƯU Ý: chuyển hết client đang dùng VLAN30 sang VLAN60 TRƯỚC
# !!         (đổi PVID/tag trên switch + SSID mgmt trên Unifi)
# ------------------------------------------------------------
/ip dhcp-server remove [find name=dhcp-vlan30]
/ip pool remove [find name=pool-vlan30]
/ip dhcp-server network remove [find comment~"VLAN30"]
/ip address remove [find comment="VLAN30 Manage Wifi GW"]
/interface bridge vlan remove [find vlan-ids=30]
/interface vlan remove [find name=bridge-lan.30]
/ip firewall address-list remove [find list=LOCAL_NETS comment="VLAN30 Manage Wifi"]
/ip firewall filter remove [find comment~"R12 VLAN30"]
/queue tree remove [find name=q-wifi-mgmt]
/ip firewall mangle remove [find comment="QoS mark Manage Wifi"]

# ------------------------------------------------------------
# 5. QoS: thêm queue tree cho pppoe-backup (backup chưa có)
#    → QoS vẫn hoạt động khi failover sang VNPT
# ------------------------------------------------------------
/queue tree
add name=wan-upload-bk parent=pppoe-backup max-limit=1000M comment="WAN BACKUP upload parent - 1Gbps"
add name=q-voip-bk   parent=wan-upload-bk packet-mark=voip   priority=1 limit-at=2M   max-limit=1000M comment="QoS VoIP backup"
add name=q-iptv-bk   parent=wan-upload-bk packet-mark=iptv   priority=2 limit-at=50M  max-limit=1000M comment="QoS IPTV backup"
add name=q-office-bk parent=wan-upload-bk packet-mark=office priority=4 limit-at=100M max-limit=1000M comment="QoS Office+WiFi backup"
add name=q-cctv-bk   parent=wan-upload-bk packet-mark=cctv   priority=5 limit-at=20M  max-limit=100M  comment="QoS CCTV backup"
add name=q-guest-bk  parent=wan-upload-bk packet-mark=guest  priority=8 limit-at=5M   max-limit=50M   comment="QoS Guest backup"

# ------------------------------------------------------------
# 6. SỬA WAN MONITORING (backup đang chạy bản CŨ bị lỗi:
#    netwatch KHÔNG tồn tại vì import fail routing-table param;
#    scripts + routing table cũ nằm chết không hoạt động)
# ------------------------------------------------------------
# 6a. Dọn bản cũ
/ip route remove [find comment~"Viettel health check"]
/routing table remove [find name=wan-check-viettel]

# 6b. Route ghim + blackhole (8.8.4.4 – KHÔNG dùng 8.8.8.8 vì là DNS chính)
/ip route
add dst-address=8.8.4.4/32 gateway=pppoe-wan scope=10 \
    comment="Viettel health check route - active khi pppoe-wan UP"
add dst-address=8.8.4.4/32 type=blackhole distance=254 \
    comment="Viettel health check blackhole - chan false-UP qua VNPT"

# 6c. Sửa up-script thành log-only (bản cũ enable pppoe-wan là dead-code)
/system script set [find name=wan-viettel-up] \
    source=":log warning \"WAN-FAILOVER: Viettel UP - Viettel is primary again (distance=1)\""

# 6d. Tạo netwatch (thành phần bị thiếu hoàn toàn trên router)
/tool netwatch
add host=8.8.4.4 interval=30s timeout=5s \
    up-script="/system script run wan-viettel-up" \
    down-script="/system script run wan-viettel-down" \
    comment="Monitor Viettel - ping 8.8.4.4 (pinned route via pppoe-wan)"

# scripts wan-viettel-down / wan-viettel-recovery + scheduler
# viettel-recovery-check ĐÃ có sẵn trên router (giữ nguyên)

# ------------------------------------------------------------
# 7. KIỂM TRA RULE NAT TRÙNG (backup nghi có 2x DSTNAT 8053
#    và 2x SRCNAT masquerade)
# ------------------------------------------------------------
/ip firewall nat print where comment~"DSTNAT WAN"
/ip firewall nat print where comment="SRCNAT Masquerade to WAN"
# Nếu thấy rule trùng lặp → remove numbers=<số của rule thừa>

# ------------------------------------------------------------
# 8. KIỂM TRA SAU KHI CHẠY
# ------------------------------------------------------------
# /ip route print where dst-address=8.8.4.4/32   → phải có 2 route (ghim + blackhole)
# /tool netwatch print                            → status=up
# /queue tree print                               → có cả wan-upload và wan-upload-bk
# /interface bridge vlan print                    → không còn vlan-ids=30
# /log print where message~"WAN-"
