# MikroTik Network Configuration – Project Reference

## Overview

Enterprise network built on MikroTik hardware (RouterOS v7 + SwOS).
4 devices: 1 router + 2 managed switches (RouterOS) + 1 access switch (SwOS).

## Network Topology

```
Internet (ISP)
     │
[Modem ISP – PRIMARY]        [Modem ISP – BACKUP]
     │ sfp-sfpplus2 (PPPoE)       │ ether1 (PPPoE)
┌────┴──────────────────────────────┤
│  CCR2004-16G-2S+                  │
│  (Router – Layer 3)               │
│  bridge priority=8192             │
└────┬──────────────────────────────┘
     │ sfp-sfpplus1
     │ S+31DLC10D (10G SMF)
     │ sfp-sfpplus1
┌────┴──────────────────────────────┐
│  CRS326-24S+2Q+RM  "CORE"         │
│  (Core Switch – L2) 192.168.10.2  │
│  bridge priority=4096             │  ← RSTP Root Bridge
└─┬──────┬──────┬──────┬────────────┘
  │ sfp2 │ sfp5 │ sfp7 │ sfp14 … (+ các cổng khác chưa map)
  │      │      │      │
┌─┴────┐ ┌┴────┐ ┌┴────┐ ┌┴──────────────┐
│IT-ROOM│ │NHA LA│ │APART│ │ Villa 11-12   │
│ .10.3 │ │.10.4 │ │.10.5│ │ CSS610 .10.8  │
└───────┘ └──────┘ └─────┘ └───────────────┘
  CRS328    CRS328   CRS328

+ 9 CSS610 khác (Vila 1-2/3-4/5-6/7-8/9-10, Bungalow 7-8/9-10/
  11-12/13-14) – IP .10.6–.15, cổng CORE chưa map đầy đủ.
  Tổng: 10× CSS610-8P-2S+ phục vụ các khu villa/bungalow.

CCR2004 ether11–14 (copper) → Camera/NVR [VLAN 70 access]
CCR2004 ether15     → NVR-1 (single device, no loop)
CCR2004 ether16     → Camera switch (NVR + cameras only, no uplink to CRS326)
```

## VLAN Plan

| VLAN | Name                      | Gateway/Prefix  | DHCP Pool                      | DHCP |
|------|---------------------------|-----------------|--------------------------------|------|
|  10  | Management                | 192.168.10.1/24 | Static only                    |  No  |
|  20  | Wifi Guest                | 172.16.20.1/22  | 172.16.20.100–172.16.23.200    |  Yes |
|  40  | IPTV Cloud                | 172.16.40.1/24  | 172.16.40.100–172.16.40.200    |  Yes |
|  50  | IP Phone                  | 172.16.50.1/24  | 172.16.50.100–172.16.50.200    |  Yes |
|  60  | Office + AP WiFi Management | 192.168.0.1/24 | 192.168.0.100–192.168.0.200  |  Yes |
|  70  | CCTV                      | 192.168.5.1/24  | Static only                    |  No  |

**VLAN 30 removed** – previously "Manage Wifi" (172.16.30.0/24), merged into VLAN 60.

## Device Management IPs

Hệ thống thực tế có **15 thiết bị** (không phải 4): 1 router + 1 core + 3 CRS328 + **10 CSS610**.

