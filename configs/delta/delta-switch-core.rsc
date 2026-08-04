# ============================================================
# DELTA – CORE (CRS326, backup Co482026)
# Paste vào Winbox Terminal (KHÔNG /import, không reset)
# ============================================================
# Backup cho thấy:
#  - Bridge CHƯA set priority=4096 → CSS610 vẫn là RSTP Root
#    → nguyên nhân loop warning vẫn tiếp diễn!
#  - Thiếu whitelist + Winbox/SSH cho VLAN60
#  - Có rule whitelist VLAN10/VPN bị TRÙNG LẶP
#  - Port thực tế: sfp2→IT room, sfp5→Nha la, sfp7→Apartment,
#    sfp14→"11-12"
# ============================================================

# ------------------------------------------------------------
# 1. QUAN TRỌNG NHẤT: ép CRS326 làm Root Bridge + IGMP snooping
# ------------------------------------------------------------
/interface bridge set [find name=bridge-core] priority=4096 igmp-snooping=yes \
    comment="Core switch bridge - Root Bridge priority=4096"

# ------------------------------------------------------------
# 2. INPUT: thêm quyền quản trị từ VLAN60
#    (chèn trước rule Whitelist VPN)
#
# LƯU Ý: comment gốc chứa dấu "–" thường không paste được → dùng "~"
#        (so khớp chuỗi con) thay cho "=", viết 1 dòng.
# ------------------------------------------------------------
/ip firewall filter add chain=input action=accept src-address=192.168.0.0/24 comment="Whitelist VLAN60 Office" place-before=[find comment~"Whitelist VPN"]

# ------------------------------------------------------------
# 3. DỌN RULE TRÙNG LẶP (backup có 2 cặp Whitelist VLAN10/VPN)
# ------------------------------------------------------------
/ip firewall filter print where chain=input comment~"Whitelist"
# Nếu thấy 2 rule cùng comment "Whitelist VLAN10" hoặc "Whitelist VPN"
# → remove numbers=<số của rule thừa, giữ rule đứng TRƯỚC default drop>

# ------------------------------------------------------------
# 4. /ip service: cho phép VLAN60
# ------------------------------------------------------------
/ip service set ssh    address=192.168.10.0/24,192.168.0.0/24,10.10.10.0/24
/ip service set winbox address=192.168.10.0/24,192.168.0.0/24,10.10.10.0/24

# ------------------------------------------------------------
# 5. Đồng bộ log prefix
# ------------------------------------------------------------
/ip firewall filter set [find log-prefix="SW-DROP: "] log-prefix="INPUT-DROP: "

# ------------------------------------------------------------
# 6. Cập nhật comment port theo thực tế (tùy chọn, cho dễ quản lý)
# ------------------------------------------------------------
/interface ethernet set [find name=sfp-sfpplus2]  comment="To IT-ROOM (CRS328)"
/interface ethernet set [find name=sfp-sfpplus5]  comment="To NHA LA (CRS328)"
/interface ethernet set [find name=sfp-sfpplus7]  comment="To APART (CRS328)"
/interface ethernet set [find name=sfp-sfpplus14] comment="To 11-12"

# ------------------------------------------------------------
# 7. KIỂM TRA
# ------------------------------------------------------------
# /interface bridge print                          → priority=0x1000 (4096)
# /interface bridge monitor bridge-core            → root-bridge=yes (sau vài giây)
# /log print where message~"loop"                  → không còn cảnh báo mới
