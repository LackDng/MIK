# ============================================================
# DELTA – ROUTER firewall audit (dựa trên export thực tế 06/08/2026)
# Paste vào Winbox Terminal (KHÔNG /import, không reset)
# ============================================================
#
# PHÁT HIỆN NGHIÊM TRỌNG NHẤT:
# Chain FORWARD hiện KHÔNG còn rule DROP nào đang bật (kể cả R24
# Default deny FORWARD). RouterOS mặc định ACCEPT khi không rule nào
# khớp => TOÀN BỘ inter-VLAN đang thông nhau tự do, và camera CCTV
# (R20 Drop CCTV to internet đang tắt) ĐANG ra được internet.
#
# Ngoài ra có 1 rule không tên nằm TRƯỚC R1:
#   add action=accept chain=forward src-address=10.10.10.0/24
# Rule này accept MỌI traffic từ VPN đi MỌI nơi (không giới hạn đích),
# đứng trước R5-R9 nên các rule VPN chi tiết đó không bao giờ được xét
# tới (dead code). Client VPN hiện có full internet + full LAN access,
# không đúng với thiết kế split-tunnel.
# ============================================================

# ------------------------------------------------------------
# BƯỚC 0: XÓA RULE THỪA (làm trước, không ảnh hưởng gì đang chạy)
# ------------------------------------------------------------
# 0a. Rule VPN không giới hạn - phá vỡ toàn bộ kiểm soát VPN chi tiết
/ip firewall filter remove [find chain=forward src-address=10.10.10.0/24 comment=""]

# 0b. Rule trùng lặp của R4
/ip firewall filter remove [find chain=forward comment=" access VLAN60 to 10"]

# ------------------------------------------------------------
# BƯỚC 1: NHÓM AN TOÀN - bật ngay, không phụ thuộc rule khác,
#          không làm gián đoạn traffic đang chạy
# ------------------------------------------------------------
/ip firewall filter enable [find comment="R2 Drop invalid" chain=input]
/ip firewall filter enable [find comment="R3 Drop brute-force blacklisted IPs"]
/ip firewall filter enable [find comment="R4 Brute-force stage3 – blacklist 1h"]
/ip firewall filter enable [find comment="R5 Brute-force stage2"]
/ip firewall filter enable [find comment="R6 Brute-force stage1"]
/ip firewall filter enable [find comment="R7 ICMP from LAN rate-limited 10pps"]
/ip firewall filter enable [find comment="R8 Drop excess ICMP from LAN"]
/ip firewall filter enable [find comment="R2 Drop invalid" chain=forward]
/ip firewall filter enable [find comment="R2a Drop SYN flood blacklisted IPs"]
/ip firewall filter enable [find comment="R2b Detect SYN flood >50/s per IP"]
/ip firewall filter enable [find comment="R2c Drop if WAN src >100 concurrent TCP connections"]

# ------------------------------------------------------------
# BƯỚC 2: URGENT – vá lỗ hổng camera ra internet (bật NGAY, độc lập)
# ------------------------------------------------------------
/ip firewall filter enable [find comment="R20 Drop CCTV cameras to internet"]
# Kiểm tra ngay sau khi bật: NVR vẫn phải còn ra internet bình thường
# (R18/R19 accept NVR-1/NVR-2 đang bật sẵn, không đụng tới).

# ------------------------------------------------------------
# BƯỚC 3: PHẢI BẬT CÙNG NHAU – DSTNAT WAN inbound
#   R2d (accept DSTNAT'd) PHẢI bật TRƯỚC R2e (drop non-DSTNAT'd),
#   nếu chỉ bật R2e mà quên R2d => port-forward NVR/SQL từ internet
#   vào sẽ bị chặn ngay.
# ------------------------------------------------------------
/ip firewall filter enable [find comment="R2d Accept new WAN connections via DSTNAT (port forwarding)"]
/ip firewall filter enable [find comment="R2e Drop new connections from WAN (not DSTNAT'd)"]
# Test ngay: truy cập cam qua IP public 117.x.x.x:8054 từ internet ngoài.

# ------------------------------------------------------------
# BƯỚC 4: PHẢI BẬT TRỌN BỘ CÙNG LÚC – R24 Default deny FORWARD
#
# !! CẢNH BÁO: R24 là rule TỔNG. Bật MỘT MÌNH R24 mà không bật kèm
# !! toàn bộ accept bên dưới sẽ NGAY LẬP TỨC cắt: guest internet,
# !! IPTV internet, VoIP, VLAN10/60 liên thông quản trị.
# !! → Bật CẢ KHỐI này trong 1 lần, không tách lẻ.
# ------------------------------------------------------------
/ip firewall filter enable [find comment="R3 VLAN10 admin full access"]
/ip firewall filter enable [find comment="R4 VLAN60 can reach VLAN10"]
/ip firewall filter enable [find comment="R5 VPN access VLAN10"]
/ip firewall filter enable [find comment="R6 VPN access VLAN60"]
/ip firewall filter enable [find comment="R7 VPN access NVR-1:8054"]
/ip firewall filter enable [find comment="R8 VPN access NVR-2:8053"]
/ip firewall filter enable [find comment="R9 Drop VPN traffic not matched above"]
/ip firewall filter enable [find comment="R10 VLAN20 Guest internet"]
/ip firewall filter enable [find comment="R11 VLAN40 IPTV internet"]
/ip firewall filter enable [find comment="R14 VoIP SIP TCP internal"]
/ip firewall filter enable [find comment="R14 VoIP SIP UDP internal"]
/ip firewall filter enable [find comment="R15 VoIP RTP internal"]
/ip firewall filter enable [find comment="R16 VoIP SIP TCP to WAN"]
/ip firewall filter enable [find comment="R16 VoIP SIP UDP to WAN"]
/ip firewall filter enable [find comment="R17 VoIP RTP to WAN"]
/ip firewall filter enable [find comment="R21 VLAN10 admin full access to CCTV"]
# CUỐI CÙNG mới bật R24 (sau khi TẤT CẢ accept ở trên đã bật):
/ip firewall filter enable [find comment="R24 Default deny FORWARD"]

