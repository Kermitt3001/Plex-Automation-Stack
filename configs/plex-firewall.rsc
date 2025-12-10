## ═══════════════════════════════════════════════════════════════════════
## MIKROTIK - FIREWALL FILTER RULES FOR PLEX
## ═══════════════════════════════════════════════════════════════════════
##
## BEFORE IMPORTING:
## 1. Replace INTERFACE_WAN with your WAN interface
## 2. Replace 192.168.xx.x with your Plex server IP
## 3. These rules should be placed BEFORE any drop rules
##
## ═══════════════════════════════════════════════════════════════════════

## BACKUP FIRST!
/export file=backup_before_plex_filter

## ═══════════════════════════════════════════════════════════════════════
## INPUT CHAIN - Allow connections TO MikroTik
## ═══════════════════════════════════════════════════════════════════════
## This allows initial SYN packets to reach the router
/ip firewall filter add \
  chain=input \
  action=accept \
  protocol=tcp \
  in-interface=INTERFACE_WAN \
  dst-port=32400 \
  place-before=0 \
  comment="Plex External - Allow Input"

## ═══════════════════════════════════════════════════════════════════════
## FORWARD CHAIN - Allow forwarding TO Plex server
## ═══════════════════════════════════════════════════════════════════════
## This allows packets to be forwarded from WAN to Plex server
/ip firewall filter add \
  chain=forward \
  action=accept \
  protocol=tcp \
  dst-address=192.168.xx.x \
  in-interface=INTERFACE_WAN \
  dst-port=32400 \
  place-before=0 \
  comment="Plex External - Allow Forward to Server"

## ═══════════════════════════════════════════════════════════════════════
## NOTES
## ═══════════════════════════════════════════════════════════════════════
##
## place-before=0 ensures these rules are at the TOP of the chain
## This is CRITICAL - they must be before any drop/reject rules
##
## If you have existing drop rules, verify placement:
## /ip firewall filter print
##
## The accept rules MUST have lower numbers (execute first)
##
## ═══════════════════════════════════════════════════════════════════════
## VERIFICATION
## ═══════════════════════════════════════════════════════════════════════
:put "=== Filter Rules Added ==="
/ip firewall filter print where dst-port=32400
:put ""
:put "Verify rule order - accept rules should be BEFORE drop rules!"
