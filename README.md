# 🎬 Plex-Automation-Stack

A production-ready, fully automated Plex Media Server setup with VPN split tunneling, Docker containerization, and advanced networking on MikroTik RouterOS.

[![License: MIT](https://img.shields.io/badge/License-MIT-yellow.svg)](https://opensource.org/licenses/MIT)
[![Docker](https://img.shields.io/badge/Docker-Ready-blue.svg)](https://www.docker.com/)
[![MikroTik](https://img.shields.io/badge/MikroTik-RouterOS-red.svg)](https://mikrotik.com/)
[![Plex](https://img.shields.io/badge/Plex-Media%20Server-orange.svg)](https://www.plex.tv/)

---

## 📋 Table of Contents

- [Overview](#-overview)
- [Architecture](#-architecture)
- [Features](#-features)
- [Tech Stack](#-tech-stack)
- [Prerequisites](#-prerequisites)
- [Quick Start](#-quick-start)
- [Network Configuration](#-network-configuration)
- [Services](#-services)
- [Security](#-security)
- [Monitoring](#-monitoring)
- [Troubleshooting](#-troubleshooting)
- [Contributing](#-contributing)
- [License](#-license)

---

## 🎯 Overview

This project provides a complete, production-grade home media server infrastructure built on:
- **Plex Media Server** for streaming
- **Sonarr/Radarr** for automated TV show and movie management
- **qBittorrent** for downloading (protected by VPN)
- **Overseerr** for user-friendly content requests
- **MikroTik RouterOS** for advanced networking and VPN split tunneling

**Key Achievement:** Plex streams externally while torrent traffic is fully protected by VPN, all while maintaining optimal performance.

---

## 🏗️ Architecture

### Network Topology

```
Internet (ISP)
    ↓
MikroTik Router 
    ├─ VPN: NordVPN WireGuard
    ├─ VPN Split Tunnel: Plex bypasses VPN
    ├─ VLAN: 192.168.xx.x/xx
    └─ Firewall: NAT, Filter, Mangle rules
        ↓
Proxmox VE Hypervisor
    └─ Ubuntu Server 24.04 LTS VM
        └─ Docker Stack (192.168.xx.x)
            ├─ Plex Media Server :32400
            ├─ Sonarr :8989
            ├─ Radarr :7878
            ├─ Bazarr :6767
            ├─ qBittorrent :8080
            ├─ Prowlarr :9696
            ├─ Overseerr :5055
            └─ Tautulli :8181
```

### Traffic Flow

**Plex Traffic (Direct, No VPN):**
```
User → ISP Router:32400 → MikroTik (DSTNAT) → Ubuntu:32400 → Plex
                                    ↓
                            Split Tunnel (Mangle)
                                    ↓
                            Direct to Internet (Main routing table)
```

**Torrent Traffic (Through VPN):**
```
qBittorrent → MikroTik (Mangle mark-routing) → VPN Routing Table → NordVPN → Internet
```

---

##  Features

### 🎬 Media Management
- **Automated Downloads**: Sonarr/Radarr monitor and download content automatically
- **Quality Profiles**: Configurable quality preferences (1080p, 4K, etc.)
- **Subtitle Management**: Bazarr for automatic subtitle downloads
- **User Requests**: Overseerr provides Netflix-like interface for content requests

### ⚡ Performance Optimization

This stack has been optimized for efficient transcoding:

#### ✅ Subtitle Optimization (Bazarr)
- **Problem:** Image-based subtitles (PGS) require CPU-intensive OCR burn-in
- **Solution:** Bazarr automatically downloads text-based SRT subtitles
- **Impact:** 40-60% CPU reduction per stream

#### ✅ Hardware Transcoding (Intel QuickSync)
- **Problem:** Video transcoding on CPU uses 60-80% per stream
- **Solution:** GPU passthrough in Proxmox enables Intel QuickSync
- **Impact:** 85% CPU reduction, 3-5 simultaneous transcodes possible

#### Performance Results
| Scenario | Before Optimization | After Optimization |
|----------|-------------------|-------------------|
| 1x Remote Transcode | 205% CPU | 20-30% CPU |
| Power Consumption | ~35W | ~20W |
| Max Concurrent Streams | 1 | 4-5 |

**See detailed guides:**
- [Transcoding Optimization](docs/TRANSCODING-OPTIMIZATION.md)
- [GPU Passthrough Setup](docs/GPU-PASSTHROUGH.md)

### 🔒 Security & Privacy
- **VPN Protection**: All torrent traffic routed through NordVPN WireGuard
- **Split Tunneling**: Plex bypasses VPN for optimal streaming performance
- **Firewall Rules**: MikroTik firewall with precise NAT and filter rules
- **UFW Hardening**: Ubuntu Server firewall configured for minimal attack surface

### 🌐 Network Features
- **External Access**: Plex accessible from anywhere (port 32400)
- **VLAN Segmentation**: Isolated network segments for security
- **VPN Kill Switch**: Automatic traffic blocking if VPN drops
- **NAT Hairpin**: Local access via external IP address

### 📊 Monitoring & Maintenance
- **Tautulli**: Real-time Plex monitoring and statistics
- **Automated Cleanup**: Scripts for duplicate removal and maintenance
- **Health Checks**: Verification scripts for all services
- **Logging**: Comprehensive logging for troubleshooting

---

## 🛠️ Tech Stack

### Infrastructure
- **Hypervisor**: Proxmox VE 8.x
- **OS**: Ubuntu Server 24.04 LTS
- **Containerization**: Docker + Docker Compose
- **Router**: MikroTik RouterOS 7.x

### Applications
- **Media Server**: Plex Media Server (LinuxServer.io image)
- **TV Management**: Sonarr v4
- **Movie Management**: Radarr v5
- **Subtitle Management**: Bazarr
- **Download Client**: qBittorrent 4.x
- **Indexer Manager**: Prowlarr
- **Request Platform**: Overseerr
- **Analytics**: Tautulli

### Network & Security
- **VPN**: NordVPN (WireGuard protocol)
- **Firewall**: MikroTik Firewall, UFW
- **DNS**: Configured for leak prevention
- **SSL/TLS**: Ready for reverse proxy integration

---

## 📦 Prerequisites

### Software Requirements
- Proxmox VE 8.x (or bare metal Ubuntu Server 24.04 LTS)
- Docker Engine 24.x+
- Docker Compose 2.x+
- MikroTik RouterOS 7.x+

### Network Requirements
- Static IP for media server
- VPN subscription (NordVPN recommended, but works with any WireGuard provider)

### Knowledge Requirements
- Basic Linux command line
- Docker basics
- Basic networking (NAT, firewall concepts)
- MikroTik RouterOS basics (optional but helpful)

---

## 🚀 Quick Start

### 1. Clone Repository

```bash
git clone https://github.com/Kermitt3001/Plex-Automation-Stack.git
cd Plex-Automation-Stack
```

### 2. Configure Environment

```bash
# Edit docker-compose.yml with your paths and settings
nano docker-compose.yml

# Create required directories
mkdir -p /path/to/media/{movies,tv,downloads}
mkdir -p /path/to/config/{plex,sonarr,radarr,qbittorrent}
```

### 3. Deploy Docker Stack

```bash
docker-compose up -d
```

### 4. Configure MikroTik Router

```bash
# SSH to MikroTik
ssh admin@192.xxx.xx.x

# Import configurations (adjust IP addresses first!)
/import plex-nat.rsc
/import plex-firewall.rsc
/import vpn-split-tunnel.rsc
```

### 5. Verify Setup

```bash
# Run verification script
./scripts/plex-verification.sh

# Check if Plex bypasses VPN
docker exec plex curl ifconfig.me
# Should show your ISP IP, not VPN IP
```

### 6. Configure Applications

1. **Plex**: http://192.168.xx.x:32400/web
   - Enable Remote Access
   - Set manual port: 32400
   
2. **Prowlarr**: http://192.168.xx.x:9696
   - Add indexers
   - Connect to Sonarr/Radarr

3. **Sonarr**: http://192.168.xx.x:8989
   - Add root folder: `/media/tv`
   - Connect qBittorrent

4. **Radarr**: http://192.168.xx.x:7878
   - Add root folder: `/media/movies`
   - Connect qBittorrent

5. **Overseerr**: http://192.168.xx.x:5055
   - Connect to Plex
   - Configure Sonarr/Radarr

---

## 🌐 Network Configuration

### VLAN Configuration

```
VLAN: 192.168.xx.x/xx
├─ Gateway: 192.168.xx.x (MikroTik)
├─ Media Server: 192.168.xx.x
└─ Client Devices: 192.168.xx.xxx-xxx
```

### Port Forwarding

**ISP Router:**
```
External Port 32400 → MikroTik WAN IP:32400
```

**MikroTik:**
```
WAN:32400 → 192.168.10.3:32400 (Plex)
```

### Firewall Rules Summary

**MikroTik NAT:**
- DSTNAT: Port forward 32400 to Plex
- SRCNAT: Masquerade Plex responses

**MikroTik Filter:**
- INPUT: Allow WAN → 32400
- FORWARD: Allow WAN → Plex:32400

**MikroTik Mangle (VPN Split Tunnel):**
1. Accept traffic to plex.tv domains (bypass VPN)
2. Mark Plex connections (src-port 32400)
3. Route marked connections via main table (no VPN)
4. Accept incoming traffic to Plex (bypass VPN)
5. Route all other server traffic via VPN table

**Ubuntu UFW:**
```bash
ufw allow 32400/tcp comment 'Plex External Access'
ufw allow from 192.168.10.0/24
```

### VPN Split Tunnel Logic

```
IF source = 192.168.xx.x AND destination = plex.tv domains
   → Route via Main table (Direct Internet)

IF source = 192.168.xx.x AND src-port = 32400
   → Mark connection as "plex-direct"
   → Route via Main table (Direct Internet)

IF destination = 192.168.xx.x AND dst-port = 32400
   → Accept (skip further marking)

ELSE IF source = 192.168.xx.x AND destination != RFC1918
   → Route via VPN table (NordVPN)
```

---

## 🎛️ Services

### Service Matrix

| Service | Port | Purpose | VPN | External Access |
|---------|------|---------|-----|-----------------|
| Plex | 32400 | Media streaming | ❌ No (bypass) | ✅ Yes |
| Sonarr | 8989 | TV show management | ✅ Yes | ❌ No |
| Radarr | 7878 | Movie management | ✅ Yes | ❌ No |
| Bazarr | 6767 | Subtitle management | ✅ Yes | ❌ No |
| qBittorrent | 8080 | Download client | ✅ Yes | ❌ No |
| Prowlarr | 9696 | Indexer manager | ✅ Yes | ❌ No |
| Overseerr | 5055 | Request platform | ❌ Optional | ⚠️ Optional |
| Tautulli | 8181 | Plex monitoring | ❌ No | ❌ No |

### Service Dependencies

```
Plex ← Sonarr/Radarr ← Prowlarr
         ↓                ↓
    qBittorrent ←────────┘
         ↓
   Media Files → Plex Library
```

---

## 🔐 Security

### Best Practices Implemented

✅ **Network Segmentation**: VLANs isolate media server traffic  
✅ **VPN Protection**: All torrent traffic encrypted via WireGuard  
✅ **Firewall Hardening**: Minimal open ports, default deny policies  
✅ **SSH Key Authentication**: Password authentication disabled  
✅ **Fail2ban**: Automatic IP banning for failed login attempts  
✅ **Automated Updates**: Unattended-upgrades for security patches  
✅ **Docker Isolation**: Containers run with minimal privileges  

### Security Considerations

⚠️ **External Plex Access**: Port 32400 is exposed to the internet
- Mitigation: Strong Plex account password, 2FA enabled
- Consider: Reverse proxy with SSL for HTTPS

⚠️ **VPN Dependency**: If VPN drops, torrent traffic may leak
- Mitigation: Kill switch configured in qBittorrent
- Monitoring: Scripts check VPN connectivity

⚠️ **Local Network Access**: All services accessible from LAN
- Mitigation: VLAN segmentation, trusted network only
- Consider: Additional authentication layer (Authelia, etc.)

---

## 📊 Monitoring

### Health Checks

```bash
# Check all services
docker ps

# Verify Plex external access
curl -I http://203.0.xxx.xxx:32400/web

# Check VPN split tunnel
curl ifconfig.me  # Should show VPN IP
docker exec plex curl ifconfig.me  # Should show ISP IP

# Monitor active connections
docker exec plex ss -tunap | grep 32400
```

### Tautulli Metrics

Access: http://192.168.xx.x:8181

- Active streams
- Bandwidth usage
- User statistics
- Library growth
- Playback history

### Logs

```bash
# Docker service logs
docker logs plex --tail 100
docker logs sonarr --tail 100
docker logs radarr --tail 100

# System logs
sudo journalctl -u docker -n 50

# MikroTik logs (from router)
/log print where topics~"firewall"
```

---

## 🆘 Troubleshooting

See [TROUBLESHOOTING.md](docs/TROUBLESHOOTING.md) for detailed solutions.

### Common Issues

**Plex Remote Access shows "Not available outside your network"**
- Check port forwarding on ISP router
- Verify MikroTik NAT rules: `/ip firewall nat print where dst-port=32400`
- Test port: https://www.yougetsignal.com/tools/open-ports/

**Torrents not downloading**
- Verify VPN connection: `/ping 8.8.8.8 routing-table=vpn-table`
- Check qBittorrent logs: `docker logs qbittorrent`
- Ensure Prowlarr has active indexers

**Plex using VPN (slow external streams)**
- Check split tunnel: `docker exec plex curl ifconfig.me`
- Verify mangle rule order: `/ip firewall mangle print`
- Plex rules MUST be before VPN rules

**Services not accessible**
- Check UFW: `sudo ufw status`
- Verify Docker: `docker ps`
- Check network: `ip addr show`, `ip route`

---

## 🤝 Contributing

Contributions are welcome! Please:

1. Fork the repository
2. Create a feature branch (`git checkout -b feature/AmazingFeature`)
3. Commit your changes (`git commit -m 'Add some AmazingFeature'`)
4. Push to the branch (`git push origin feature/AmazingFeature`)
5. Open a Pull Request

### Areas for Improvement

- [ ] Cloudflare Tunnel integration for secure external access
- [ ] Ansible playbooks for automated deployment
- [ ] Grafana/Prometheus monitoring stack
- [ ] Automated backup solution
- [ ] 4K transcoding optimization


---

## 📚 Additional Resources

- [Plex Support](https://support.plex.tv/)
- [MikroTik Wiki](https://wiki.mikrotik.com/)
- [Servarr Wiki](https://wiki.servarr.com/)
- [LinuxServer.io Docs](https://docs.linuxserver.io/)

---

## 📄 License

This project is licensed under the MIT License - see the [LICENSE](LICENSE) file for details.

---

## 🙏 Acknowledgments

- **LinuxServer.io** for excellent Docker images
- **Servarr Team** for Sonarr/Radarr/Prowlarr
- **Plex** for the media server platform
- **MikroTik** for powerful networking hardware
- The homelab community for inspiration and support

---

## ⚠️ Disclaimer

This project is for educational and personal use. Users are responsible for:
- Complying with local copyright laws
- Ensuring legal acquisition of media content
- Following VPN provider's terms of service
- Securing their own network infrastructure

The author is not responsible for misuse of this setup.

---

**Built with ❤️ for the homelab community**

[⬆ Back to top](#-plex-automation-stack)
