#!/bin/bash
## ═══════════════════════════════════════════════════════════════════════
## UFW FIREWALL CONFIGURATION FOR MEDIA SERVER
## ═══════════════════════════════════════════════════════════════════════
##
## This script configures UFW (Uncomplicated Firewall) on Ubuntu Server
## for secure media server operation with external Plex access
##
## Usage: sudo ./ufw-config.sh
##
## ═══════════════════════════════════════════════════════════════════════

set -e  # Exit on error

# Colors for output
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
RED='\033[0;31m'
NC='\033[0m' # No Color

echo -e "${GREEN}╔════════════════════════════════════════════════════════════╗${NC}"
echo -e "${GREEN}║     UFW FIREWALL CONFIGURATION - MEDIA SERVER              ║${NC}"
echo -e "${GREEN}╚════════════════════════════════════════════════════════════╝${NC}"
echo ""

# Check if running as root
if [[ $EUID -ne 0 ]]; then
   echo -e "${RED}This script must be run as root (use sudo)${NC}"
   exit 1
fi

# ═══════════════════════════════════════════════════════════════════════
# STEP 1: Backup current UFW configuration
# ═══════════════════════════════════════════════════════════════════════
echo -e "${YELLOW}[1/6] Backing up current UFW configuration...${NC}"
if [ -d "/etc/ufw" ]; then
    cp -r /etc/ufw /etc/ufw.backup.$(date +%Y%m%d-%H%M%S)
    echo -e "${GREEN}✓ Backup created${NC}"
else
    echo -e "${YELLOW}! No existing UFW config found${NC}"
fi
echo ""

# ═══════════════════════════════════════════════════════════════════════
# STEP 2: Reset UFW (optional - comment out if you have existing rules)
# ═══════════════════════════════════════════════════════════════════════
# echo -e "${YELLOW}[2/6] Resetting UFW to defaults...${NC}"
# ufw --force reset
# echo -e "${GREEN}✓ UFW reset${NC}"
# echo ""

# ═══════════════════════════════════════════════════════════════════════
# STEP 3: Set default policies
# ═══════════════════════════════════════════════════════════════════════
echo -e "${YELLOW}[2/6] Setting default policies...${NC}"
ufw default deny incoming
ufw default allow outgoing
ufw default deny routed
echo -e "${GREEN}✓ Default policies set${NC}"
echo ""

# ═══════════════════════════════════════════════════════════════════════
# STEP 4: Configure rules
# ═══════════════════════════════════════════════════════════════════════
echo -e "${YELLOW}[3/6] Adding firewall rules...${NC}"

# SSH - Allow from local network only (CHANGE 192.168.10.0/24 to your subnet!)
echo "  → SSH from LAN"
ufw allow from 192.168.10.0/24 to any port 22 proto tcp comment 'SSH from LAN'

# Plex - Allow from anywhere (external access)
echo "  → Plex (32400) from anywhere"
ufw allow 32400/tcp comment 'Plex External Access'

# Media management services - Allow from local network only
echo "  → Sonarr (8989) from LAN"
ufw allow from 192.168.10.0/24 to any port 8989 proto tcp comment 'Sonarr'

echo "  → Radarr (7878) from LAN"
ufw allow from 192.168.10.0/24 to any port 7878 proto tcp comment 'Radarr'

echo "  → Bazarr (6767) from LAN"
ufw allow from 192.168.10.0/24 to any port 6767 proto tcp comment 'Bazarr'

echo "  → qBittorrent (8080) from LAN"
ufw allow from 192.168.10.0/24 to any port 8080 proto tcp comment 'qBittorrent'

echo "  → Prowlarr (9696) from LAN"
ufw allow from 192.168.10.0/24 to any port 9696 proto tcp comment 'Prowlarr'

echo "  → Overseerr (5055) from LAN"
ufw allow from 192.168.10.0/24 to any port 5055 proto tcp comment 'Overseerr'

echo "  → Tautulli (8181) from LAN"
ufw allow from 192.168.10.0/24 to any port 8181 proto tcp comment 'Tautulli'

# DNS (if using custom DNS)
echo "  → DNS (53) outgoing"
ufw allow out 53 comment 'DNS'

echo -e "${GREEN}✓ Rules added${NC}"
echo ""

# ═══════════════════════════════════════════════════════════════════════
# STEP 5: Enable UFW
# ═══════════════════════════════════════════════════════════════════════
echo -e "${YELLOW}[4/6] Enabling UFW...${NC}"
ufw --force enable
echo -e "${GREEN}✓ UFW enabled${NC}"
echo ""

# ═══════════════════════════════════════════════════════════════════════
# STEP 6: Verify configuration
# ═══════════════════════════════════════════════════════════════════════
echo -e "${YELLOW}[5/6] Verifying configuration...${NC}"
echo ""
ufw status verbose
echo ""

# ═══════════════════════════════════════════════════════════════════════
# STEP 7: Test connectivity
# ═══════════════════════════════════════════════════════════════════════
echo -e "${YELLOW}[6/6] Testing connectivity...${NC}"

# Test Plex port
if ss -tlnp | grep -q ":32400"; then
    echo -e "${GREEN}✓ Plex port 32400 is listening${NC}"
else
    echo -e "${RED}✗ Plex port 32400 is NOT listening${NC}"
fi

# Test outbound connectivity
if curl -s -m 5 ifconfig.me > /dev/null; then
    echo -e "${GREEN}✓ Outbound connectivity OK${NC}"
else
    echo -e "${RED}✗ Outbound connectivity FAILED${NC}"
fi

echo ""
echo -e "${GREEN}╔════════════════════════════════════════════════════════════╗${NC}"
echo -e "${GREEN}║               UFW CONFIGURATION COMPLETE                   ║${NC}"
echo -e "${GREEN}╚════════════════════════════════════════════════════════════╝${NC}"
echo ""
echo -e "${YELLOW}Important Notes:${NC}"
echo "1. SSH is restricted to local network (192.168.10.0/24)"
echo "2. Plex (32400) is accessible from anywhere"
echo "3. All other services are LAN-only"
echo "4. Test external Plex access: http://YOUR_PUBLIC_IP:32400/web"
echo ""
echo -e "${YELLOW}To add/remove rules:${NC}"
echo "  sudo ufw allow from <IP> to any port <PORT>"
echo "  sudo ufw delete allow from <IP> to any port <PORT>"
echo ""
echo -e "${YELLOW}To disable UFW (NOT RECOMMENDED):${NC}"
echo "  sudo ufw disable"
echo ""
