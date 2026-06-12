#!/bin/bash
# ╔══════════════════════════════════════════════════════════════╗
# ║     Star-Talk / 星语 — 21-assemble-rootfs.sh              ║
# ║     Copy configs + built packages to rootfs staging area   ║
# ╚══════════════════════════════════════════════════════════════╝
set -euo pipefail
source "$(dirname "$0")/utils.sh"

PHASE="21"
START_TIME=$(date +%s)
step "Phase ${PHASE}: Assembling root filesystem"

# ── Create usr-merge symlinks ────────────────────────────────────
step "Creating usr-merge layout..."

for d in bin sbin lib lib64; do
    [ -L "$ROOTFS_DIR/$d" ] && rm -f "$ROOTFS_DIR/$d"
    [ ! -e "$ROOTFS_DIR/$d" ] && ln -sf "usr/$d" "$ROOTFS_DIR/$d"
done

# ── Copy system configuration ────────────────────────────────────
step "Installing system configuration files..."

# inittab
cp "$CONFIGS_DIR/inittab" "$ROOTFS_DIR/etc/inittab"

# fstab
cp "$CONFIGS_DIR/fstab" "$ROOTFS_DIR/etc/fstab"

# hostname
cp "$CONFIGS_DIR/hostname" "$ROOTFS_DIR/etc/hostname"

# passwd, group
cp "$CONFIGS_DIR/passwd" "$ROOTFS_DIR/etc/passwd"
cp "$CONFIGS_DIR/group" "$ROOTFS_DIR/etc/group"

# Shadow file (empty passwords for live system)
cat > "$ROOTFS_DIR/etc/shadow" << 'EOF'
root::1::::::
startalk::1::::::
tor:!::1::::::
i2p:!::1::::::
EOF

# profile
cp "$CONFIGS_DIR/profile" "$ROOTFS_DIR/etc/profile"

# bash.bashrc
cp "$CONFIGS_DIR/bash.bashrc" "$ROOTFS_DIR/etc/bash.bashrc"

# ── Init scripts ─────────────────────────────────────────────────
step "Installing init scripts..."
cp "$CONFIGS_DIR/rcS" "$ROOTFS_DIR/etc/init.d/rcS"
cp "$CONFIGS_DIR/rcK" "$ROOTFS_DIR/etc/init.d/rcK"
chmod +x "$ROOTFS_DIR/etc/init.d/rcS"
chmod +x "$ROOTFS_DIR/etc/init.d/rcK"

# ── Session launcher ─────────────────────────────────────────────
step "Installing session launcher..."
cp "$CONFIGS_DIR/startalk-session" "$ROOTFS_DIR/usr/local/bin/startalk-session"
chmod +x "$ROOTFS_DIR/usr/local/bin/startalk-session"

# ── User home directory ────────────────────────────────────────
step "Setting up user home directory..."

# .bash_profile
cp "$CONFIGS_DIR/bash_profile" "$ROOTFS_DIR/home/startalk/.bash_profile"
chmod +x "$ROOTFS_DIR/home/startalk/.bash_profile"

# Status scripts
mkdir -p "$ROOTFS_DIR/home/startalk/bin"
cp "$CONFIGS_DIR/tor-status.sh" "$ROOTFS_DIR/home/startalk/bin/tor-status.sh"
cp "$CONFIGS_DIR/i2p-status.sh" "$ROOTFS_DIR/home/startalk/bin/i2p-status.sh"
chmod +x "$ROOTFS_DIR/home/startalk/bin/tor-status.sh"
chmod +x "$ROOTFS_DIR/home/startalk/bin/i2p-status.sh"

# ── Desktop configuration ────────────────────────────────────────
step "Installing desktop configuration files..."

# Niri
mkdir -p "$ROOTFS_DIR/home/startalk/.config/niri"
cp "$CONFIGS_DIR/niri/config.kdl" "$ROOTFS_DIR/home/startalk/.config/niri/config.kdl"

# Waybar
mkdir -p "$ROOTFS_DIR/home/startalk/.config/waybar"
cp "$CONFIGS_DIR/waybar/config" "$ROOTFS_DIR/home/startalk/.config/waybar/config"
cp "$CONFIGS_DIR/waybar/style.css" "$ROOTFS_DIR/home/startalk/.config/waybar/style.css"

# Wofi
mkdir -p "$ROOTFS_DIR/home/startalk/.config/wofi"
cp "$CONFIGS_DIR/wofi/config" "$ROOTFS_DIR/home/startalk/.config/wofi/config"
cp "$CONFIGS_DIR/wofi/style.css" "$ROOTFS_DIR/home/startalk/.config/wofi/style.css"

# Foot
mkdir -p "$ROOTFS_DIR/home/startalk/.config/foot"
cp "$CONFIGS_DIR/foot/foot.ini" "$ROOTFS_DIR/home/startalk/.config/foot/foot.ini"

# ── Wayland session entry ────────────────────────────────────────
mkdir -p "$ROOTFS_DIR/usr/share/wayland-sessions"
cat > "$ROOTFS_DIR/usr/share/wayland-sessions/star-talk.desktop" << 'EOF'
[Desktop Entry]
Name=Star-Talk (Niri)
Name[zh_CN]=星语 (Niri)
Comment=Star-Talk scrollable-tiling Wayland session
Exec=/usr/local/bin/startalk-session
Type=Application
DesktopNames=niri;Star-Talk;
EOF

# ── Set ownership/permissions ────────────────────────────────────
step "Setting permissions..."

# Make everything owned by root initially (the live system will handle it)
chmod 755 "$ROOTFS_DIR/etc/init.d/rcS"
chmod 755 "$ROOTFS_DIR/etc/init.d/rcK"
chmod 755 "$ROOTFS_DIR/usr/local/bin/startalk-session"

# ── Rootfs size summary ──────────────────────────────────────────
info "Rootfs size summary:"
du -sh "$ROOTFS_DIR" 2>/dev/null || true
info "Top-level directories:"
du -sh "$ROOTFS_DIR/"*/ 2>/dev/null | sort -rh | head -10 || true

cd "$PROJECT_ROOT"
build_summary "$PHASE" "$START_TIME"
