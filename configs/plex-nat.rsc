## ═══════════════════════════════════════════════════════════════════════
## MIKROTIK - NAT CONFIGURATION FOR PLEX EXTERNAL ACCESS
## ═══════════════════════════════════════════════════════════════════════
## 
## BEFORE IMPORTING:
## 1. Replace INTERFACE_WAN with your WAN interface (e.g., ether1, pppoe-out1)
## 2. Replace 192.168.xx.x with your Plex server IP
## 3. Test in safe mode first: Ctrl+X in terminal
##
## ═══════════════════════════════════════════════════════════════════════

## BACKUP FIRST!
/export file=backup_before_plex_nat

## ═══════════════════════════════════════════════════════════════════════
## DSTNAT - Port Forward from WAN to Plex Server
## ═══════════════════════════════════════════════════════════════════════
/ip firewall nat add \
  chain=dstnat \
  action=dst-nat \
  to-addresses=192.168.xx.x \
  to-ports=32400 \
  protocol=tcp \
  in-interface=INTERFACE_WAN \
  dst-port=32400 \
  comment="Plex External Access - Port Forward"

## ═══════════════════════════════════════════════════════════════════════
## SRCNAT - Masquerade for Plex responses
## ═══════════════════════════════════════════════════════════════════════
## This ensures return packets go back through the correct path
/ip firewall nat add \
  chain=srcnat \
  action=masquerade \
  protocol=tcp \
  src-address=192.168.xx.x \
  out-interface=INTERFACE_WAN \
  src-port=32400 \
  comment="Plex External Access - Masquerade"

## ═══════════════════════════════════════════════════════════════════════
## NAT HAIRPIN (Optional) - Access via external IP from LAN
## ═══════════════════════════════════════════════════════════════════════
## Uncomment if you want to access Plex via external IP from local network
## Replace YOUR_EXTERNAL_IP with your public IP address
##
## /ip firewall nat add \
##   chain=dstnat \
##   src-address=192.168.xx.0/24 \
##   dst-address=YOUR_EXTERNAL_IP \
##   protocol=tcp \
##   dst-port=32400 \
##   action=dst-nat \
##   to-addresses=192.168.xx.x \
##   to-ports=32400 \
##   comment="Plex Hairpin - DSTNAT"
##
## /ip firewall nat add \
##   chain=srcnat \
##   src-address=192.168.xx.0/24 \
##   dst-address=192.168.xx.x \
##   protocol=tcp \
##   dst-port=32400 \
##   action=masquerade \
##   comment="Plex Hairpin - SRCNAT"

## ═══════════════════════════════════════════════════════════════════════
## VERIFICATION
## ═══════════════════════════════════════════════════════════════════════
:put "=== NAT Rules Added ==="
/ip firewall nat print where dst-port=32400
:put ""
:put "Test external access: http://YOUR_EXTERNAL_IP:32400/web"
:put "Test port: https://www.yougetsignal.com/tools/open-ports/"
