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
# 6. Sửa comment bridge port cho ĐÚNG thực tế
#    (bridge port comment đang SAI: sfp2 ghi "CSS610" nhưng thực ra là
#     IT-ROOM; sfp3 ghi "CRS328" nhưng thực ra là CSS610)
# ------------------------------------------------------------
/interface bridge port set [find interface=sfp-sfpplus1]  comment="Uplink to Router CCR2004 (192.168.10.1)"
/interface bridge port set [find interface=sfp-sfpplus2]  comment="Downlink to CRS328 IT-ROOM (192.168.10.3)"
/interface bridge port set [find interface=sfp-sfpplus3]  comment="Downlink to CSS610 Bungalow 9-10 (192.168.10.12)"
/interface bridge port set [find interface=sfp-sfpplus4]  comment="Downlink to CSS610 Vila 5-6 (192.168.10.6)"
/interface bridge port set [find interface=sfp-sfpplus5]  comment="Downlink to CRS328 NHA LA (192.168.10.4)"
/interface bridge port set [find interface=sfp-sfpplus6]  comment="Downlink to CSS610 Villa 11-12 (192.168.10.8)"
/interface bridge port set [find interface=sfp-sfpplus7]  comment="Downlink to CRS328 APART (192.168.10.5)"
/interface bridge port set [find interface=sfp-sfpplus8]  comment="Downlink to CSS610 Vila 9-10 (192.168.10.9)"
/interface bridge port set [find interface=sfp-sfpplus9]  comment="Downlink to CSS610 Bungalow 7-8 (192.168.10.11)"
/interface bridge port set [find interface=sfp-sfpplus10] comment="Downlink to CSS610 Vila 3-4 (192.168.10.10)"
/interface bridge port set [find interface=sfp-sfpplus11] comment="Downlink to CSS610 Vila 1-2 (192.168.10.15)"
/interface bridge port set [find interface=sfp-sfpplus12] comment="Downlink to CSS610 Vila 7-8 (192.168.10.7)"
/interface bridge port set [find interface=sfp-sfpplus13] comment="Downlink to CSS610 Bungalow 13-14 (192.168.10.14)"
/interface bridge port set [find interface=sfp-sfpplus14] comment="Downlink to CSS610 Bungalow 11-12 (192.168.10.13)"

# Comment trên interface vật lý (hiện trong Winbox Interfaces list)
/interface ethernet set [find name=sfp-sfpplus2]  comment="To IT-ROOM (CRS328)"
/interface ethernet set [find name=sfp-sfpplus3]  comment="To Bungalow 9-10"
/interface ethernet set [find name=sfp-sfpplus4]  comment="To Vila 5-6"
/interface ethernet set [find name=sfp-sfpplus5]  comment="To NHA LA (CRS328)"
/interface ethernet set [find name=sfp-sfpplus6]  comment="To Villa 11-12"
/interface ethernet set [find name=sfp-sfpplus7]  comment="To APART (CRS328)"
/interface ethernet set [find name=sfp-sfpplus8]  comment="To Vila 9-10"
/interface ethernet set [find name=sfp-sfpplus9]  comment="To Bungalow 7-8"
/interface ethernet set [find name=sfp-sfpplus10] comment="To Vila 3-4"
/interface ethernet set [find name=sfp-sfpplus11] comment="To Vila 1-2"
/interface ethernet set [find name=sfp-sfpplus12] comment="To Vila 7-8"
/interface ethernet set [find name=sfp-sfpplus13] comment="To Bungalow 13-14"
/interface ethernet set [find name=sfp-sfpplus14] comment="To Bungalow 11-12"

# !! LƯU Ý: comment cũ ghi sfp-sfpplus14 = "To 11-12" gây hiểu nhầm.
#    sfp14 = BUNGALOW 11-12 (.10.13), KHÔNG phải Villa 11-12.
#    Villa 11-12 (.10.8) nằm ở sfp-sfpplus6.

# ------------------------------------------------------------
# 7. GỠ VLAN30 TRÊN CORE (vẫn còn – xác nhận 04/08/2026)
#
# !! LÀM SAU KHI đã gỡ VLAN30 trên ROUTER và chuyển hết client
# !! (AP management) sang VLAN60. Gỡ sớm sẽ cắt mạng thiết bị
# !! đang dùng VLAN30.
# ------------------------------------------------------------
/interface bridge vlan print where bridge=bridge-core
# Nếu thấy dòng vlan-ids=30 → gỡ bằng:
# /interface bridge vlan remove [find bridge=bridge-core vlan-ids=30]

# Kiểm tra các CRS328 có còn VLAN30 không (chạy trên từng switch):
#   /interface bridge vlan print
# Nếu còn → /interface bridge vlan remove [find vlan-ids=30]

# ------------------------------------------------------------
# 7. KIỂM TRA
# ------------------------------------------------------------
# /interface bridge print                          → priority=0x1000 (4096)
# /interface bridge monitor bridge-core            → root-bridge=yes (sau vài giây)
# /log print where message~"loop"                  → không còn cảnh báo mới
