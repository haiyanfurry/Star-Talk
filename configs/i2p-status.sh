#!/bin/bash
# ╔══════════════════════════════════════════════════════════════╗
# ║     Star-Talk — I2P Status for Waybar                      ║
# ╚══════════════════════════════════════════════════════════════╝
#
# Returns JSON for waybar custom/i2p-status module.

I2P_CONSOLE="127.0.0.1:7070"
I2P_PROXY="127.0.0.1:4444"

# Check if i2pd is running
if ! pgrep -x i2pd >/dev/null 2>&1; then
    echo '{"text": " I2P OFF ", "class": "i2p-off", "tooltip": "I2P daemon is not running\nStart with: sudo i2pd &"}'
    exit 0
fi

# Quick check if console is reachable
if curl -s --connect-timeout 2 "http://$I2P_CONSOLE" >/dev/null 2>&1; then
    echo '{"text": " I2P ON ", "class": "i2p-on", "tooltip": "I2P router is running\nHTTP Proxy: 127.0.0.1:4444\nConsole: http://127.0.0.1:7070"}'
else
    echo '{"text": " I2P ... ", "class": "i2p-connecting", "tooltip": "I2P is starting up / tunnelling"}'
fi
