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
# VLAN60 → UNTAGGED (native)
/interface bridge vlan set [find vlan-ids=60] untagged=([get [find vlan-ids=60] untagged],ether1)

# VLAN20 → TAGGED
/interface bridge vlan set [find vlan-ids=20] tagged=([get [find vlan-ids=20] tagged],ether1)

# Nếu cú pháp nối danh sách ở trên báo lỗi, làm thủ công:
#   1. /interface bridge vlan print   → chép danh sách hiện có
#   2. Gõ lại đầy đủ, thêm ether1 vào cuối. Ví dụ:
#      /interface bridge vlan set [find vlan-ids=60] untagged=ether2,ether3,ether1
#   !! Cẩn thận: set sẽ GHI ĐÈ toàn bộ danh sách, thiếu cổng nào là
#   !! cổng đó mất mạng.

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
