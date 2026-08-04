# ============================================================
# DELTA – APART (CRS328, backup AP482026)
# Paste vào Winbox Terminal (KHÔNG /import, không reset)
# ============================================================
# Backup cho thấy firewall bản CŨ (giống NHA LA):
#  - Thiếu whitelist VLAN60
#  - Có 1 rule "Whitelist VLAN10" bị TRÙNG LẶP (nằm sau default drop)
#  - Log prefix SW-DROP (cũ)
#  - Chưa bật igmp-snooping
# ============================================================

# ------------------------------------------------------------
# 1. IGMP snooping
# ------------------------------------------------------------
/interface bridge set [find name=bridge-access] igmp-snooping=yes

# ------------------------------------------------------------
# 2. INPUT: thêm quyền quản trị từ VLAN60
#
# LƯU Ý: comment gốc chứa dấu "–" thường không paste được → dùng "~"
#        (so khớp chuỗi con) thay cho "=", viết 1 dòng.
# ------------------------------------------------------------
/ip firewall filter add chain=input action=accept src-address=192.168.0.0/24 comment="Whitelist VLAN60 Office" place-before=[find comment~"Whitelist VPN"]

# ------------------------------------------------------------
# 3. DỌN RULE TRÙNG LẶP
# ------------------------------------------------------------
/ip firewall filter print where chain=input comment~"Whitelist VLAN10"
# Nếu thấy 2 rule "Whitelist VLAN10" → remove numbers=<rule thừa,
# đặc biệt rule nằm SAU rule "Default drop" là vô dụng>

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
# 6. KIỂM TRA
# ------------------------------------------------------------
# Từ PC VLAN60 (192.168.0.x): mở Winbox tới IP của APART → OK