| IP | Identity | Model | Firmware |
|----|----------|-------|----------|
| 192.168.10.1 | ROUTER | CCR2004-16G-2S+ | ROS 7.23.3 |
| 192.168.10.2 | CORE | CRS326-24S+2Q+ | ROS 7.23.3 |
| 192.168.10.3 | IT-ROOM | CRS328-24P-4S+ | ROS 7.23.3 |
| 192.168.10.4 | NHA LA | CRS328-24P-4S+ | ROS 7.23.3 |
| 192.168.10.5 | APART | CRS328-24P-4S+ | ROS 7.23.3 |
| 192.168.10.6 | Vila 5-6 | CSS610-8P-2S+ | SwOS 2.18 |
| 192.168.10.7 | Vila 7-8 | CSS610-8P-2S+ | SwOS 2.21 |
| 192.168.10.8 | Villa 11-12 | CSS610-8P-2S+ | SwOS 2.18 |
| 192.168.10.9 | Vila 9-10 | CSS610-8P-2S+ | SwOS 2.21 |
| 192.168.10.10 | Vila 3-4 | CSS610-8P-2S+ | SwOS 2.18 |
| 192.168.10.11 | Bungalow 7-8 | CSS610-8P-2S+ | SwOS 2.18 |
| 192.168.10.12 | Bungalow 9-10 | CSS610-8P-2S+ | SwOS 2.18 |
| 192.168.10.13 | Bungalow 11-12 | CSS610-8P-2S+ | SwOS 2.21 |
| 192.168.10.14 | Bungalow 13-14 | CSS610-8P-2S+ | SwOS 2.21 |
| 192.168.10.15 | Vila 1-2 | CSS610-8P-2S+ | SwOS 2.18 |

**Dải .1–.15 ĐÃ DÙNG HẾT. Thiết bị mới bắt đầu từ 192.168.10.16.**

⚠️ **Firmware SwOS không đồng nhất**: 6 máy chạy 2.18, 4 máy chạy 2.21. Nên nâng toàn bộ lên 2.21 để hành vi VLAN/IGMP giống nhau, tránh lỗi khó chẩn đoán.

**Vì sao CSS610 không hiện trong `/ip neighbor print` trên CORE**: SwOS mặc định tắt MNDP discovery, hoặc `discover-interface-list` trên CORE giới hạn. Thấy được qua tab Neighbors của Winbox (dùng broadcast từ PC). Không phải lỗi.

Management access: Winbox (8291) + SSH (22) allowed from VLAN10 (192.168.10.0/24), VLAN60 (192.168.0.0/24), and VPN (10.10.10.0/24).

## CCR2004 Port Mapping

| Interface      | Role                                           |
|----------------|------------------------------------------------|
| sfp-sfpplus2   | WAN PRIMARY – PPPoE Viettel (pppoe-wan, distance=1) |
| ether1         | WAN BACKUP – PPPoE dự phòng (pppoe-backup, distance=2) |
| sfp-sfpplus1   | Trunk → Core CRS326 (S+31DLC10D 10G SMF)      |
| ether2         | VLAN10 ACCESS – Management (direct PC)         |
| ether3–ether9  | Reserved (not used)                            |
| ether10        | VLAN60 ACCESS – Office (pvid=60, đang dùng thực tế) |
| ether11–ether16| VLAN70 ACCESS – Camera/NVR (pvid=70, untagged) |

**Note on ether15/16**: ether15 connects to a single NVR (no downstream switch). ether16 connects to a dedicated camera switch that does NOT uplink back to CRS326. No physical loop exists on these ports.

## CRS326 Port Mapping

| Interface          | Role                                              |
|--------------------|---------------------------------------------------|
| sfp-sfpplus1       | Uplink → CCR2004 (S+31DLC10D 10G SMF)            |
| sfp-sfpplus2       | Downlink → CSS610 (S-31DLC20D 1G SMF)            |
| sfp-sfpplus3       | Downlink → CRS328 (S-31DLC20D 1G SMF)            |
| sfp-sfpplus4–13    | In use – trunk all VLANs                          |
| sfp-sfpplus14–24   | Reserved (not configured)                         |

All 13 active ports (sfp-sfpplus1–13) are trunk ports (admit-only-vlan-tagged), carrying all 6 VLANs.

## STP / RSTP Bridge Priority

