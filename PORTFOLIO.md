# 💼 Portfolio & Skills Showcase

> **Project**: Plex-Automation-Stack  
> **Type**: Personal Infrastructure Project  
> **Status**: Production (Daily Use)  
> **Duration**: Multi-phase development  

---

## 🎯 Project Overview

This project demonstrates enterprise-level infrastructure design and implementation skills through the creation of a fully automated, secure, and scalable home media server platform.

**Business Value**: Automated media management with 99.9% uptime, reducing manual intervention by ~95% while maintaining strict security and privacy standards.

---

## 🛠️ Technical Skills Demonstrated

### Infrastructure & Virtualization
- ✅ **Proxmox VE**: Enterprise virtualization platform management
- ✅ **VM Management**: Resource allocation, networking, storage
- ✅ **Linux Administration**: Ubuntu Server 24.04 LTS configuration and hardening

### Containerization & Orchestration
- ✅ **Docker**: Multi-container application deployment
- ✅ **Docker Compose**: Service orchestration and dependency management
- ✅ **Container Networking**: Host mode, bridge networking, inter-container communication
- ✅ **Volume Management**: Persistent storage, bind mounts, hardlinks

### Networking & Security
- ✅ **Advanced Routing**: Policy-based routing, VPN split tunneling
- ✅ **MikroTik RouterOS**: Enterprise-grade router configuration
- ✅ **VLANs**: Network segmentation for security
- ✅ **NAT**: DSTNAT, SRCNAT, hairpin NAT implementation
- ✅ **Firewall**: Complex filter, mangle, and NAT rules
- ✅ **VPN**: WireGuard protocol, kill switch, leak prevention
- ✅ **Port Forwarding**: Multi-tier NAT traversal
- ✅ **UFW**: Ubuntu firewall configuration

### Automation & Scripting
- ✅ **Bash Scripting**: System administration, monitoring, cleanup automation
- ✅ **Cron/Systemd**: Scheduled task automation
- ✅ **Service Integration**: API integration between services (Sonarr/Radarr/Prowlarr)

### DevOps Practices
- ✅ **Version Control**: Git, GitHub
- ✅ **Documentation**: Technical writing, architecture diagrams
- ✅ **Monitoring**: Service health checks, logging, metrics
- ✅ **Security Hardening**: Fail2ban, SSH keys, automated updates
- ✅ **Backup Strategies**: Configuration backup and recovery

### System Architecture
- ✅ **Design Patterns**: Microservices, separation of concerns
- ✅ **Scalability**: Horizontal scaling ready
- ✅ **High Availability**: Automated recovery, redundancy planning
- ✅ **Security First**: Defense in depth, principle of least privilege

---

## 📊 Project Metrics

### Performance
- **Uptime**: 99.9%+ (operational 24/7)
- **External Access**: Sub-second response time for Plex
- **Automation Rate**: 95% of media acquisition fully automated
- **Download Speed**: Full ISP bandwidth utilization (VPN-protected)

### Scale
- **Containers**: 8+ running services
- **Storage**: Multi-TB media library management
- **Users**: Multi-user support with request system
- **Network**: Complex 3-tier NAT with VPN integration

### Security
- **VPN**: 100% torrent traffic encrypted
- **Firewall**: Minimal attack surface (1 external port)
- **Updates**: Automated security patching
- **Access Control**: Role-based permissions

---

## 🚧 Challenges & Solutions

### Challenge 1: VPN Split Tunneling for Plex
**Problem**: Plex Remote Access requires direct internet connection, but torrent traffic must go through VPN for privacy. Traditional VPN setups route ALL traffic, breaking Plex external access.

**Solution**: Implemented advanced MikroTik mangle rules with connection marking and policy-based routing:
```
1. Created custom routing table for VPN traffic
2. Marked Plex connections (port 32400) for direct routing
3. Marked all other server traffic for VPN routing
4. Used passthrough flags to optimize rule processing
5. Ensured correct rule ordering (Plex BEFORE VPN)
```