# Kiểm tra NGAY sau bước 4 (làm lần lượt, đừng bỏ qua):
#   - PC VLAN10 ping/Winbox được các switch VLAN60, VLAN70    (R3)
#   - PC VLAN60 Winbox/ping được VLAN10 management            (R4)
#   - Máy VLAN20 Guest mở được internet                        (R10)
#   - Đầu thu VLAN40 IPTV chạy được kênh                       (R11)
#   - Điện thoại VLAN50 gọi được ra ngoài                      (R14-17)
#   - VPN connect vào, truy cập VLAN10/60/NVR bình thường      (R5-R8)
#   - PC VLAN20 Guest KHÔNG vào được VLAN10 (phải bị chặn)
#   - Camera 192.168.5.x KHÔNG ra được internet (đã chặn ở BƯỚC 2)

# ============================================================
# PHÁT HIỆN 2: WAN interface list THIẾU pppoe-backup
# ============================================================
# So với file thiết kế router-ccr2004.rsc (list=WAN có cả pppoe-wan
# VÀ pppoe-backup), router đang chạy CHỈ có pppoe-wan trong list=WAN.
#
# Hệ quả: các rule dùng in-interface-list=WAN sẽ KHÔNG áp dụng cho
# traffic đến qua pppoe-backup khi đang failover sang VNPT.
#
# Kiểm tra hiện trạng:
/interface list member print where list=WAN

# Thêm pppoe-backup vào list=WAN:
/interface list member add interface=pppoe-backup list=WAN

# ------------------------------------------------------------
# PHÁT HIỆN 3: R13-R19 đang hardcode in-interface=pppoe-wan
#   thay vì in-interface-list=WAN
#
# !! HẬU QUẢ NGHIÊM TRỌNG: R13 "WireGuard UDP 13231 from WAN" chỉ
# !! accept traffic đến qua pppoe-wan. Khi Viettel down và hệ thống
# !! failover sang VNPT (pppoe-backup), gói WireGuard đến qua VNPT
# !! sẽ KHÔNG được accept bởi R13 → rơi xuống R20 Default drop
# !! → VPN MẤT HOÀN TOÀN đúng lúc đang cần nhất (khi Viettel down).
#
# Sau khi đã thêm pppoe-backup vào list=WAN (phát hiện 2), chuyển các
# rule sau từ hardcode sang list=WAN:
# ------------------------------------------------------------
/ip firewall filter set [find comment="R13 WireGuard UDP 13231 from WAN"] in-interface-list=WAN
/ip firewall filter set [find comment="R14 Drop Winbox from WAN"] in-interface-list=WAN
/ip firewall filter set [find comment="R15 Drop SSH from WAN"] in-interface-list=WAN
/ip firewall filter set [find comment="R16 Drop Telnet from WAN"] in-interface-list=WAN
/ip firewall filter set [find comment="R17 Drop API/API-SSL from WAN"] in-interface-list=WAN
/ip firewall filter set [find comment="R18 Drop HTTP/HTTPS from WAN"] in-interface-list=WAN
/ip firewall filter set [find comment="R19 Drop all from WAN"] in-interface-list=WAN

# !! LƯU Ý: R2a/R2b/R2c/R2d/R2e (forward chain, SYN flood + DSTNAT
# !! WAN) vẫn đang hardcode in-interface=pppoe-wan. Theo quyết định
# !! thiết kế đã chốt, port-forward (DSTNAT) CHỈ chạy qua Viettel nên
# !! R2d/R2e giữ nguyên pppoe-wan là ĐÚNG. Nhưng R2a/R2b/R2c (chống
# !! SYN flood/DDoS) nên bảo vệ luôn cả pppoe-backup:
/ip firewall filter set [find comment="R2a Drop SYN flood blacklisted IPs"] in-interface-list=WAN
/ip firewall filter set [find comment="R2b Detect SYN flood >50/s per IP"] in-interface-list=WAN
/ip firewall filter set [find comment="R2c Drop if WAN src >100 concurrent TCP connections"] in-interface-list=WAN

# ------------------------------------------------------------
# PHÁT HIỆN 4: bridge-lan CHƯA có priority=8192 + igmp-snooping=yes
#   (mục 1 của delta-router-ccr2004.rsc – có vẻ CHƯA được chạy)
# ------------------------------------------------------------
/interface bridge print detail where name=bridge-lan
# Nếu KHÔNG thấy priority=0x2000 (8192) và igmp-snooping=yes:
/interface bridge set [find name=bridge-lan] priority=8192 igmp-snooping=yes comment="Main LAN bridge - Secondary Root priority=8192"

# ============================================================
# KIỂM TRA TỔNG THỂ SAU KHI HOÀN TẤT
# ============================================================
/ip firewall filter print where chain=forward disabled=no
# Không được thấy dòng nào comment rỗng hoặc lạ ngoài danh sách R1-R24
/interface list member print where list=WAN
# Phải có đủ pppoe-wan VÀ pppoe-backup