| Device  | Bridge Priority | Role                  |
|---------|-----------------|-----------------------|
| CRS326  | 4096            | RSTP Root Bridge      |
| CCR2004 | 8192            | Secondary Root        |
| CRS328 ×3 | 32768 (default) | Non-root            |
| CSS610  | N/A (SwOS)      | RSTP bật được sau khi CORE=4096 |

Setting CRS326 as Root Bridge prevents the access switches from winning the RSTP election and causing TCN broadcast storms.

**Đính chính chẩn đoán cũ (dựa trên backup 04/08/2026)**: MAC `04:F4:1C:D2:1D:E2` từng bị quy cho CSS610 thực ra là `sfp-sfpplus1` của **IT-ROOM (CRS328)**. Dải MAC thực tế:

| Thiết bị | MAC thấp nhất |
|----------|---------------|
| IT-ROOM (CRS328) | `04:f4:1c:d2:1d:ca` ← thấp nhất toàn hệ thống |
| NHA LA (CRS328)  | `04:f4:1c:d2:80:9d` |
| APART (CRS328)   | `04:f4:1c:d2:8a:0a` |
| CCR2004 Router   | `d0:ea:11:1d:db:7f` |
| CORE (CRS326)    | `d0:ea:11:72:28:b6` ← cao nhất |

Cả 3 CRS328 (`04:f4:…`) đều có MAC thấp hơn CORE (`d0:ea:…`), nên khi mọi bridge để priority mặc định 32768 thì **IT-ROOM** mới là Root Bridge, không phải CSS610. Cách khắc phục không đổi: đặt CORE priority=4096 để thắng bầu cử bất kể MAC. IGMP snooping is enabled on ALL devices — `igmp-snooping=yes` on CCR2004/CRS326/CRS328 bridges, IGMP Snooping checkbox in CSS610 SwOS System tab — to reduce multicast flooding (IPTV/camera traffic).

## WAN Failover

- PRIMARY: sfp-sfpplus2 → pppoe-wan — **Viettel (đường chính, ưu tiên)** (default-route-distance=1)
- BACKUP: ether1 → pppoe-backup — **VNPT đường dự phòng** (default-route-distance=2)
- Automatic failover: RouterOS removes distance=1 route when pppoe-wan drops, traffic switches to pppoe-backup automatically.
- Both PPPoE clients in interface list `WAN`.
- All firewall/NAT rules use `in-interface-list=WAN` / `out-interface-list=WAN` (not hardcoded to a single interface).

### WAN Monitoring Script (STEP 21)

Cơ chế "pinned route + blackhole" trong bảng main (tương thích mọi bản ROS v7 — netwatch không cần tham số `routing-table`):

| Component | Chi tiết |
|-----------|---------|
| Pinned route | 8.8.4.4/32 gateway=pppoe-wan scope=10 – chỉ active khi Viettel UP |
| Blackhole route | 8.8.4.4/32 **blackhole** distance=254 – chặn false-UP qua VNPT khi Viettel down |
| Netwatch | Ping 8.8.4.4 mỗi 30s, timeout 5s |
| `wan-viettel-down` | Disable pppoe-wan → VNPT backup tự động active (distance=2) |
| `wan-viettel-up` | Log xác nhận Viettel primary active lại (distance=1) |
| `wan-viettel-recovery` | Script chạy mỗi 5 phút, thử re-enable pppoe-wan khi đang failover |
| Scheduler | `viettel-recovery-check` interval=5m – trigger recovery script |

**Host check là 8.8.4.4, KHÔNG dùng 8.8.8.8** — 8.8.8.8 là DNS server chính; nếu blackhole nó thì DNS bị chặn khi failover.

**Tại sao cần scheduler recovery**: Khi pppoe-wan bị disable, route ghim biến mất, blackhole chặn ping → netwatch không thể tự phát hiện Viettel đã phục hồi. Scheduler định kỳ thử enable lại, sau 20s kiểm tra nếu kết nối OK thì giữ lại, nếu không thì disable tiếp.