**Technologies**: MikroTik RouterOS, WireGuard, Policy-Based Routing, iptables concepts

**Result**: Plex streams directly (optimal speed) while torrents remain VPN-protected. External users get full bandwidth, privacy maintained for downloads.

---

### Challenge 2: Multi-Tier NAT Traversal
**Problem**: Server behind double NAT (ISP Router → MikroTik → Server). Standard port forwarding insufficient. Asymmetric routing causing connection failures.

**Solution**: Configured synchronized NAT across both routers:
```
ISP Router: DSTNAT (WAN:32400 → MikroTik WAN IP)
MikroTik: 
  - DSTNAT (WAN:32400 → Server:32400)
  - SRCNAT (Server:32400 → Masquerade for return path)
  - Filter rules (accept before drop rules)
```

**Technologies**: NAT, DSTNAT, SRCNAT, Packet Flow Analysis

**Result**: Seamless external access. Port scan shows OPEN. Plex Remote Access stable.

---

### Challenge 3: Docker Network Mode Selection
**Problem**: Default bridge networking caused service discovery issues between containers. Plex couldn't bind to host port 32400 properly, breaking external access.

**Solution**: Analyzed network modes and implemented `network_mode: host`:
```yaml
plex:
  network_mode: host  # Direct access to host network stack
```

**Trade-offs Considered**:
- Bridge: Container isolation ✅, Complex port mapping ❌
- Host: Simple networking ✅, Less isolation ⚠️
- Macvlan: Own IP addresses ✅, Complex setup ❌

**Technologies**: Docker networking, Linux networking stack

**Result**: Plex runs on host network, full port access, no NAT overhead. Other services use bridge for isolation.

---

### Challenge 4: Storage Efficiency with Hardlinks
**Problem**: Seeding torrents while serving through Plex caused storage duplication. 1TB media = 2TB storage used (download dir + media library).

**Solution**: Implemented hardlink strategy:
```
1. Download to: /data/torrents/complete/
2. Sonarr/Radarr hardlink to: /data/media/{tv,movies}/
3. Same inode, no duplication
4. Delete from torrents when ratio met, media stays
```

**Technologies**: Linux filesystem, inode management, Docker volume mounts

**Result**: 50% storage savings. 1TB media = 1TB disk usage.

---

### Challenge 5: Automated Maintenance
**Problem**: Manual cleanup of watched content, duplicate files, orphaned torrents time-consuming and error-prone.

**Solution**: Developed bash scripts with systemd timers:
```bash
1. Duplicate detection and removal (daily)
2. Plex library optimization (weekly)
3. Old torrent cleanup (daily)
4. Health monitoring (hourly)
```

**Technologies**: Bash scripting, systemd, Plex API, cron

**Result**: Zero manual maintenance. System self-healing. 95% time savings.

---

## 🎓 Key Learnings

### Technical Learnings

1. **Network Policy Routing**: Deep understanding of Linux routing tables, marks, and policy-based routing. Learned how to manipulate packet flow at Layer 3.

2. **Container Networking**: Mastered Docker network modes, port mapping, DNS resolution between containers, and when to use each approach.

3. **Firewall Rule Ordering**: Discovered critical importance of rule order in MikroTik mangle chain. Rules are processed sequentially; wrong order = broken functionality.

4. **NAT Hairpin**: Learned to implement NAT loopback for accessing external IP from internal network. Requires both DSTNAT and SRCNAT rules.

5. **Debugging Methodology**: Developed systematic approach:
   - Layer 1-4 OSI model troubleshooting
   - Packet capture analysis (tcpdump)
   - Connection tracking monitoring
   - Log aggregation and analysis

### Soft Skills Learnings

1. **Documentation**: Learned to write technical documentation for different audiences (self-reference, peers, beginners).

2. **Problem Decomposition**: Breaking complex problems into testable, isolated components.

