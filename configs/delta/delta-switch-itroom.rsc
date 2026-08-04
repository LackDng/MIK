# ============================================================
# DELTA – IT-ROOM (CRS328, backup IT482026)
# Paste vào Winbox Terminal (KHÔNG /import, không reset)
# ============================================================
# Backup cho thấy: firewall đã có đủ rule VLAN60 (R10/R11),
# NHƯNG:
#  - User "admin" mặc định VẪN CÒN TỒN TẠI (lỗ hổng bảo mật)
#  - ICMP chỉ accept từ MGMT, chưa rate-limit như chuẩn chung
#  - Chưa bật igmp-snooping
# ============================================================

# ------------------------------------------------------------
# 1. BẢO MẬT – GỠ USER admin MẶC ĐỊNH
# !! Đăng nhập bằng user quản trị riêng (Theindochine) TRƯỚC
# !! khi chạy lệnh này, xác nhận đăng nhập OK rồi mới xóa admin
# ------------------------------------------------------------
/user remove [find name=admin]

# ------------------------------------------------------------
# 2. IGMP snooping (đồng bộ toàn hệ thống)
# ------------------------------------------------------------
/interface bridge set [find name=bridge-access] igmp-snooping=yes

# ------------------------------------------------------------
# 3. ICMP: đổi sang rate-limit 10pps (đồng bộ chuẩn chung)
# ------------------------------------------------------------
/ip firewall filter set [find comment="R7 ICMP from MGMT"] \
    in-interface-list="" limit=10,5:packet comment="R7 ICMP rate-limited 10pps"
/ip firewall filter add chain=input action=drop protocol=icmp \
    comment="R7b Drop excess ICMP" \
    place-before=[find comment="R8 Winbox from VLAN10"]

# ------------------------------------------------------------
# 4. KIỂM TRA
# ------------------------------------------------------------
# /user print                → chỉ còn user quản trị riêng
# /interface bridge print    → igmp-snooping=yes
