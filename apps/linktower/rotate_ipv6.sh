#!/bin/bash
# rotate_ipv6.sh — Force rotation of the host's temporary IPv6 privacy address (RFC 4941)

# CONFIGURATION
# Host physical network interface (e.g., enp2s0)
INTERFACE="enp2s0"

# Check root privileges
if [ "$EUID" -ne 0 ]; then
  echo "Error: this script must be run as root (or with sudo)."
  exit 1
fi

# 1. Fetch active (non-deprecated) temporary IPv6 address(es)
TEMP_IPS=$(ip -6 addr show dev "$INTERFACE" temporary | grep "inet6" | grep -v "deprecated" | awk '{print $2}')

if [ -z "$TEMP_IPS" ]; then
  echo "[-] No active temporary IPv6 address found on $INTERFACE."
  exit 1
fi

for IP in $TEMP_IPS; do
  echo "[+] Deprecating current temporary IPv6 address: $IP"
  # Setting preferred_lft to 0 marks the address as deprecated:
  # existing connections remain intact while new connections use the fresh address.
  ip -6 addr change "$IP" dev "$INTERFACE" preferred_lft 0
done

# 2. Trigger generation of a new temporary IPv6 address by the kernel
echo "[+] Triggering new temporary IPv6 address generation..."
ping6 -c 1 -w 2 ipv6.google.com >/dev/null 2>&1

# 3. Wait briefly and display the newly generated IPv6 address
sleep 1
NEW_IP=$(ip -6 addr show dev "$INTERFACE" temporary | grep "inet6" | grep -v "deprecated" | awk '{print $2}')
echo "[+] New active temporary IPv6 address: $NEW_IP"

# 4. Clean up deprecated temporary IPv6 addresses (optional, keeps the interface tidy)
DEPRECATED_IPS=$(ip -6 addr show dev "$INTERFACE" temporary | grep "deprecated" | awk '{print $2}')
for OLD_DEP_IP in $DEPRECATED_IPS; do
  echo "    -> Removing deprecated IPv6 address: $OLD_DEP_IP"
  ip -6 addr del "$OLD_DEP_IP" dev "$INTERFACE" 2>/dev/null
done
