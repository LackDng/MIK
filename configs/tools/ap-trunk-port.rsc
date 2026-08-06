# ============================================================
# CÔNG THỨC: Cổng trunk cho AP WiFi
#   VLAN 60 = native/untagged  (SSID Office + quản trị AP)
#   VLAN 20 = tagged           (SSID Wifi Guest)
# ============================================================
#
# !! CHẠY TRÊN CRS328 (IT-ROOM / NHA LA / APART) hoặc CORE.
# !! KHÔNG chạy trên CCR2004: ether1 của router là WAN BACKUP PPPoE
# !!   (VNPT). Biến nó thành trunk sẽ mất đường dự phòng internet.
#
# Tên bridge theo từng thiết bị:
#   CRS328  → bridge-access
#   CRS326  → bridge-core
#   CCR2004 → bridge-lan
#
# Ví dụ dưới dùng ether1 trên CRS328. Đổi tên cổng nếu cần.
# ============================================================

# ------------------------------------------------------------
# ĐIỂM MẤU CHỐT: frame-types=admit-all
# ------------------------------------------------------------
# Cổng này nhận ĐỒNG THỜI 2 loại frame:
#   - untagged  (VLAN60 – AP gửi traffic SSID Office không gắn tag)
#   - tagged 20 (VLAN20 – AP gắn tag cho SSID Guest)
#
# Nếu đặt sai frame-types thì:
#   admit-only-vlan-tagged                  → mất VLAN60 (untagged bị drop)
#   admit-only-untagged-and-priority-tagged → mất VLAN20 (tagged bị drop)
#   admit-all                               → ĐÚNG, nhận cả hai
#
# pvid=60 : frame untagged đi vào sẽ được gán VLAN60
# ingress-filtering=yes : chỉ cho phép VLAN có trong bảng, chặn VLAN lạ

# ------------------------------------------------------------
# BƯỚC 1: Xem hiện trạng TRƯỚC khi sửa (để biết cần giữ gì)
# ------------------------------------------------------------
/interface bridge port print where interface=ether1
/interface bridge vlan print

# ------------------------------------------------------------
# BƯỚC 2: Cấu hình bridge port
# ------------------------------------------------------------
# Nếu ether1 ĐÃ là bridge port → dùng set:
/interface bridge port set [find interface=ether1] pvid=60 frame-types=admit-all ingress-filtering=yes comment="AP WiFi - VLAN60 native + VLAN20 guest"

# Nếu ether1 CHƯA có trong bridge → dùng add (chỉ chạy 1 trong 2):
# /interface bridge port add bridge=bridge-access interface=ether1 pvid=60 frame-types=admit-all ingress-filtering=yes comment="AP WiFi - VLAN60 native + VLAN20 guest"

# ------------------------------------------------------------
# BƯỚC 3: Thêm ether1 vào bảng VLAN
# ------------------------------------------------------------
#
# VLAN60 (untagged/native): KHÔNG cần làm gì.
#   pvid=60 ở BƯỚC 2 tự sinh entry động, xem bằng:
#     /interface bridge vlan print
#   sẽ thấy dòng ";;; added by pvid" với untagged=ether1
#
# VLAN20 (tagged): PHẢI thêm thủ công – pvid không tạo tagged.
#
# !! KHÔNG dùng cú pháp nối kiểu:
# !!   tagged=([get [find vlan-ids=20] tagged],ether1)
# !! → báo lỗi "invalid internal item number" vì `get` trả về
# !!   internal ID (*8) chứ không phải tên cổng.

# 3a. Xem danh sách hiện tại – print detail hiện TÊN cổng:
/interface bridge vlan print detail where vlan-ids=20

# 3b. Gõ lại ĐẦY ĐỦ danh sách cũ + ether1 ở cuối.
#     Ví dụ nếu bước 3a cho tagged=sfp-sfpplus1 :
/interface bridge vlan set [find vlan-ids=20] tagged=sfp-sfpplus1,ether1

# !! set GHI ĐÈ toàn bộ danh sách. Chép nguyên danh sách cũ,
# !! thiếu cổng nào là cổng đó mất VLAN20 ngay lập tức.

# (Tuỳ chọn) Nếu muốn khai báo VLAN60 untagged tường minh thay vì
# dựa vào entry động – làm y hệt cách trên:
#   /interface bridge vlan print detail where vlan-ids=60
#   /interface bridge vlan set [find vlan-ids=60] untagged=<danh sách cũ>,ether1

