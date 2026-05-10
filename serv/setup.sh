#!/bin/bash
set -e

if [ "$EUID" -ne 0 ]; then
    echo "Error: Run as root"
    exit 1
fi

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd -P)"
SERVER_DIR="$SCRIPT_DIR"

usage() {
    echo "Usage: $0"
    echo ""
    echo "Domain will be prompted interactively."
    echo ""
    echo "Example:"
    echo "  $0"
    echo "  Domain: mydomain.com"
    exit 1
}

[ $# -gt 0 ] && usage

echo "=== steal-oneself Server Setup ==="
echo ""

read -p "Domain (e.g. mydomain.com): " DOMAIN
if ! echo "$DOMAIN" | grep -qE '^[a-zA-Z0-9]([a-zA-Z0-9.-]*[a-zA-Z0-9])?\.[a-zA-Z]{2,}$'; then
    echo "Error: Invalid domain format"
    exit 1
fi

ADMIN_PATH="admin-$(head -c 8 /dev/urandom | base64 | tr -dc 'a-z0-9' | head -c 8)"
SUB_PATH="sub-$(head -c 8 /dev/urandom | base64 | tr -dc 'a-z0-9' | head -c 8)"
LAMJac_PASSWORD="$(head -c 16 /dev/urandom | base64 | tr -dc 'a-zA-Z0-9' | head -c 16)"

echo "=== steal-oneself Server Setup ==="
echo ""
echo "Domain: $DOMAIN"
echo "Server dir: $SERVER_DIR"
echo "Admin path: /$ADMIN_PATH/"
echo "Sub path: /$SUB_PATH/"
echo ""

echo "[1/7] Generating Lampac password..."
printf '%s' "$LAMJac_PASSWORD" > "$SERVER_DIR/lampac/passwd"
echo "  Done. Password saved to ./lampac/passwd"

echo "[2/7] Enabling BBR..."
echo "net.core.default_qdisc=fq" | tee -a /etc/sysctl.conf
echo "net.ipv4.tcp_congestion_control=bbr" | tee -a /etc/sysctl.conf
sysctl -p >/dev/null 2>&1
echo "  BBR enabled"

echo "[3/7] Updating Caddyfile..."
sed -i "s/example\.com/$DOMAIN/g" "$SERVER_DIR/Caddyfile"
sed -i "s|/admin[^/]*/\*|/$ADMIN_PATH/*|g" "$SERVER_DIR/Caddyfile"
sed -i "s|/sub[^/]*/\*|/$SUB_PATH/*|g" "$SERVER_DIR/Caddyfile"
echo "  Domain and paths updated"

echo "[4/7] Generating Caddy bcrypt hash..."
read -s -p "Enter password for panel admin: " ADMIN_PASSWORD
echo ""
if ! command -v docker &> /dev/null; then
    echo "Error: Docker not found. Install Docker first."
    exit 1
fi
BCRYPT_HASH=$(docker run --rm -i caddy caddy hash-password <<< "$ADMIN_PASSWORD" 2>/dev/null) || {
    echo "Error: Failed to generate bcrypt hash"
    exit 1
}
sed -i "s/\\\$2a\\\$.*/$BCRYPT_HASH/" "$SERVER_DIR/Caddyfile"
echo "  Caddy bcrypt hash updated"

echo "[5/7] Configuring firewall..."
iptables -A INPUT -m state --state RELATED,ESTABLISHED -j ACCEPT
iptables -A INPUT -p tcp --dport 22 -j ACCEPT
iptables -A INPUT -p tcp --dport 80 -j ACCEPT
iptables -A INPUT -p udp --dport 80 -j ACCEPT
iptables -A INPUT -p tcp --dport 443 -j ACCEPT
iptables -A INPUT -p udp --dport 443 -j ACCEPT
iptables -A INPUT -i lo -j ACCEPT
iptables -A OUTPUT -o lo -j ACCEPT
iptables -P INPUT DROP
mkdir -p /etc/network
iptables-save > /etc/network/iptables.rules
echo "  Firewall configured"
echo "  Rules saved to /etc/network/iptables.rules"

echo "[6/7] Starting services..."
mkdir -p "$SERVER_DIR/3x-ui/db"
mkdir -p "$SERVER_DIR/caddy/data"
mkdir -p "$SERVER_DIR/tmp"
cd "$SERVER_DIR" && docker compose up -d
echo "  Services started"

echo "[7/7] Done."
echo ""
echo "=== Setup complete ==="
echo ""
echo "URLs:"
echo "  Panel:  https://$DOMAIN/$ADMIN_PATH/"
echo "  Sub:    https://$DOMAIN/$SUB_PATH/"
echo ""
echo "Credentials:"
echo "  Caddy:  admin / [your password]"
echo "  3x-ui:  admin / admin (change immediately!)"
echo "  Lampac: $LAMJac_PASSWORD"
echo ""
echo "Commands:"
echo "  docker compose up -d    # start"
echo "  docker compose down     # stop"
echo "  docker compose logs -f  # logs"