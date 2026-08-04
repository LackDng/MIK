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
└──┬────────┬────────┬──────────┬───┘
   │ sfp2   │ sfp5   │ sfp7     │ sfp14
   │ (?)    │ 1G SMF │ 1G SMF   │ "To 11-12" (?)
┌──┴─────┐ ┌┴──────┐ ┌┴───────┐
│IT-ROOM │ │NHA LA │ │ APART  │   ← 3× CRS328-24P-4S+
│  .10.3 │ │ .10.4 │ │ .10.5  │
└────────┘ └───────┘ └────────┘

(?) = chưa xác nhận. `/ip neighbor print` trên CORE chỉ thấy NHA LA
      (sfp5) và APART (sfp7) là láng giềng vật lý trực tiếp.
      IT-ROOM chỉ hiện qua vlan10-mgmt (L3) → link sfp2 có thể đang DOWN
      hoặc IT-ROOM đấu nối qua đường khác. Xem mục "Việc cần xác minh".

CSS610 (SwOS): KHÔNG xuất hiện trong neighbor list → chưa triển khai
               hoặc chưa cắm điện/uplink.

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

Xác nhận bằng `/ip neighbor print` trên CORE (04/08/2026):

| Device  | Identity | IP (VLAN10)      | Gateway      |
|---------|----------|------------------|--------------|
| CCR2004 | ROUTER   | 192.168.10.1/24  | —            |
| CRS326  | CORE     | 192.168.10.2/24  | 192.168.10.1 |
| CRS328  | IT-ROOM  | 192.168.10.3/24  | 192.168.10.1 |
| CRS328  | NHA LA   | 192.168.10.4/24  | 192.168.10.1 |
| CRS328  | APART    | 192.168.10.5/24  | 192.168.10.1 |
| CSS610  | (chưa triển khai) | 192.168.10.6/24 – **đề xuất** | 192.168.10.1 |

⚠️ **XUNG ĐỘT IP đã tránh được**: tài liệu cũ ghi CSS610 = 192.168.10.4, nhưng IP đó **đang được NHA LA sử dụng**. Nếu triển khai CSS610 với .4 sẽ gây xung đột IP làm mất quản trị NHA LA. Đã đổi đề xuất sang **192.168.10.6**.

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
- Guest WiFi SSID → VLAN 20 (tagged on trunk ports to APs)
- Office WiFi SSID → VLAN 60 (untagged/native on access port to AP)
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

Tất cả đang chạy RouterOS **7.23.3 (stable)** – đồng nhất phiên bản.

| Identity | Model   | IP        | Kết nối từ CORE | Ghi chú |
|----------|---------|-----------|-----------------|---------|
| ROUTER   | CCR2004-16G-2S+ | .10.1 | — (uplink sfp1) | Còn VLAN30, thiếu VLAN60 mgmt, thiếu QoS backup |
| CORE     | CRS326-24S+2Q+ | .10.2 | — | Chưa set priority=4096, thiếu VLAN60 |
| IT-ROOM  | CRS328-24P-4S+ | .10.3 | **chỉ thấy qua L3** ⚠️ | Còn user `admin` mặc định |
| NHA LA   | CRS328-24P-4S+ | .10.4 | sfp-sfpplus5 ✅ | Firewall cũ, thiếu VLAN60 |
| APART    | CRS328-24P-4S+ | .10.5 | sfp-sfpplus7 ✅ | Firewall cũ, thiếu VLAN60, rule trùng |
| CSS610   | CSS610-8P-2S+ | (chưa có) | **không thấy** ⚠️ | Chưa triển khai |

### Việc cần xác minh

1. **IT-ROOM không hiện là láng giềng vật lý của CORE.** NHA LA/APART xuất hiện cả trên cổng sfp lẫn vlan10-mgmt; IT-ROOM chỉ hiện trên vlan10-mgmt. Nghi vấn: link `sfp-sfpplus2` (nhãn "To IT room") đang DOWN, hoặc IT-ROOM đấu qua đường khác. Kiểm tra trên CORE:
   ```
   /interface ethernet monitor sfp-sfpplus2 once
   /interface bridge host print where mac-address=04:F4:1C:D2:1D:E2
   ```
   Lệnh thứ 2 cho biết IT-ROOM thực sự nằm sau cổng nào.

2. **CSS610 chưa xuất hiện trong mạng.** Nếu định triển khai: dùng IP `192.168.10.6` (KHÔNG dùng .4 – NHA LA đang giữ).

3. **sfp-sfpplus14 nhãn "To 11-12"** – chưa rõ thiết bị, không thấy neighbor.

Admin user chung: `Theindochine`. File delta để đồng bộ từng thiết bị: `configs/delta/delta-*.rsc` (paste Terminal, không import).

### Lưu ý khi paste lệnh vào Winbox Terminal

| Vấn đề | Cách xử lý |
|--------|-----------|
| Comment gốc chứa dấu gạch dài `–` không paste được → `find comment="..."` trả rỗng → `no such item` | Dùng `find comment~"chuỗi con"` (toán tử `~`) thay cho `=` |
| Nối dòng bằng `\` hay bị đứt, dòng sau chạy riêng thành lệnh lỗi | Viết lệnh trên **1 dòng duy nhất** |
| `[find a="x" and b=y]` | RouterOS dùng khoảng trắng làm AND: `[find a="x" b=y]` |

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