# ------------------------------------------------------------
# BƯỚC 4: Cấp nguồn PoE cho AP (CRS328-24P có PoE)
# ------------------------------------------------------------
/interface ethernet poe set [find name=ether1] poe-out=auto-on
# Kiểm tra AP đã ăn điện chưa:
/interface ethernet poe monitor ether1 once

# ------------------------------------------------------------
# BƯỚC 5: KIỂM TRA
# ------------------------------------------------------------
/interface bridge vlan print
#   VLAN 60 → cột CURRENT-UNTAGGED phải có ether1
#   VLAN 20 → cột CURRENT-TAGGED   phải có ether1

/interface bridge port print where interface=ether1
#   pvid=60, frame-types=admit-all

# AP phải nhận IP trong dải 192.168.0.100–200 (DHCP VLAN60 từ router):
/interface bridge host print where on-interface=ether1

# ============================================================
# LÀM TRÊN CSS610 (SwOS) – Web UI, KHÔNG có CLI
# ============================================================
#
# ---- Tab "VLAN" (cấu hình từng cổng) ----
#
#   Port1:
#     VLAN Mode       : strict          ← lọc VLAN lạ (giống ingress-filtering=yes)
#     VLAN Receive    : any             ← !! PHẢI LÀ "any"
#     Default VLAN ID : 60              ← PVID, gán VLAN60 cho frame untagged
#     Force VLAN ID   : ☐ (BỎ TRỐNG)    ← tick vào sẽ ép MỌI frame về VLAN60,
#                                          phá luôn VLAN20 tagged
#
#   !! LỖI HAY GẶP: đặt VLAN Receive = "only tagged"
#      → chặn hết frame untagged → MẤT VLAN60 (SSID Office + quản trị AP).
#      Cổng AP nhận CẢ HAI loại frame nên bắt buộc dùng "any".
#
#      only tagged   → mất VLAN60 (untagged bị drop)
#      only untagged → mất VLAN20 (tagged bị drop)
#      any           → ĐÚNG
#
# ---- Tab "VLANs" (bảng thành viên VLAN) – BẮT BUỘC, đừng bỏ qua ----
#
#   VLAN 60 → Port1 = untagged  +  cổng uplink SFP = tagged
#   VLAN 20 → Port1 = tagged    +  cổng uplink SFP = tagged
#
#   !! KHÁC BIỆT QUAN TRỌNG SO VỚI RouterOS:
#      RouterOS tự sinh entry untagged từ pvid (";;; added by pvid").
#      SwOS KHÔNG tự làm. "Default VLAN ID = 60" chỉ xử lý chiều VÀO;
#      chiều RA vẫn cần khai báo Port1 là untagged của VLAN60 trong
#      tab VLANs. Thiếu bước này → AP nhận được gói nhưng không gửi
#      ra được, biểu hiện "kết nối chập chờn / không lấy được IP".
#
#   Với VLAN Mode = strict, VLAN nào không khai báo trong bảng sẽ bị
#   drop hoàn toàn → phải có đủ cả 2 dòng VLAN 20 và 60.
#
# ---- Bảng đối chiếu RouterOS ↔ SwOS ----
#
#   | Mục đích              | RouterOS (CRS328)        | SwOS (CSS610)          |
#   |-----------------------|--------------------------|------------------------|
#   | PVID                  | pvid=60                  | Default VLAN ID = 60   |
#   | Nhận tagged+untagged  | frame-types=admit-all    | VLAN Receive = any     |
#   | Lọc VLAN lạ           | ingress-filtering=yes    | VLAN Mode = strict     |
#   | VLAN20 tagged         | bridge vlan tagged=ether1| VLANs tab: 20→tagged   |
#   | VLAN60 untagged       | TỰ ĐỘNG từ pvid          | VLANs tab: 60→untagged |
#
# ---- PoE cho AP ----
#   Tab "PoE" → Port1 → bật (auto-on)
#
# (Nhãn trên giao diện có thể khác chút giữa SwOS 2.18 và 2.21 –
#  hệ thống đang chạy lẫn cả hai bản.)
#
# ============================================================
# PHÍA UNIFI CONTROLLER (làm song song)
# ============================================================
# Networks:
#   - Office     : VLAN 60  → đặt làm mạng quản trị AP (native)
#   - Wifi Guest : VLAN 20
#
# WiFi (SSID):
#   - SSID Office → Network = Office (VLAN 60)
#   - SSID Guest  → Network = Wifi Guest (VLAN 20)
#
# AP sẽ tự lấy IP quản trị từ DHCP VLAN60 (192.168.0.100–200),
# controller cùng VLAN60 nên adopt được trực tiếp, không cần
# định tuyến liên VLAN.
# ============================================================
