#!/bin/bash
# ╔══════════════════════════════════════════════════════════════╗
# ║     Star-Talk — Tor Status for Waybar                      ║
# ╚══════════════════════════════════════════════════════════════╝
#
# Returns JSON for waybar custom/tor-status module.
# Checks: Tor daemon running, SOCKS port open, circuit established.

TOR_SOCKS="127.0.0.1:9050"
TOR_CONTROL="127.0.0.1:9051"

# Check if Tor is running
if ! pgrep -x tor >/dev/null 2>&1; then
    echo '{"text": " TOR OFF ", "class": "tor-off", "tooltip": "Tor daemon is not running\nStart with: sudo tor &"}'
    exit 0
fi

# Check SOCKS port
if curl -s --socks5-hostname "$TOR_SOCKS" https://check.torproject.org/api/ip 2>/dev/null | grep -q '"IsTor":true'; then
    echo '{"text": " TOR ON ", "class": "tor-on", "tooltip": "Tor is running and connected\nSOCKS: 127.0.0.1:9050\nUse: torsocks <command>"}'
else
    echo '{"text": " TOR ... ", "class": "tor-connecting", "tooltip": "Tor is starting up / connecting to the network"}'
fi