**Lưu ý import**: script `source=` phải viết 1 dòng với `\n` và `\$` escape — khối `source={` nhiều dòng sẽ làm `/import` báo syntax error (chỉ paste được vào Terminal).

**Cú pháp blackhole ROS v7** (đã test trên CCR2004 thật): `blackhole` là **flag đứng một mình**.

| Cú pháp | Kết quả |
|---------|---------|
| `type=blackhole` | ❌ `bad parameter type` (cú pháp v6) |
| `blackhole=yes` | ❌ `expected end of command` |
| `blackhole` | ✅ Đúng |

## WireGuard VPN

- Interface: wg-vpn, UDP port 13231
- Server IP: 10.10.10.1/24
- Peer vanhau: 10.10.10.2/32, persistent-keepalive=25
- Split tunnel: routes 10.10.10.0/24, 192.168.10.0/24, 192.168.0.0/24, 192.168.5.0/24
- **Note**: WireGuard peer public key must be set manually (`/interface wireguard peers set 0 public-key="<KEY>"`). The peer add command in router-ccr2004.rsc has the public-key commented out to avoid import failure.

## WiFi / AP (Unifi)

- AP brand: Unifi (U7 LR and similar)
- AP management VLAN: **VLAN 60** (192.168.0.0/24) — controller and APs on same L2 segment, no inter-VLAN routing needed for management
- Guest WiFi SSID → VLAN 20 (tagged)
- Office WiFi SSID → VLAN 60

### ⚠️ VLAN60 tới AP là TAGGED, không phải native

Xác nhận thực tế 04/08/2026: cổng AP trên CSS610 chạy tốt với `VLAN Receive = only tagged`; đổi sang `any` thì **AP mất kết nối ngay**. Nguyên nhân: switch bắt đầu gửi VLAN60 untagged, AP chờ tag 60 nên bỏ gói → chiều về đứt.

Lý do: Unifi **gắn tag cho mọi Network có điền VLAN ID**; chỉ mạng quản trị mặc định mới đi untagged.

| Cấu hình Unifi | Cổng switch phải là |
|---|---|
| Network Office **có** VLAN ID 60 ← *hệ thống này* | Trunk thuần: VLAN 60 + 20 đều **tagged** |
| Network Office **không** có VLAN ID | VLAN 60 untagged (pvid=60) + VLAN 20 tagged |

Chọn sai: AP vẫn "lên" nhưng SSID Office không có mạng hoặc AP không lấy được IP. Chi tiết 2 kịch bản trong `configs/tools/ap-trunk-port.rsc`.

**Cần kiểm tra lại IT-ROOM `ether1`**: đang cấu hình theo kiểu native (pvid=60 → entry `added by pvid`). Nếu AP ở đó cũng là Unifi cùng kiểu thì phải chuyển VLAN60 sang tagged.
- Recommended channel widths: 40 MHz for 2.4 GHz, 80 MHz for 5 GHz

## CCTV (VLAN 70)

| Device | IP             | Web Port | Internet |
|--------|----------------|----------|----------|
| NVR-1  | 192.168.5.254  | 8054     | Allowed  |
| NVR-2  | 192.168.5.253  | 8053     | Allowed  |
| Camera | 192.168.5.1–100| —        | BLOCKED  |

Port forwarding (chỉ qua **Viettel** – `in-interface=pppoe-wan`, không dùng interface-list WAN):

| Port | Đích | Ghi chú |
|------|------|---------|
| 8054 | NVR-1 192.168.5.254 | |
| 8053 | NVR-2 192.168.5.253 | |
| 1433 | SQL 192.168.0.254 | ⚠️ Rủi ro bảo mật – nên chuyển sang truy cập qua VPN |

**Khi failover sang VNPT, port forwarding ngừng hoạt động** (thiết kế có chủ đích — IP public chỉ ổn định trên Viettel). Truy cập nội bộ và qua WireGuard VPN vẫn bình thường.

