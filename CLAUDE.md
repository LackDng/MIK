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
┌────┴──────────────────┐
│  CRS326-24S+2Q+RM     │
│  (Core Switch – L2)   │
│  bridge priority=4096  │  ← RSTP Root Bridge
└────┬──────────┬────────┘
     │ sfp-sfpplus2  │ sfp-sfpplus3
     │ 1G SMF        │ 1G SMF
┌────┴──────┐  ┌┴──────────────────┐
│  CSS610   │  │  CRS328-24P-4S+   │
│ (SwOS-L2) │  │  (RouterOS – L2)  │
└───────────┘  └───────────────────┘

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

| Device        | IP (VLAN10)      | Gateway      |
|---------------|------------------|--------------|
| CCR2004       | 192.168.10.1/24  | —            |
| CRS326        | 192.168.10.2/24  | 192.168.10.1 |
| CRS328        | 192.168.10.3/24  | 192.168.10.1 |
| CSS610        | 192.168.10.4/24  | 192.168.10.1 |

Management access: Winbox (8291) + SSH (22) allowed from VLAN10 (192.168.10.0/24), VLAN60 (192.168.0.0/24), and VPN (10.10.10.0/24).

## CCR2004 Port Mapping

| Interface      | Role                                           |
|----------------|------------------------------------------------|
| sfp-sfpplus2   | WAN PRIMARY – PPPoE Viettel (pppoe-wan, distance=1) |
| ether1         | WAN BACKUP – PPPoE dự phòng (pppoe-backup, distance=2) |
| sfp-sfpplus1   | Trunk → Core CRS326 (S+31DLC10D 10G SMF)      |
| ether2         | VLAN10 ACCESS – Management (direct PC)         |
| ether3–ether10 | Reserved (not used)                            |
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
| CRS328  | 32768 (default) | Non-root              |
| CSS610  | N/A (SwOS)      | STP disabled          |

Setting CRS326 as Root Bridge prevents CSS610 (which had the lowest MAC address) from winning the RSTP election and causing TCN broadcast storms. Both CRS326 and CCR2004 have `igmp-snooping=yes` on their bridge to reduce multicast flooding (IPTV/camera traffic).

## WAN Failover

- PRIMARY: sfp-sfpplus2 → pppoe-wan — **Viettel (đường chính, ưu tiên)** (default-route-distance=1)
- BACKUP: ether1 → pppoe-backup — **VNPT đường dự phòng** (default-route-distance=2)
- Automatic failover: RouterOS removes distance=1 route when pppoe-wan drops, traffic switches to pppoe-backup automatically.
- Both PPPoE clients in interface list `WAN`.
- All firewall/NAT rules use `in-interface-list=WAN` / `out-interface-list=WAN` (not hardcoded to a single interface).

### WAN Monitoring Script (STEP 21)

| Component | Chi tiết |
|-----------|---------|
| Routing table | `wan-check-viettel` – route 8.8.8.8/32 qua pppoe-wan |
| Netwatch | Ping 8.8.8.8 mỗi 30s qua table Viettel, timeout 5s |
| `wan-viettel-down` | Disable pppoe-wan → VNPT backup tự động active (distance=2) |
| `wan-viettel-up` | Enable pppoe-wan → Viettel primary active lại (distance=1) |
| `wan-viettel-recovery` | Script chạy mỗi 5 phút, thử re-enable pppoe-wan khi đang failover |
| Scheduler | `viettel-recovery-check` interval=5m – trigger recovery script |

**Tại sao cần scheduler recovery**: Khi pppoe-wan bị disable, route `wan-check-viettel` biến mất → netwatch không thể tự phát hiện Viettel đã phục hồi. Scheduler định kỳ thử enable lại, sau 20s kiểm tra nếu kết nối OK thì giữ lại, nếu không thì disable tiếp.

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

Port forwarding: WAN:8054 → NVR-1, WAN:8053 → NVR-2

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

## Config Files

| File                              | Device          | System   |
|-----------------------------------|-----------------|----------|
| configs/router-ccr2004.rsc        | CCR2004         | RouterOS |
| configs/switch-core-crs326.rsc    | CRS326          | RouterOS |
| configs/switch-access-crs328.rsc  | CRS328          | RouterOS |
| configs/css610-swos.txt           | CSS610          | SwOS     |

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
7. **IGMP snooping** on CRS326 and CCR2004 bridges: Reduces multicast flooding to only ports with active IGMP listeners (important for IPTV and camera streams).
8. **QoS duplicated for both WAN interfaces**: Mangle marks and queue trees are replicated for pppoe-wan and pppoe-backup so QoS remains active during failover.
