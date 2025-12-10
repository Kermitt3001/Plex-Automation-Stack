# 🆘 Troubleshooting Guide

This document covers common issues and their solutions for the Plex-Automation-Stack.

---

## 📋 Table of Contents

- [Plex External Access Issues](#plex-external-access-issues)
- [VPN Split Tunnel Problems](#vpn-split-tunnel-problems)
- [Download Issues](#download-issues)
- [Network Connectivity](#network-connectivity)
- [Docker Problems](#docker-problems)
- [Performance Issues](#performance-issues)
- [Diagnostic Commands](#diagnostic-commands)

---

## 🎬 Plex External Access Issues

### Problem: "Not available outside your network"

**Symptom**: Plex Remote Access shows green checkmark briefly, then disappears or shows error.

**Diagnosis**:
```bash
# Test external port
curl -I http://YOUR_EXTERNAL_IP:32400/web

# Check if port is listening
sudo ss -tlnp | grep 32400

# Test online
# Visit: https://www.yougetsignal.com/tools/open-ports/
```

**Solutions**:

1. **Check ISP Router Port Forwarding**
   - Log into ISP router
   - Verify port 32400 → MikroTik IP
   - Or set MikroTik in DMZ

2. **Verify MikroTik NAT**
   ```bash
   # SSH to MikroTik
   /ip firewall nat print where dst-port=32400
   
   # Should show DSTNAT rule
   ```

3. **Check Firewall Filter**
   ```bash
   /ip firewall filter print where dst-port=32400
   
   # Should show accept rules BEFORE drop rules
   ```

4. **UFW on Ubuntu**
   ```bash
   sudo ufw status | grep 32400
   # Should show: 32400  ALLOW  Anywhere
   ```

5. **Plex Configuration**
   - Open: http://LOCAL_IP:32400/web
   - Settings → Remote Access
   - Enable Remote Access: ✅
   - Manually specify port: 32400
   - Click "Retry"

---

### Problem: Port shows CLOSED on external test

**Diagnosis**:
```bash
# On server
docker ps | grep plex
sudo netstat -tlnp | grep 32400

# On MikroTik
/ip firewall connection print where dst-port=32400
```

**Solutions**:

1. **Verify Port Chain**
   ```
   Internet → ISP Router:32400 → MikroTik WAN:32400 → Server:32400
   ```
   Test each hop individually.

2. **Check for Firewall Blocking**
   ```bash
   # MikroTik - temporarily log drops
   /ip firewall filter add chain=forward dst-port=32400 action=log
   /log print where message~"32400"
   ```

3. **ISP Blocking**
   - Some ISPs block port 32400
   - Try alternative port (e.g., 32401)
   - Update port in Plex, MikroTik, ISP router

4. **Double NAT Issues**
   - If ISP router → MikroTik → Server
   - Ensure port forward on BOTH routers
   - Or put MikroTik in DMZ on ISP router

---

### Problem: Remote Access works but streams are slow

**Cause**: Plex traffic going through VPN (split tunnel not working)

**Diagnosis**:
```bash
# Normal traffic (should be VPN IP)
curl ifconfig.me

# Plex traffic (should be ISP IP, NOT VPN)
docker exec plex curl ifconfig.me

# If both are same = problem!
```

**Solution**: See [VPN Split Tunnel Problems](#vpn-split-tunnel-problems)

---

## 🔐 VPN Split Tunnel Problems

### Problem: Plex uses VPN (slow external streams)

**Symptom**: 
```bash
curl ifconfig.me             # Shows: 198.51.100.50 (VPN)
docker exec plex curl ifconfig.me  # Shows: 198.51.100.50 (VPN) ❌
```
Both should be DIFFERENT IPs!

**Solutions**:

1. **Check Mangle Rule Order**
   ```bash
   # SSH to MikroTik
   /ip firewall mangle print
   
   # Plex rules MUST be BEFORE VPN routing rules!
   # Correct order:
   #   0-3: Plex rules
   #   4+: VPN routing rules
   ```

2. **Fix Rule Order**
   ```bash
   # If Plex rules are after VPN rules:
   /ip firewall mangle move [numbers=X,Y,Z] destination=0
   ```

3. **Clear Connection Tracking**
   ```bash
   /ip firewall connection remove [find src-address=192.168.10.3]
   
   # Restart Plex
   docker restart plex
   ```

4. **Verify Address List**
   ```bash
   /ip firewall address-list print where list=plex-domains
   
   # Should contain: plex.tv, plex.direct, my.plexapp.com, app.plex.tv
   ```

---

### Problem: VPN routing broken after Plex config

**Symptom**: Torrents not downloading, all traffic bypassing VPN

**Diagnosis**:
```bash
# Check if traffic goes through VPN
curl ifconfig.me
# Should show VPN IP, not ISP IP

# Check routing
/ip route print where routing-table=vpn-table
```

**Solution**:

Mangle rules with `action=accept` stop processing. Ensure:
```
Plex rules: Use accept only for INCOMING traffic
VPN rules: Come AFTER Plex rules
```

Correct structure:
```
0: Plex to plex.tv → accept (bypass VPN)
1: Plex mark-connection
2: Plex mark-routing → main
3: Plex incoming → accept
4: Docker to external → mark-routing → vpn-table
```

---

## 📥 Download Issues

### Problem: Torrents not downloading

**Diagnosis**:
```bash
# Check qBittorrent logs
docker logs qbittorrent --tail 50

# Check VPN connection
# On MikroTik:
/ping 8.8.8.8 routing-table=vpn-table
```

**Solutions**:

1. **VPN Down**
   ```bash
   # Check VPN interface
   /interface wireguard print
   # Status should be "R" (running)
   ```

2. **No Indexers in Prowlarr**
   - Open Prowlarr: http://LOCAL_IP:9696
   - Add indexers
   - Test connectivity

3. **qBittorrent Not Connected to Sonarr/Radarr**
   - Sonarr/Radarr → Settings → Download Clients
   - Test connection to qBittorrent
   - Verify credentials

4. **Port Forwarding for Torrents**
   - Some trackers require open port
   - Configure in qBittorrent settings
   - Set port in VPN provider settings

---

### Problem: Downloads work but files don't move to Plex

**Diagnosis**:
```bash
# Check Sonarr/Radarr logs
docker logs sonarr --tail 50
docker logs radarr --tail 50

# Check filesystem permissions
ls -la /path/to/media/
```

**Solutions**:

1. **Permission Issues**
   ```bash
   # Fix ownership
   sudo chown -R 1000:1000 /path/to/media/
   sudo chmod -R 755 /path/to/media/
   ```

2. **Path Mismatch**
   - Sonarr/Radarr paths must match qBittorrent
   - Downloads: `/downloads/complete/`
   - Media: `/media/tv/` and `/media/movies/`
   - Must be on same filesystem for hardlinks!

3. **Import Failed**
   - Check Activity tab in Sonarr/Radarr
   - Look for import errors
   - Verify file quality meets profile requirements

---

## 🌐 Network Connectivity

### Problem: Can't access services from LAN

**Diagnosis**:
```bash
# Test connectivity
ping 192.168.10.3

# Check if services are running
docker ps

# Check UFW
sudo ufw status
```

**Solutions**:

1. **UFW Blocking**
   ```bash
   # Allow from your subnet
   sudo ufw allow from 192.168.xx.0/24
   sudo ufw reload
   ```

2. **Docker Network Issues**
   ```bash
   # Check network mode
   docker inspect plex | grep NetworkMode
   
   # Should be "host" for Plex
   ```

3. **VLAN Configuration**
   - Verify client is on correct VLAN
   - Check MikroTik VLAN config
   - Verify inter-VLAN routing if needed

---

### Problem: Intermittent connectivity

**Diagnosis**:
```bash
# Check connection drops
ping -c 100 192.168.xx.3

# Monitor logs
sudo journalctl -u docker -f
```

**Solutions**:

1. **Network Cable Issues**
   - Check physical connections
   - Test with different cable
   - Verify link speed

2. **Switch/Router Issues**
   - Check MikroTik CPU usage
   - Verify no dropped packets
   ```bash
   /interface print stats
   ```

3. **VM Network**
   - If using Proxmox, check VM network settings
   - Ensure virtio drivers are used

---

## 🐳 Docker Problems

### Problem: Containers constantly restarting

**Diagnosis**:
```bash
# Check container status
docker ps -a

# Check logs
docker logs CONTAINER_NAME --tail 100

# Check system resources
docker stats
htop
```

**Solutions**:

1. **Out of Memory**
   ```bash
   # Check memory usage
   free -h
   
   # Limit container memory in docker-compose.yml
   mem_limit: 2g
   ```

2. **Disk Full**
   ```bash
   # Check disk space
   df -h
   
   # Clean Docker
   docker system prune -a
   ```

3. **Configuration Error**
   - Check docker-compose.yml syntax
   - Verify volume paths exist
   - Check environment variables

---

### Problem: Can't pull Docker images

**Diagnosis**:
```bash
# Test Docker hub connectivity
docker pull hello-world

# Check DNS
cat /etc/resolv.conf
ping registry-1.docker.io
```

**Solutions**:

1. **DNS Issues**
   ```bash
   # Use Google DNS
   sudo nano /etc/resolv.conf
   nameserver 8.8.8.8
   nameserver 8.8.4.4
   ```

2. **Docker Hub Rate Limit**
   - Login to Docker Hub
   ```bash
   docker login
   ```

3. **Network Issues**
   - Check VPN isn't blocking Docker registry
   - Verify outbound connectivity

---

## ⚡ Performance Issues

### Problem: Slow Plex transcoding

**Diagnosis**:
```bash
# Check CPU usage during playback
htop

# Check Plex transcoding
docker exec plex cat /transcode/
```

**Solutions**:

1. **Enable Hardware Transcoding**
   - Plex Settings → Transcoder
   - Enable: "Use hardware acceleration when available"
   - Requires Plex Pass

2. **Transcode on SSD**
   ```yaml
   # docker-compose.yml
   volumes:
     - /path/to/ssd/transcode:/transcode
   ```

3. **Lower Quality Settings**
   - Settings → Remote Access
   - Lower remote stream bitrate
   - Adjust quality profiles in Sonarr/Radarr

---

### Problem: High CPU usage on idle

**Diagnosis**:
```bash
# Check process CPU
htop

# Check Docker stats
docker stats
```

**Solutions**:

1. **Plex Library Scanning**
   - Disable scheduled scans
   - Scan manually when needed

2. **Too Many Services**
   - Stop unused containers
   - Use `docker stop CONTAINER_NAME`

3. **Inefficient Scripts**
   - Check cron jobs: `crontab -l`
   - Optimize or space out scheduled tasks

---

## 🔍 Diagnostic Commands

### Quick Health Check

```bash
# All-in-one health check
echo "=== Docker Services ==="
docker ps

echo "=== Disk Space ==="
df -h

echo "=== Memory Usage ==="
free -h

echo "=== CPU Load ==="
uptime

echo "=== Network Connectivity ==="
ping -c 3 8.8.8.8

echo "=== Plex Port ==="
ss -tlnp | grep 32400

echo "=== External IP ==="
curl ifconfig.me
docker exec plex curl ifconfig.me
```

### MikroTik Diagnostics

```bash
# SSH to MikroTik, then:

# Check NAT
/ip firewall nat print where dst-port=32400

# Check Filter
/ip firewall filter print where dst-port=32400

# Check Mangle
/ip firewall mangle print

# Check Connections
/ip firewall connection print where dst-port=32400

# Check Routes
/ip route print
/ip route print where routing-table=vpn-table

# Check VPN
/interface wireguard print
/ping 8.8.8.8 routing-table=vpn-table
```

### Docker Logs

```bash
# Follow logs in real-time
docker logs -f plex

# Last 100 lines
docker logs --tail 100 sonarr

# With timestamps
docker logs --timestamps radarr

# All containers
for container in $(docker ps --format '{{.Names}}'); do
    echo "=== $container ==="
    docker logs --tail 10 $container
done
```

---

## 📞 Getting Help

If problems persist:

1. **Check GitHub Issues**: [Plex-Automation-Stack/issues](https://github.com/Kermitt3001/Plex-Automation-Stack/issues)
2. **Run Verification Script**: `./scripts/plex-verification.sh`
3. **Collect Logs**: Save all relevant logs before asking for help
4. **Be Specific**: Include error messages, what you've tried, your configuration

---

## 📚 Additional Resources

- [Plex Support](https://support.plex.tv/)
- [MikroTik Wiki](https://wiki.mikrotik.com/)
- [Servarr Wiki](https://wiki.servarr.com/)
- [Docker Documentation](https://docs.docker.com/)
- [r/PleX](https://reddit.com/r/PleX)
- [r/homelab](https://reddit.com/r/homelab)

---

[⬆ Back to Main README](../README.md)