## QoS Priority

Queue tree on pppoe-wan (PRIMARY) and pppoe-backup (BACKUP):

| Queue  | Priority | limit-at | max-limit |
|--------|----------|----------|-----------|
| voip   |    1     |   2M     |  1000M    |
| iptv   |    2     |  50M     |  1000M    |
| office |    4     | 100M     |  1000M    |
| cctv   |    5     |  20M     |   100M    |
| guest  |    8     |   5M     |    50M    |

Guest simple queue: 50M/50M hard cap.

## Live Device Fleet (từ backup 04/08/2026)

Hệ thống thực tế có **3 switch CRS328** (không phải 1 như thiết kế ban đầu):

RouterOS đồng nhất **7.23.3 (stable)** trên cả 5 thiết bị RouterOS.

| Identity | Model | IP | Cổng CORE | Việc cần làm |
|----------|-------|-----|-----------|--------------|
| ROUTER  | CCR2004 | .10.1 | — (uplink sfp1) | Còn VLAN30, thiếu VLAN60 mgmt, thiếu QoS backup |
| CORE    | CRS326  | .10.2 | — | Chưa set priority=4096, thiếu VLAN60 |
| IT-ROOM | CRS328  | .10.3 | **sfp-sfpplus2** ✅ | Còn user `admin` mặc định |
| NHA LA  | CRS328  | .10.4 | sfp-sfpplus5 ✅ | Firewall cũ, thiếu VLAN60 |
| APART   | CRS328  | .10.5 | sfp-sfpplus7 ✅ | Firewall cũ, thiếu VLAN60, rule trùng |
| 10× CSS610 | CSS610-8P-2S+ | .10.6–.15 | chưa map hết | Firmware lệch 2.18/2.21 |

IT-ROOM đã xác nhận đấu trực tiếp `sfp-sfpplus2` (link-ok 1Gbps, module WINTOP WT-9110G/SM/20/L; bridge host thấy MAC `04:F4:1C:D2:1D:E2` VID 10 trên cổng này). Nghi vấn link DOWN trước đó là **không đúng** — nó chỉ không trả lời MNDP trên cổng vật lý.

`sfp-sfpplus14` nhãn "To 11-12" ứng với CSS610 **Villa 11-12** (192.168.10.8).

### CORE – bản đồ 14 cổng trunk (ĐẦY ĐỦ)

Xác minh 04/08/2026 bằng `/interface bridge host print where vid=10` — đối chiếu MAC thật, **không dựa vào comment cũ trên thiết bị** (comment cũ sai nhiều chỗ).

| Cổng | IP | Thiết bị | MAC |
|------|-----|----------|-----|
| sfp-sfpplus1 | .10.1 | ROUTER CCR2004 | D0:EA:11:1D:DB:90 |
| sfp-sfpplus2 | .10.3 | CRS328 IT-ROOM | 04:F4:1C:D2:1D:E2 |
| sfp-sfpplus3 | .10.12 | Bungalow 9-10 | F4:1E:57:C2:CC:9A |
| sfp-sfpplus4 | .10.6 | Vila 5-6 | F4:1E:57:C1:F7:7F |
| sfp-sfpplus5 | .10.4 | CRS328 NHA LA | 04:F4:1C:D2:80:B5 |
| sfp-sfpplus6 | .10.8 | **Villa 11-12** | F4:1E:57:C1:EF:40 |
| sfp-sfpplus7 | .10.5 | CRS328 APART | 04:F4:1C:D2:8A:22 |
| sfp-sfpplus8 | .10.9 | Vila 9-10 | F4:1E:57:C1:F7:0E |
| sfp-sfpplus9 | .10.11 | Bungalow 7-8 | F4:1E:57:C5:6C:75 |
| sfp-sfpplus10 | .10.10 | Vila 3-4 | F4:1E:57:C1:F7:F4 |
| sfp-sfpplus11 | .10.15 | Vila 1-2 | F4:1E:57:C5:6A:27 |
| sfp-sfpplus12 | .10.7 | Vila 7-8 | F4:1E:57:C1:F8:00 |
| sfp-sfpplus13 | .10.14 | Bungalow 13-14 | F4:1E:57:C4:A6:17 |
| sfp-sfpplus14 | .10.13 | **Bungalow 11-12** | F4:1E:57:C5:6A:3A |

