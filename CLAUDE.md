# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## Repository Purpose

Lưu trữ toàn bộ cấu hình mạng doanh nghiệp MikroTik (RouterOS v7) cho một hệ thống gồm 4 thiết bị. File `mik.txt` là tài liệu yêu cầu thiết kế gốc (design spec/prompt). Thư mục `configs/` chứa config CLI thực tế sẵn sàng paste vào thiết bị.

## Cách áp dụng config lên thiết bị

Config là RouterOS `.rsc` script — KHÔNG chạy trực tiếp như shell script thông thường.

**Quy trình chuẩn (PHẢI làm theo đúng thứ tự):**

```
# Bước 1 – Reset thiết bị (chạy TAY trong Winbox hoặc SSH):
/system reset-configuration no-defaults=yes skip-backup=yes

# Bước 2 – Đợi reboot, kết nối lại, rồi import file:
/import file-name=<tên-file>.rsc
```

**Lý do không gộp reset vào file**: Router reboot giữa chừng khiến các lệnh sau thất bại do bridge mặc định bị xóa.

**CSS610 (SwOS)**: Không có CLI — cấu hình hoàn toàn qua Web GUI tại `http://192.168.10.4`. Xem `configs/css610-swos.txt` để có hướng dẫn từng bước theo tab giao diện.

## Topology & Device Roles

```
Internet → [Modem ISP]
               │ ether1 (PPPoE)
         [CCR2004]  ← Router Layer 3: routing, firewall, NAT, VPN, QoS, DHCP
               │ sfp-sfpplus1 (10G SMF, S+31DLC10D)
         [CRS326]  ← Core Switch Layer 2: pure switching, tất cả port trunk
          │       │
      sfp-sfpplus2  sfp-sfpplus3   (1G SMF, S-31DLC20D)
      [CSS610]   [CRS328]  ← Access Switch Layer 2: PoE ports chưa cấu hình
```

CCR2004 `ether11–ether16` kết nối thẳng Camera/NVR (VLAN 70, access untagged).

## VLAN Plan

| VLAN | Tên         | Subnet             | DHCP | Ghi chú |
|------|-------------|---------------------|------|---------|
| 10   | Management  | 192.168.10.0/24    | Không | Static only; quản lý tất cả thiết bị |
| 20   | Wifi Guest  | 172.16.20.0/22     | Có    | Giới hạn 50Mbps up/down |
| 30   | Manage Wifi | 172.16.30.0/24     | Có    | Management AP WiFi |
| 40   | IPTV Cloud  | 172.16.40.0/24     | Có    | |
| 50   | IP Phone    | 172.16.50.0/24     | Có    | DHCP option 66 → 172.16.50.10 (SIP) |
| 60   | Office      | 192.168.0.0/24     | Có    | |
| 70   | CCTV        | 192.168.5.0/24     | Không | Static only; camera block internet |

**Management IP thiết bị (tất cả qua VLAN 10):**
- Router CCR2004: `192.168.10.1`
- Core CRS326: `192.168.10.2`
- Access CRS328: `192.168.10.3`
- CSS610: `192.168.10.4` (Web: `http://192.168.10.4`)

Winbox/SSH chỉ cho phép từ `192.168.10.0/24` và VPN pool `10.10.10.0/24`.

## Kiến trúc Key

**Bridge VLAN Filtering**: Tất cả thiết bị RouterOS đều dùng `vlan-filtering=yes` trên bridge. CPU port (`bridge-lan`, `bridge-core`, `bridge-access`) phải được thêm vào `tagged` của VLAN 10 để management hoạt động.

**Trunk vs Access ports**:
- Trunk (tagged): `frame-types=admit-only-vlan-tagged`
- Access (untagged): `frame-types=admit-only-untagged-and-priority-tagged` + `pvid=<VLAN>`
- VLAN 70 access: ether11–16 trên CCR2004, `pvid=70`, untagged trong bridge VLAN table

**VLAN sub-interfaces trên Router**: Traffic L3 đi qua `/interface vlan` tạo trên `bridge-lan` (ví dụ `bridge-lan.20`). CPU port `bridge-lan` phải tagged trong mọi VLAN cần router xử lý.

**WireGuard VPN** (`wg-vpn`, port UDP 13231): Split tunnel — chỉ route các subnet nội bộ, internet đi thẳng. Peer `vanhau` (IP `10.10.10.2`) cần điền public key thủ công sau khi thiết bị generate keypair.

**Hairpin NAT (CCTV NVR)**: Phương án A (direct IP, `192.168.5.254:8054` / `192.168.5.253:8053`) mặc định ENABLE. Phương án B (qua WAN IP) mặc định DISABLE — có sẵn trong comment để enable khi cần.

**CCTV Firewall logic**: NVR (`.253`, `.254`) được ra internet; Camera (`192.168.5.1–100`) bị block. Rule drop camera đặt SAU rule accept NVR để tránh chặn nhầm.

**QoS**: Mangle mark trong `prerouting`, Queue Tree gắn vào `pppoe-wan`. Priority: VoIP(1) > IPTV(2) > Wifi-Mgmt(3) > Office(4) > CCTV(5) > Guest(8).

## Ràng buộc bắt buộc khi sửa config

- **RouterOS v7 syntax** — không dùng lệnh deprecated từ v6
- Không tạo DHCP server cho VLAN 10 và VLAN 70
- Firewall rule thứ tự quan trọng: established/related → invalid → specific rules → default drop
- `LOCAL_NETS` address-list phải bao gồm cả VPN pool `10.10.10.0/24`
- Mọi thay đổi firewall trên switch (CRS326/CRS328) chỉ áp dụng cho chain `input` (switch L2 không có chain `forward`)

## Thông tin nhạy cảm

File `mik.txt` và `configs/router-ccr2004.rsc` chứa PPPoE credentials thực tế. Không commit thêm credential vào repo — thay bằng placeholder khi tạo config mới.
