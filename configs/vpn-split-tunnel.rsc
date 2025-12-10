## ═══════════════════════════════════════════════════════════════════════
## MIKROTIK - VPN SPLIT TUNNEL FOR PLEX
## ═══════════════════════════════════════════════════════════════════════
##
## PURPOSE: Route Plex traffic directly (no VPN) while routing all other
##          server traffic through VPN for privacy
##
## BEFORE IMPORTING:
## 1. Replace 192.168.xx.x with your server IP
## 2. Ensure you have routing tables: "main" and "vpn-table"
## 3. Ensure you have address-list: "plex-domains"
## 4. These rules MUST be BEFORE any existing VPN routing rules
##
## ═══════════════════════════════════════════════════════════════════════

## BACKUP FIRST!
/export file=backup_before_plex_split_tunnel

## ═══════════════════════════════════════════════════════════════════════
## STEP 1: Create address-list for Plex domains
## ═══════════════════════════════════════════════════════════════════════
/ip firewall address-list add list=plex-domains address=plex.tv comment="Plex.tv domain"
/ip firewall address-list add list=plex-domains address=plex.direct comment="Plex Direct"
/ip firewall address-list add list=plex-domains address=my.plexapp.com comment="Plex App"
/ip firewall address-list add list=plex-domains address=app.plex.tv comment="Plex App Web"

## ═══════════════════════════════════════════════════════════════════════
## STEP 2: Ensure routing tables exist
## ═══════════════════════════════════════════════════════════════════════
## Check: /routing table print
## You should have:
## - "main" (default, direct internet)
## - "vpn-table" (routes through VPN interface)
##
## If "vpn-table" doesn't exist, create it:
## /routing table add name=vpn-table fib
##
## Then add default route to VPN:
## /ip route add dst-address=0.0.0.0/0 gateway=YOUR_VPN_INTERFACE routing-table=vpn-table

## ═══════════════════════════════════════════════════════════════════════
## STEP 3: MANGLE RULES - VPN Split Tunnel (CRITICAL ORDER!)
## ═══════════════════════════════════════════════════════════════════════

## ───────────────────────────────────────────────────────────────────────
## RULE 1: Bypass VPN for connections TO plex.tv domains
## ───────────────────────────────────────────────────────────────────────
## This allows Plex to register with plex.tv for Remote Access
/ip firewall mangle add \
  chain=prerouting \
  src-address=192.168.xx.x \
  dst-address-list=plex-domains \
  action=accept \
  place-before=0 \
  comment="Plex to Plex.tv - Bypass VPN"

## ───────────────────────────────────────────────────────────────────────
## RULE 2: Mark Plex Server connections (source port 32400)
## ───────────────────────────────────────────────────────────────────────
## Marks connections FROM Plex server TO external clients
/ip firewall mangle add \
  chain=prerouting \
  src-address=192.168.xx.x \
  protocol=tcp \
  src-port=32400 \
  dst-address-list=!RFC1918 \
  action=mark-connection \
  new-connection-mark=plex-direct \
  passthrough=yes \
  place-before=1 \
  comment="Plex Server - Mark Connection"

## ───────────────────────────────────────────────────────────────────────
## RULE 3: Route marked connections via main table (Direct, no VPN)
## ───────────────────────────────────────────────────────────────────────
/ip firewall mangle add \
  chain=prerouting \
  connection-mark=plex-direct \
  action=mark-routing \
  new-routing-mark=main \
  passthrough=no \
  place-before=2 \
  comment="Plex Server - Route Direct (no VPN)"

## ───────────────────────────────────────────────────────────────────────
## RULE 4: Accept incoming traffic TO Plex (skip further processing)
## ───────────────────────────────────────────────────────────────────────
/ip firewall mangle add \
  chain=prerouting \
  dst-address=192.168.xx.x \
  protocol=tcp \
  dst-port=32400 \
  action=accept \
  place-before=3 \
  comment="Plex Incoming - Bypass VPN"

## ═══════════════════════════════════════════════════════════════════════
## STEP 4: VPN ROUTING FOR OTHER TRAFFIC (if not already configured)
## ═══════════════════════════════════════════════════════════════════════
## This rule should come AFTER the Plex rules above!
## If you already have a VPN routing rule, ensure it's AFTER Plex rules
##
## Example VPN routing rule (adjust to your setup):
## /ip firewall mangle add \
##   chain=prerouting \
##   src-address=192.168.xx.x \
##   dst-address-list=!RFC1918 \
##   action=mark-routing \
##   new-routing-mark=vpn-table \
##   passthrough=yes \
##   comment="Server - Route via VPN (external only)"

## ═══════════════════════════════════════════════════════════════════════
## VERIFICATION
## ═══════════════════════════════════════════════════════════════════════
:put "=== Mangle Rules Added ==="
/ip firewall mangle print where comment~"Plex"
:put ""
:put "=== CRITICAL: Verify rule order ==="
:put "Plex rules MUST be BEFORE VPN routing rules!"
:put "Use: /ip firewall mangle print"
:put ""
:put "Expected order:"
:put "  0: Plex to Plex.tv - Bypass VPN"
:put "  1: Plex Server - Mark Connection"
:put "  2: Plex Server - Route Direct (no VPN)"
:put "  3: Plex Incoming - Bypass VPN"
:put "  4+: VPN routing rules (for other traffic)"
:put ""
:put "=== Testing ==="
:put "On server, run:"
:put "  curl ifconfig.me                    # Should show VPN IP"
:put "  docker exec plex curl ifconfig.me   # Should show ISP IP (different!)"
:put ""
:put "If both show same IP, check rule order!"

## ═══════════════════════════════════════════════════════════════════════
## TROUBLESHOOTING
## ═══════════════════════════════════════════════════════════════════════
##
## Problem: Both IPs are same (VPN IP)
## Solution: Check mangle rule order, Plex MUST be before VPN
##
## Problem: Plex Remote Access unstable
## Solution: Verify plex.tv domains in address-list
##
## Problem: No routing table "main"
## Solution: Main routing table exists by default, check: /routing table print
##
## Problem: VPN routing broken after applying
## Solution: Rules with "accept" action skip further processing
##           Ensure VPN rules are AFTER Plex rules
##
## ═══════════════════════════════════════════════════════════════════════