⚠️ **Bẫy đặt tên**: comment cũ ghi sfp-sfpplus14 = "To 11-12" → dễ hiểu nhầm là Villa 11-12. Thực tế **sfp14 = Bungalow 11-12** (.10.13), còn **Villa 11-12** (.10.8) ở **sfp6**. Hai khu tên gần giống, rút nhầm dây là mất mạng nhầm khu.

Bảng VLAN đã xác nhận có đủ `sfp-sfpplus14` → Bungalow 11-12 hoạt động bình thường.

**MAC `A4:4C:C8:10:AE:8A` trên sfp-sfpplus1** = PC quản trị của admin (192.168.10.50), nằm sau router trên VLAN10. Đã xác nhận — không phải thiết bị lạ, không cần điều tra lại.

### CRS328 – bản đồ cổng access (đang cập nhật dần)

⚠️ File `switch-access-crs328.rsc` **chưa khai báo cổng access nào** (chỉ có uplink `sfp-sfpplus1`). Mỗi CRS328 có bố trí cổng khác nhau. Reset + reimport sẽ mất toàn bộ cấu hình access port → phải bổ sung trước khi dùng file để phục hồi.

**IT-ROOM (192.168.10.3)** – xác nhận 04/08/2026:

| Cổng | VLAN | Vai trò |
|------|------|---------|
| sfp-sfpplus1 | trunk all | Uplink → CORE sfp-sfpplus2 |
| ether1 | 60 native + 20 tagged | **AP WiFi** (Office + Guest) |
| ether2, ether4 | 60 untagged | Office PC |
| ether9 | 50 untagged | IP Phone |
| ether23, ether24 | 70 untagged | Camera/CCTV |

**NHA LA (.10.4) / APART (.10.5)**: chưa map. Lấy bằng `/interface bridge vlan print` trên từng máy (xem các dòng `;;; added by pvid`).

### ⚠️ VLAN 30 VẪN CÒN TRÊN CORE

`/interface bridge vlan print` cho thấy CORE vẫn có `vlan-ids=30` trên toàn bộ 14 cổng. Router cũng còn VLAN30. Trình tự gỡ an toàn:

1. Chuyển hết AP management sang VLAN60 (Unifi controller)
2. Gỡ trên ROUTER (mục 4 `delta-router-ccr2004.rsc`)
3. Gỡ trên CORE: `/interface bridge vlan remove [find bridge=bridge-core vlan-ids=30]`
4. Kiểm tra từng CRS328: `/interface bridge vlan print` → gỡ nếu còn

Gỡ sai thứ tự sẽ cắt mạng thiết bị đang dùng VLAN30.

Admin user chung: `Theindochine`. File delta để đồng bộ từng thiết bị: `configs/delta/delta-*.rsc` (paste Terminal, không import).

## ⚠️ Audit cấu hình thực tế (export 06/08/2026) – các sai lệch so với thiết kế

Đối chiếu file `/export` thật của ROUTER, CORE, IT-ROOM, NHA LA, APART với file thiết kế trong repo.

### Router – nghiêm trọng nhất: FORWARD chain đang mở hoàn toàn
Toàn bộ rule DROP trong chain FORWARD (kể cả `R24 Default deny FORWARD`) đang bị `disabled=yes`. RouterOS mặc định ACCEPT khi không rule nào khớp → **camera CCTV đang ra được internet** (R20 tắt), **không còn cách ly VLAN nào được thực thi**. Chi tiết + lệnh khắc phục theo đúng thứ tự phụ thuộc: `configs/delta/delta-router-firewall-audit.rsc`.

