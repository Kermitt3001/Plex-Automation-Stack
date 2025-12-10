#!/bin/bash
## ═══════════════════════════════════════════════════════════════════════
## PLEX VERIFICATION SCRIPT
## ═══════════════════════════════════════════════════════════════════════
##
## Comprehensive testing of:
## - Plex service status
## - External port accessibility
## - VPN split tunnel functionality
## - Network configuration
##
## Usage: ./plex-verification.sh
##
## ═══════════════════════════════════════════════════════════════════════

# Colors
GREEN='\033[0;32m'
RED='\033[0;31m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m'

# Configuration
PLEX_CONTAINER="plex"
PLEX_PORT="32400"
EXTERNAL_IP=""  # Will be detected automatically

# ═══════════════════════════════════════════════════════════════════════
# Helper Functions
# ═══════════════════════════════════════════════════════════════════════

print_header() {
    echo -e "${BLUE}╔════════════════════════════════════════════════════════════╗${NC}"
    echo -e "${BLUE}║  $1${NC}"
    echo -e "${BLUE}╚════════════════════════════════════════════════════════════╝${NC}"
    echo ""
}

test_result() {
    if [ $? -eq 0 ]; then
        echo -e "${GREEN}[✓] PASS${NC}"
        return 0
    else
        echo -e "${RED}[✗] FAIL${NC}"
        return 1
    fi
}

# ═══════════════════════════════════════════════════════════════════════
# Main Tests
# ═══════════════════════════════════════════════════════════════════════

print_header "PLEX EXTERNAL ACCESS + VPN SPLIT TUNNEL - VERIFICATION"

echo -e "${YELLOW}═══════════════════════════════════════════════════════════${NC}"
echo -e "${YELLOW}TEST 1: Docker & Plex Service Status${NC}"
echo -e "${YELLOW}═══════════════════════════════════════════════════════════${NC}"
echo ""

echo -n "1.1. Docker daemon running: "
systemctl is-active --quiet docker
test_result

echo -n "1.2. Plex container running: "
docker ps | grep -q $PLEX_CONTAINER
test_result

echo -n "1.3. Port $PLEX_PORT listening: "
ss -tlnp | grep -q ":$PLEX_PORT"
test_result

echo ""

echo -e "${YELLOW}═══════════════════════════════════════════════════════════${NC}"
echo -e "${YELLOW}TEST 2: Local Accessibility${NC}"
echo -e "${YELLOW}═══════════════════════════════════════════════════════════${NC}"
echo ""

