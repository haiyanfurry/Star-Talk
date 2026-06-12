#!/bin/bash
# ╔══════════════════════════════════════════════════════════════╗
# ║     Star-Talk / 星語 — User .bash_profile                  ║
# ╚══════════════════════════════════════════════════════════════╝
#
# Sourced by login shell for user 'startalk'.
# On tty1, auto-launches the Star-Talk Wayland desktop session.

# ── Environment ──────────────────────────────────────────────────
export EDITOR=nano
export VISUAL=nano
export PAGER=less
export BROWSER=firefox
export TERMINAL=foot

# Wayland environment
export XDG_SESSION_TYPE=wayland
export XDG_CURRENT_DESKTOP=niri
export MOZ_ENABLE_WAYLAND=1
export QT_QPA_PLATFORM=wayland
export GDK_BACKEND=wayland
export SDL_VIDEODRIVER=wayland
export CLUTTER_BACKEND=wayland

# GTK theme (Catppuccin Mocha)
export GTK_THEME=Adwaita:dark

# ── Path ─────────────────────────────────────────────────────────
export PATH="$HOME/bin:$HOME/.local/bin:$PATH"

# ── Aliases ──────────────────────────────────────────────────────
alias ls='ls --color=auto'
alias ll='ls -la'
alias la='ls -A'
alias l='ls -CF'
alias grep='grep --color=auto'
alias tor-status='curl -s http://127.0.0.1:9051/ 2>/dev/null || echo "Tor not running"'
alias i2p-status='curl -s http://127.0.0.1:7070/ 2>/dev/null || echo "I2P not running"'
alias steam-proton='STEAM_COMPAT_DATA_PATH=~/.proton steam'
alias update-mdev='mdev -s'

# ── Auto-start desktop on tty1 ──────────────────────────────────
if [ -z "${WAYLAND_DISPLAY:-}" ] && [ "$(tty 2>/dev/null)" = "/dev/tty1" ]; then
    echo ""
    echo "  ┌──────────────────────────────────────────────────────────┐"
    echo "  │  Starting Star-Talk / 星語 Wayland Session...           │"
    echo "  │  Compositor: Niri (scrollable tiling)                   │"
    echo "  │  Press Super+D to launch apps, Super+Q to close         │"
    echo "  └──────────────────────────────────────────────────────────┘"
    echo ""
    exec /usr/local/bin/startalk-session
fi

# ── Greeting ─────────────────────────────────────────────────────
if [ -z "${WAYLAND_DISPLAY:-}" ]; then
    echo ""
    echo "  Welcome to Star-Talk / 星語 — Linux Live Environment"
    echo "  Type 'startalk-session' to launch the desktop."
    echo "  Type 'startx' for X11 fallback (if installed)."
    echo ""
fi
