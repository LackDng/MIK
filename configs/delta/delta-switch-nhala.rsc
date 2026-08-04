# ============================================================
# DELTA – NHA LA (CRS328, backup NL482026)
# Paste vào Winbox Terminal (KHÔNG /import, không reset)
# ============================================================
# Backup cho thấy firewall bản CŨ:
#  - Thiếu whitelist VLAN60 → user VLAN60 KHÔNG quản trị được
#  - Không có rule Winbox/SSH riêng (chỉ dựa vào whitelist)
#  - Log prefix SW-DROP (cũ)
#  - Chưa bật igmp-snooping
# ============================================================

# ------------------------------------------------------------
# 1. IGMP snooping
# ------------------------------------------------------------
/interface bridge set [find name=bridge-access] igmp-snooping=yes

# ------------------------------------------------------------
# 2. INPUT: thêm quyền quản trị từ VLAN60
#    (chèn trước rule Whitelist VPN)
#
# LƯU Ý: comment gốc trên thiết bị chứa dấu gạch ngang dài "–" thường
#        KHÔNG copy/paste được → find so khớp CHÍNH XÁC sẽ trả về rỗng
#        và place-before báo "no such item".
#        → Dùng "~" (so khớp chuỗi con) thay cho "=".
#        → Viết 1 dòng, tránh nối dòng bằng "\" trong Winbox Terminal.
# ------------------------------------------------------------
/ip firewall filter add chain=input action=accept src-address=192.168.0.0/24 comment="Whitelist VLAN60 Office" place-before=[find comment~"Whitelist VPN"]

# ------------------------------------------------------------
# 3. /ip service: cho phép VLAN60
# ------------------------------------------------------------
/ip service set ssh    address=192.168.10.0/24,192.168.0.0/24,10.10.10.0/24
/ip service set winbox address=192.168.10.0/24,192.168.0.0/24,10.10.10.0/24

# ------------------------------------------------------------
# 4. Đồng bộ log prefix
# ------------------------------------------------------------
/ip firewall filter set [find log-prefix="SW-DROP: "] log-prefix="INPUT-DROP: "

# ------------------------------------------------------------
# 5. KIỂM TRA
# ------------------------------------------------------------
# Từ PC VLAN60 (192.168.0.x): mở Winbox tới IP của NHA LA → OK
# /interface bridge print → igmp-snooping=yes