echo -n "2.1. Localhost access (curl): "
HTTP_CODE=$(curl -s -o /dev/null -w "%{http_code}" -m 5 http://localhost:$PLEX_PORT/web)
if [ "$HTTP_CODE" = "302" ] || [ "$HTTP_CODE" = "200" ]; then
    echo -e "${GREEN}[✓] PASS (HTTP $HTTP_CODE)${NC}"
else
    echo -e "${RED}[✗] FAIL (HTTP $HTTP_CODE)${NC}"
fi

echo ""

echo -e "${YELLOW}═══════════════════════════════════════════════════════════${NC}"
echo -e "${YELLOW}TEST 3: VPN Split Tunnel${NC}"
echo -e "${YELLOW}═══════════════════════════════════════════════════════════${NC}"
echo ""

echo "3.1. Normal traffic IP (should be VPN):"
NORMAL_IP=$(curl -s -m 10 ifconfig.me)
echo -e "     ${BLUE}$NORMAL_IP${NC}"

echo ""
echo "3.2. Plex container IP (should be ISP, NOT VPN):"
PLEX_IP=$(docker exec $PLEX_CONTAINER curl -s -m 10 ifconfig.me 2>/dev/null || echo "FAIL")
echo -e "     ${BLUE}$PLEX_IP${NC}"

echo ""
if [ "$PLEX_IP" != "$NORMAL_IP" ] && [ "$PLEX_IP" != "FAIL" ]; then
    echo -e "${GREEN}[✓] Split tunnel working! Plex bypasses VPN.${NC}"
    SPLIT_TUNNEL_OK=true
elif [ "$PLEX_IP" = "FAIL" ]; then
    echo -e "${RED}[✗] Cannot test Plex IP${NC}"
    SPLIT_TUNNEL_OK=false
else
    echo -e "${RED}[✗] Split tunnel NOT working! Both IPs are same.${NC}"
    echo -e "${YELLOW}    Check MikroTik mangle rules order.${NC}"
    SPLIT_TUNNEL_OK=false
fi

echo ""

echo -e "${YELLOW}═══════════════════════════════════════════════════════════${NC}"
echo -e "${YELLOW}TEST 4: External Port Accessibility${NC}"
echo -e "${YELLOW}═══════════════════════════════════════════════════════════${NC}"
echo ""

# Detect external IP
if [ -z "$EXTERNAL_IP" ]; then
    EXTERNAL_IP=$(curl -s -m 10 ifconfig.me)
fi

echo "4.1. Your external IP: ${BLUE}$EXTERNAL_IP${NC}"
echo ""

echo -n "4.2. External port test (curl): "
EXT_HTTP_CODE=$(curl -s -o /dev/null -w "%{http_code}" -m 10 http://$EXTERNAL_IP:$PLEX_PORT/web 2>/dev/null)
if [ "$EXT_HTTP_CODE" = "302" ] || [ "$EXT_HTTP_CODE" = "200" ]; then
    echo -e "${GREEN}[✓] PASS (HTTP $EXT_HTTP_CODE)${NC}"
    EXTERNAL_OK=true
else
    echo -e "${RED}[✗] FAIL (HTTP $EXT_HTTP_CODE)${NC}"
    EXTERNAL_OK=false
fi

echo ""
echo "4.3. Online port checker:"
echo "     Test manually: https://www.yougetsignal.com/tools/open-ports/"
echo "     IP: $EXTERNAL_IP"
echo "     Port: $PLEX_PORT"
echo "     Expected: OPEN"

echo ""

echo -e "${YELLOW}═══════════════════════════════════════════════════════════${NC}"
echo -e "${YELLOW}TEST 5: Active Connections${NC}"
echo -e "${YELLOW}═══════════════════════════════════════════════════════════${NC}"
echo ""

echo "5.1. Current connections on port $PLEX_PORT:"
ss -tunap | grep ":$PLEX_PORT" || echo "     No active connections"

echo ""

echo -e "${YELLOW}═══════════════════════════════════════════════════════════${NC}"
echo -e "${YELLOW}TEST 6: Plex Remote Access Logs${NC}"
echo -e "${YELLOW}═══════════════════════════════════════════════════════════${NC}"
echo ""

echo "6.1. Recent Remote Access logs:"
docker logs $PLEX_CONTAINER 2>&1 | grep -i "remote" | tail -5 || echo "     No recent logs"

echo ""

# ═══════════════════════════════════════════════════════════════════════
# Summary
# ═══════════════════════════════════════════════════════════════════════

echo -e "${BLUE}╔════════════════════════════════════════════════════════════╗${NC}"
echo -e "${BLUE}║                     TEST SUMMARY                           ║${NC}"
echo -e "${BLUE}╚════════════════════════════════════════════════════════════╝${NC}"
echo ""

if [ "$SPLIT_TUNNEL_OK" = true ] && [ "$EXTERNAL_OK" = true ]; then
    echo -e "${GREEN}✅ ALL TESTS PASSED!${NC}"
    echo ""
    echo "✓ Plex is accessible externally"
    echo "✓ VPN split tunnel working (Plex bypasses VPN)"
    echo "✓ System configured correctly"
    echo ""
    echo "Next steps:"
    echo "1. Configure Remote Access in Plex Web UI"
    echo "2. Test from mobile device (LTE/5G)"
    echo "3. Monitor with: docker logs -f plex"
    EXIT_CODE=0
elif [ "$EXTERNAL_OK" = true ]; then
    echo -e "${YELLOW}⚠ PARTIAL SUCCESS${NC}"
    echo ""
    echo "✓ Plex is accessible externally"
    echo "✗ VPN split tunnel may not be working"
    echo ""
    echo "Troubleshooting:"
    echo "1. Check MikroTik mangle rules"
    echo "2. Verify rule order (Plex BEFORE VPN)"
    echo "3. Restart Plex: docker restart plex"
    EXIT_CODE=1
else
    echo -e "${RED}❌ TESTS FAILED${NC}"
    echo ""
    echo "Issues found:"
    [ "$EXTERNAL_OK" = false ] && echo "✗ External access not working"
    [ "$SPLIT_TUNNEL_OK" = false ] && echo "✗ VPN split tunnel not working"
    echo ""
    echo "Troubleshooting steps:"
    echo "1. Check port forwarding on ISP router"
    echo "2. Verify MikroTik NAT rules"
    echo "3. Check UFW firewall: sudo ufw status"
    echo "4. Verify Plex is running: docker ps"
    echo "5. Check logs: docker logs plex"
    EXIT_CODE=1
fi

echo ""
echo "═══════════════════════════════════════════════════════════"
echo "Full documentation: https://github.com/Kermitt3001/Plex-Automation-Stack"
echo "═══════════════════════════════════════════════════════════"

exit $EXIT_CODE