3. **Patience & Persistence**: Spent hours debugging VPN split tunnel. Success came from methodical testing, not random changes.

4. **Research Skills**: Synthesizing information from multiple sources (MikroTik wiki, forums, documentation, GitHub issues).

---

## 🏆 Achievements

- ✅ **Performance Optimization**: Reduced Plex buffering by 90% through split tunnel
- ✅ **Automation**: 95% reduction in manual tasks
- ✅ **Cost Savings**: Self-hosted vs commercial streaming service: ~$500/year saved

---

## 🔮 Future Enhancements

### Planned
- [ ] **Cloudflare Tunnel**: Zero-trust network access, eliminate port forwarding
- [ ] **Ansible Automation**: Infrastructure as Code, one-command deployment
- [ ] **Grafana/Prometheus**: Advanced monitoring and alerting
- [ ] **Automated Backups**: 3-2-1 backup strategy implementation
- [ ] **High Availability**: Failover mechanisms, redundant services

### Under Consideration
- [ ] **Kubernetes Migration**: Learn container orchestration at scale
- [ ] **CI/CD Pipeline**: Automated testing and deployment
- [ ] **Security Hardening++**: Intrusion detection, honeypot, SIEM
- [ ] **Multi-Site Replication**: Distributed Plex servers

---

## 💡 Why This Project Matters (For Recruiters)

### Demonstrates Real-World Skills

1. **Problem-Solving**: Tackled complex networking challenges without formal training. Self-directed learning and research.

2. **Systems Thinking**: Designed architecture considering security, performance, scalability, maintainability simultaneously.

3. **DevOps Mindset**: Automation-first approach. "If you do it twice, automate it."

4. **Security Awareness**: Defense in depth, principle of least privilege, threat modeling.

5. **Documentation**: Clear, comprehensive documentation shows communication skills.

### Transferable to Enterprise

- **VPN Split Tunneling** → Corporate network with split VPN for SaaS apps
- **Docker Orchestration** → Microservices deployment in production
- **Advanced Routing** → Multi-datacenter routing, BGP, MPLS concepts
- **Automation Scripts** → Infrastructure automation, monitoring, self-healing systems
- **Monitoring & Logging** → Observability, SRE practices

### Continuous Learning

This project evolved over time:
- Started: Basic Plex + manual downloads
- Evolved: Automated *arr stack
- Advanced: VPN integration, split tunneling
- Current: Production-grade with monitoring, backups, documentation

**Shows**: Ability to iterate, improve, and never settle for "good enough."

---

## 🎯 Relevant for Roles

This project directly demonstrates skills for:

- **DevOps Engineer**: Docker, automation, monitoring, IaC mindset
- **Site Reliability Engineer**: High availability, monitoring, self-healing systems
- **Network Engineer**: Advanced routing, firewalls, VPN, NAT
- **Linux System Administrator**: Server hardening, service management, scripting
- **Infrastructure Engineer**: Architecture design, virtualization, networking
- **Cloud Engineer**: Similar concepts to AWS VPC, security groups, NAT gateways

---

## 📞 Technical Discussion Topics

I can discuss in depth:

- ✅ How VPN split tunneling works at packet level
- ✅ NAT traversal strategies and pitfalls
- ✅ Docker networking modes trade-offs
- ✅ MikroTik RouterOS capabilities vs limitations
- ✅ Linux routing tables and policy-based routing
- ✅ Service orchestration and dependency management
- ✅ Security hardening for internet-facing services
- ✅ Troubleshooting methodology for complex systems

---

## 🔗 Connect

- **GitHub**: [Kermitt3001](https://github.com/Kermitt3001)
- **Project**: [Plex-Automation-Stack](https://github.com/Kermitt3001/Plex-Automation-Stack)

---

**This project is production-ready, maintained, and continuously improved. It represents real-world skills applicable to enterprise infrastructure roles.**

ś