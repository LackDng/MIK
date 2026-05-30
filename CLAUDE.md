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
└────┬──────────────────────────────┘
     │ sfp-sfpplus1
     │ S+31DLC10D (10G SMF)
     │ sfp-sfpplus1
┌────┴──────────────────┐
│  CRS326-24S+2Q+RM     │
│  (Core Switch – L2)   │
└────┬──────────┬────────┘
     │ sfp1     │ sfp2
     │ 1G SMF   │ 1G SMF
┌────┴──────┐  ┌┴──────────────────┐
│  CSS610   │  │  CRS328-24P-4S+   │
│ (SwOS-L2) │  │  (RouterOS – L2)  │
└───────────┘  └───────────────────┘

CCR2004 ether11–16 (copper) → Camera/NVR [VLAN 70 access]
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
| sfp-sfpplus2   | WAN PRIMARY – PPPoE (pppoe-wan, distance=1)    |
| ether1         | WAN BACKUP – PPPoE (pppoe-backup, distance=2)  |
| sfp-sfpplus1   | Trunk → Core CRS326 (S+31DLC10D 10G SMF)      |
| ether2         | VLAN10 ACCESS – Management (direct PC)         |
| ether3–ether10 | Reserved (not used)                            |
| ether11–ether16| VLAN70 ACCESS – Camera/NVR (pvid=70, untagged) |

## WAN Failover

- PRIMARY: sfp-sfpplus2 → pppoe-wan (default-route-distance=1)
- BACKUP: ether1 → pppoe-backup (default-route-distance=2)
- Automatic failover: RouterOS removes distance=1 route when pppoe-wan drops, traffic switches to pppoe-backup automatically.
- Both PPPoE clients in interface list `WAN`.
- All firewall/NAT rules use `in-interface-list=WAN` / `out-interface-list=WAN` (not hardcoded to a single interface).

## WireGuard VPN

- Interface: wg-vpn, UDP port 13231
- Server IP: 10.10.10.1/24
- Peer vanhau: 10.10.10.2/32, persistent-keepalive=25
- Split tunnel: routes 10.10.10.0/24, 192.168.10.0/24, 192.168.0.0/24, 192.168.5.0/24

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

## Key Design Decisions

1. **VLAN60 dual role**: Office PCs + AP WiFi management on same subnet (192.168.0.0/24). APs get DHCP from this range; office staff on same VLAN can access AP management web UI directly.
2. **VLAN60 admin access**: Full Winbox/SSH access to all RouterOS devices (same as VLAN10 management).
3. **No VLAN30**: Previously separate "Manage Wifi" VLAN merged into VLAN60 to simplify topology.
4. **Dual PPPoE failover**: No external keepalive scripts needed — RouterOS native routing distance handles automatic failover.
5. **Hairpin NAT Option A** (enabled by default): Internal hosts access NVR via direct LAN IP, no WAN IP loop. Option B (hairpin via WAN IP) is in config as commented-out disabled rules.
