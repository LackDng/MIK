# ============================================================
# CÔNG CỤ: Xác định thiết bị nào đang cắm ở cổng nào
# Paste vào Winbox Terminal của switch cần kiểm tra
# ============================================================

# ------------------------------------------------------------
# CÁCH 1: NHANH – chỉ thấy thiết bị MikroTik RouterOS
# ------------------------------------------------------------
/ip neighbor print
#
# Ưu điểm : có sẵn tên (identity), model, phiên bản
# Nhược   : CSS610 chạy SwOS KHÔNG hiện (không phát MNDP qua cổng vật lý).
#           Thiết bị hãng khác (camera, AP, NVR) cũng thường không hiện.
# → Chỉ dùng để xem nhanh, KHÔNG dùng làm nguồn tin duy nhất.

# Bật thêm LLDP/CDP để bắt được nhiều hãng hơn:
# /ip neighbor discovery-settings set protocol=cdp,lldp,mndp


# ------------------------------------------------------------
# CÁCH 2: CHÍNH XÁC NHẤT – bảng MAC (thấy MỌI thiết bị)
# ------------------------------------------------------------
# Thiết bị nào cũng phải gửi frame → switch luôn học được MAC.
# local=no : bỏ qua MAC của chính switch, chỉ xem thiết bị bên ngoài

/interface bridge host print where local=no vid=10

# Biết CỔNG → hỏi có gì trên đó:
# /interface bridge host print where on-interface=sfp-sfpplus6

# Biết MAC → hỏi nằm ở cổng nào:
# /interface bridge host print where mac-address=F4:1E:57:C1:EF:40


# ------------------------------------------------------------
# CÁCH 3: BẢNG ĐẦY ĐỦ  CỔNG | MAC | IP  (khuyên dùng)
# ------------------------------------------------------------
# Bước 1 – nạp bảng ARP trước (quét subnet quản trị ~15 giây):
/tool ip-scan address-range=192.168.10.0/24 duration=15

# Bước 2 – in bảng ghép (PASTE NGUYÊN 1 DÒNG):
:put "PORT | MAC | IP"; :foreach h in=[/interface bridge host find where local=no vid=10] do={ :local m [/interface bridge host get $h mac-address]; :local p [/interface bridge host get $h on-interface]; :local ip "-"; :foreach a in=[/ip arp find where mac-address=$m] do={ :set ip [/ip arp get $a address] }; :put "$p | $m | $ip" }

# Kết quả ví dụ (chạy trên CORE):
#   sfp-sfpplus6 | F4:1E:57:C1:EF:40 | 192.168.10.8
#   sfp-sfpplus2 | 04:F4:1C:D2:1D:E2 | 192.168.10.3
#
# Muốn xem VLAN khác thì đổi vid=10 thành vid=60, vid=70...


# ------------------------------------------------------------
# CÁCH 4: XÁC ĐỊNH VẬT LÝ (khi cần tìm đúng sợi dây trong rack)
# ------------------------------------------------------------
# 4a. Số serial module SFP là dấu vân tay duy nhất – đọc rồi soi
#     nhãn trên module thật, KHÔNG cần rút dây:
/interface ethernet monitor sfp-sfpplus6 once
#     → sfp-vendor-name, sfp-vendor-part-number, sfp-vendor-serial

# 4b. Xem cổng nào đang có traffic (thiết bị còn sống hay đã chết):
/interface print stats where name~"sfp-sfpplus"

# 4c. Cách cuối – tắt cổng và xem khu nào mất mạng.
#     !! GÂY GIÁN ĐOẠN, chỉ làm ngoài giờ, nhớ bật lại:
# /interface ethernet disable sfp-sfpplus6
# ... kiểm tra ...
# /interface ethernet enable sfp-sfpplus6


# ------------------------------------------------------------
# GIẢI PHÁP LÂU DÀI: ĐẶT COMMENT CHO TỪNG CỔNG
# ------------------------------------------------------------
# Sau khi map xong 1 lần, ghi luôn vào comment để lần sau
# chỉ cần nhìn Winbox là biết, không phải tra lại:
#
#   /interface ethernet set [find name=sfp-sfpplus6] comment="To Villa 11-12"
#   /interface bridge port set [find interface=sfp-sfpplus6] comment="CSS610 Villa 11-12 (192.168.10.8)"
#
# Bản đồ 14 cổng CORE đã map sẵn trong:
#   configs/switch-core-crs326.rsc        (phần PORT MAPPING TABLE)
#   configs/delta/delta-switch-core.rsc   (mục 6 – lệnh set comment)
#
# !! Comment PHẢI cập nhật mỗi lần đổi dây, nếu không nó còn nguy hiểm
# !! hơn không có comment – vì người sau sẽ tin vào thông tin sai.
# ============================================================