### Router – 3 lệch khác so với file thiết kế
1. `bridge-lan` chưa có `priority=8192 igmp-snooping=yes` (mục 1 của `delta-router-ccr2004.rsc` có vẻ chưa chạy) — CORE vẫn thắng root election (priority=4096 < default 32768) nên KHÔNG ảnh hưởng ai là root hiện tại, nhưng mất vai trò Secondary Root khi CORE down.
2. Interface list `WAN` chỉ có `pppoe-wan`, thiếu `pppoe-backup`.
3. R13–R19 (input) và R2a–R2c (forward) đang hardcode `in-interface=pppoe-wan` thay vì `in-interface-list=WAN` → **WireGuard VPN sẽ mất hoàn toàn khi failover sang VNPT** (R13 không match traffic đến qua pppoe-backup). Đây là vấn đề chức năng thật, không chỉ lý thuyết.

Có 1 rule ẩn không tên `accept chain=forward src-address=10.10.10.0/24` nằm trước R1 — vô hiệu hóa toàn bộ R5-R9 (VPN chi tiết) và cấp VPN client full internet + full LAN, không đúng thiết kế split-tunnel. Nên xóa (đã đưa vào delta).

### CORE / NHA LA / APART – hardening chưa áp dụng đồng bộ
- `discover-interface-list` trên CORE, NHA LA, APART vẫn là `!dynamic` (giá trị mặc định factory) thay vì `MGMT` như thiết kế — chỉ IT-ROOM và Router đã đúng.
- `/tool mac-server allowed-interface-list` trên CORE/NHA LA/APART là `none` (chặt hơn thiết kế `MGMT`) — có thể là chủ đích, nhưng sẽ mất khả năng cứu hộ MAC-Winbox qua VLAN10 nếu mất IP.
- **CORE**: mục 6 của `delta-switch-core.rsc` (sửa comment 14 cổng cho đúng thực tế) **chưa chạy** — bridge port vẫn ghi "Downlink to CSS610" trên sfp2 (thực tế là IT-ROOM) và "Reserved trunk" trên các cổng đang chạy thật. Riêng comment tầng ethernet (`/interface ethernet`) đã được cập nhật đúng.
- **NHA LA**: vẫn còn `vlan-ids=30` trong bridge vlan table — là thiết bị DUY NHẤT còn sót VLAN30 (Router/CORE/IT-ROOM/APART đã sạch).

### IT-ROOM / NHA LA – nghi vấn cổng AP dùng sai kịch bản VLAN60
Test thực tế trên CSS610 đã xác nhận hệ thống dùng **Kịch bản A** (VLAN60 tagged tới AP, xem mục WiFi/AP bên trên). Nhưng cấu hình hiện tại:
- **IT-ROOM**: `ether1, ether2, ether3, ether4` đều đang cấu hình theo **Kịch bản B** (`pvid=60`, VLAN60 không có trong danh sách tagged) — tăng từ 1 lên 4 cổng AP so với lần audit trước.
- **NHA LA**: `ether1, ether2, ether3, ether5` cùng pattern.

Nếu các AP này cũng là Unifi cùng Network "Office" có VLAN ID = 60 (đã xác nhận đúng cho hệ thống này), **các AP đó nhiều khả năng không nhận được VLAN60** — biểu hiện: AP không được adopt bởi controller (vì quản trị AP cũng đi qua VLAN60), không chỉ riêng SSID Office bị lỗi. Cần kiểm tra trên Unifi Controller xem các AP này có đang online không, trước khi áp dụng fix (đổi VLAN60 sang tagged, xem `configs/tools/ap-trunk-port.rsc` Kịch bản A) — không tự ý sửa vì có thể AP đang hoạt động bình thường và giả định này sai.

