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
/interface bridge port set [find interface=sfp-sfpplus2]  comment="Downlink to CRS328 IT-ROOM (192.168.10.3)"
/interface bridge port set [find interface=sfp-sfpplus5]  comment="Downlink to CRS328 NHA LA (192.168.10.4)"
/interface bridge port set [find interface=sfp-sfpplus7]  comment="Downlink to CRS328 APART (192.168.10.5)"
/interface bridge port set [find interface=sfp-sfpplus14] comment="Downlink to CSS610 Villa 11-12 (192.168.10.8)"

# Comment trên interface vật lý (hiện trong Winbox Interfaces list)
/interface ethernet set [find name=sfp-sfpplus2]  comment="To IT-ROOM (CRS328)"
/interface ethernet set [find name=sfp-sfpplus5]  comment="To NHA LA (CRS328)"
/interface ethernet set [find name=sfp-sfpplus7]  comment="To APART (CRS328)"
/interface ethernet set [find name=sfp-sfpplus14] comment="To Villa 11-12 (CSS610)"

# ------------------------------------------------------------
# 6b. KIỂM TRA sfp-sfpplus14 có trong bảng VLAN chưa
#     (cổng này KHÔNG có trong file config cũ – nếu thiếu trong bảng
#      VLAN thì Villa 11-12 sẽ mất mạng hoàn toàn)
# ------------------------------------------------------------
/interface bridge vlan print where bridge=bridge-core
# Cột CURRENT-TAGGED của cả 6 VLAN phải có sfp-sfpplus14.
# Nếu THIẾU, thêm bằng (chạy từng dòng):
# /interface bridge vlan set [find vlan-ids=10] tagged=([get [find vlan-ids=10] tagged],sfp-sfpplus14)
# /interface bridge vlan set [find vlan-ids=20] tagged=([get [find vlan-ids=20] tagged],sfp-sfpplus14)
# /interface bridge vlan set [find vlan-ids=40] tagged=([get [find vlan-ids=40] tagged],sfp-sfpplus14)
# /interface bridge vlan set [find vlan-ids=50] tagged=([get [find vlan-ids=50] tagged],sfp-sfpplus14)
# /interface bridge vlan set [find vlan-ids=60] tagged=([get [find vlan-ids=60] tagged],sfp-sfpplus14)
# /interface bridge vlan set [find vlan-ids=70] tagged=([get [find vlan-ids=70] tagged],sfp-sfpplus14)

# ------------------------------------------------------------
# 6c. LẤY BẢN ĐỒ 9 CSS610 CÒN LẠI nằm ở cổng nào
#     MAC prefix của CSS610 là F4:1E:57:
# ------------------------------------------------------------
/interface bridge host print where vid=10
# Đối chiếu MAC với bảng trong configs/css610-swos.txt để biết
# khu nào (Vila/Bungalow) cắm ở cổng sfp nào, rồi cập nhật comment.

# ------------------------------------------------------------
# 7. KIỂM TRA
# ------------------------------------------------------------
# /interface bridge print                          → priority=0x1000 (4096)
# /interface bridge monitor bridge-core            → root-bridge=yes (sau vài giây)
# /log print where message~"loop"                  → không còn cảnh báo mới