IT-ROOM `ether5` có comment `"CCTV  OFFICE 60 - ACC"` — nhiều khả năng là port Office bị dán nhầm comment còn sót chữ "CCTV" từ lần copy-paste trước, không phải port camera thật (frame-types/pvid khớp mẫu Office, không phải mẫu CCTV pvid=70).

### Lưu ý khi paste lệnh vào Winbox Terminal

| Vấn đề | Cách xử lý |
|--------|-----------|
| Comment gốc chứa dấu gạch dài `–` không paste được → `find comment="..."` trả rỗng → `no such item` | Dùng `find comment~"chuỗi con"` (toán tử `~`) thay cho `=` |
| Nối dòng bằng `\` hay bị đứt, dòng sau chạy riêng thành lệnh lỗi | Viết lệnh trên **1 dòng duy nhất** |
| `[find a="x" and b=y]` | RouterOS dùng khoảng trắng làm AND: `[find a="x" b=y]` |
| Nối danh sách kiểu `tagged=([get ... tagged],ether1)` → `invalid internal item number` | `get` trả về internal ID (`*8`) không phải tên cổng. Phải `print detail` xem tên, rồi gõ lại đầy đủ danh sách |

**Bridge VLAN – untagged tự động**: đặt `pvid=X` trên bridge port sẽ tự sinh entry động (`;;; added by pvid`) cho untagged. Chỉ **tagged** mới phải thêm tay vào bảng VLAN.

## Config Files

| File                              | Device          | System   |
|-----------------------------------|-----------------|----------|
| configs/router-ccr2004.rsc        | CCR2004         | RouterOS |
| configs/switch-core-crs326.rsc    | CRS326 (CORE)   | RouterOS |
| configs/switch-access-crs328.rsc  | CRS328 (template cho IT-ROOM / NHA LA / APART) | RouterOS |
| configs/css610-swos.txt           | CSS610          | SwOS     |
| configs/delta/delta-*.rsc         | Delta commands đồng bộ thiết bị đang chạy | RouterOS Terminal |

**Security note**: `configs/router-ccr2004.rsc` and `mik.txt` contain real PPPoE credentials. Do NOT commit additional credentials — use placeholders in any new config.

## Git Branch

Active development branch: `claude/config-file-setup-E6YE9`

## Key Design Decisions

1. **VLAN60 dual role**: Office PCs + AP WiFi management on same subnet (192.168.0.0/24). APs get DHCP from this range; office staff on same VLAN can access AP management web UI directly.
2. **VLAN60 admin access**: Full Winbox/SSH access to all RouterOS devices (same as VLAN10 management).
3. **No VLAN30**: Previously separate "Manage Wifi" VLAN merged into VLAN60 to simplify topology.
4. **Dual PPPoE failover**: No external keepalive scripts needed — RouterOS native routing distance handles automatic failover.
5. **Hairpin NAT Option A + B** (both enabled): Option A = access NVR via direct LAN IP (192.168.5.254:8054). Option B = access NVR via public IP (e.g. 117.2.11.52:8054) from inside LAN — DSTNAT intercepts LOCAL_NETS→port 8054/8053 and redirects to NVR LAN IP; SRCNAT masquerades so NVR replies via router. No hardcoded public IP (dynamic PPPoE safe).
6. **CRS326 as RSTP Root Bridge** (priority=4096): Prevents CSS610 (lowest MAC) from winning root election and causing TCN broadcast storms on every link-state change.
7. **IGMP snooping on all 4 devices** (CCR2004, CRS326, CRS328 bridges + CSS610 SwOS checkbox): Reduces multicast flooding to only ports with active IGMP listeners (important for IPTV and camera streams).
8. **QoS duplicated for both WAN interfaces**: Mangle marks and queue trees are replicated for pppoe-wan and pppoe-backup so QoS remains active during failover.
