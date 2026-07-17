#!/bin/sh
# ╔══════════════════════════════════════════════════════════════════════╗
# ║  Star-Talk / 星语 — Desktop Configuration                         ║
# ║  KDE Plasma, SDDM, Wallpaper, System configs                      ║
# ╚══════════════════════════════════════════════════════════════════════╝
set -e
. "$(dirname "$0")/utils-netbsd.sh"

PHASE="N04"
START_TIME=$(date +%s)
step "Phase ${PHASE}: Configuring KDE Plasma Desktop"

# ── Install star-talk branding and wallpapers ─────────────────────────
step "Installing Star-Talk branding..."

# Wallpaper
WALLPAPER_SRC="$PROJECT_ROOT/56616da29a9bd0e3038e2490aeea4aae.png"
WALLPAPER_DEST="$ROOTFS_DIR/usr/local/share/star-talk/wallpapers/star-talk.png"

if [ -f "$WALLPAPER_SRC" ]; then
    mkdir -p "$(dirname "$WALLPAPER_DEST")"
    cp "$WALLPAPER_SRC" "$WALLPAPER_DEST"
    success "Wallpaper installed: $(basename "$WALLPAPER_SRC")"
else
    warn "Wallpaper not found at $WALLPAPER_SRC"
    warn "Place a PNG file in the project root named: star-talk-wallpaper.png"
fi

# ── Install system configuration files ────────────────────────────────
step "Installing NetBSD system configurations..."

# rc.conf
cp "$CONFIGS_DIR/netbsd/etc/rc.conf" "$ROOTFS_DIR/etc/rc.conf"
success "rc.conf installed"

# rc.d scripts
mkdir -p "$ROOTFS_DIR/etc/rc.d"
for script in startalk-splash tor i2pd; do
    if [ -f "$CONFIGS_DIR/netbsd/etc/rc.d/${script}" ]; then
        cp "$CONFIGS_DIR/netbsd/etc/rc.d/${script}" "$ROOTFS_DIR/etc/rc.d/${script}"
        chmod +x "$ROOTFS_DIR/etc/rc.d/${script}"
        info "  rc.d/${script}: installed"
    fi
done

# boot.cfg
mkdir -p "$ROOTFS_DIR/boot"
cp "$CONFIGS_DIR/netbsd/etc/boot.cfg" "$ROOTFS_DIR/boot.cfg"
cp "$CONFIGS_DIR/netbsd/etc/boot.cfg" "$ROOTFS_DIR/etc/boot.cfg" 2>/dev/null || true
success "boot.cfg installed"

# wscons.conf
cp "$CONFIGS_DIR/netbsd/etc/wscons.conf" "$ROOTFS_DIR/etc/wscons.conf"
success "wscons.conf installed"

# ttys
cp "$CONFIGS_DIR/netbsd/etc/ttys" "$ROOTFS_DIR/etc/ttys"
success "ttys installed"

# ── Install KDE Plasma configuration ──────────────────────────────────
step "Installing KDE Plasma desktop configuration..."

# Plasma setup script
mkdir -p "$ROOTFS_DIR/usr/local/sbin"
cp "$CONFIGS_DIR/kde/plasma-setup.sh" "$ROOTFS_DIR/usr/local/sbin/star-talk-plasma-setup"
chmod +x "$ROOTFS_DIR/usr/local/sbin/star-talk-plasma-setup"
success "Plasma setup script installed"

# ── Install SDDM configuration ────────────────────────────────────────
step "Installing SDDM configuration..."

if [ -f "$CONFIGS_DIR/sddm/sddm.conf" ]; then
    mkdir -p "$ROOTFS_DIR/usr/pkg/etc/sddm.conf.d"
    cp "$CONFIGS_DIR/sddm/sddm.conf" "$ROOTFS_DIR/usr/pkg/etc/sddm.conf.d/star-talk.conf"
    success "SDDM config installed"
fi

if [ -d "$CONFIGS_DIR/sddm/star-talk-theme" ]; then
    mkdir -p "$ROOTFS_DIR/usr/pkg/share/sddm/themes/star-talk"
    cp -r "$CONFIGS_DIR/sddm/star-talk-theme/"* "$ROOTFS_DIR/usr/pkg/share/sddm/themes/star-talk/"
    success "SDDM theme installed"
fi

# ── Install installer script ──────────────────────────────────────────
step "Installing hard disk installer..."

mkdir -p "$ROOTFS_DIR/usr/local/sbin"
cp "$CONFIGS_DIR/netbsd/install/install.sh" "$ROOTFS_DIR/usr/local/sbin/star-talk-install"
chmod +x "$ROOTFS_DIR/usr/local/sbin/star-talk-install"
success "Installer script installed"

# ── Create user home skeleton ─────────────────────────────────────────
step "Creating user home directory skeleton..."

SKEL_DIR="$ROOTFS_DIR/usr/local/share/star-talk/skel"
mkdir -p "$SKEL_DIR"/{.config,.local/share/wallpapers,.local/bin,Desktop,Documents,Downloads,Music,Pictures,Videos}

# Copy wallpaper to skel
if [ -f "$WALLPAPER_DEST" ]; then
    cp "$WALLPAPER_DEST" "$SKEL_DIR/.local/share/wallpapers/star-talk.png"
fi

# Create .profile with i18n settings
cat > "$SKEL_DIR/.profile" << 'PROFILE'
# Star-Talk / 星语 — User .profile
export LANG=zh_CN.UTF-8
export LC_ALL=zh_CN.UTF-8
export LC_CTYPE=zh_CN.UTF-8
export EDITOR=kate
export VISUAL=kate
export BROWSER=firefox
export TERMINAL=konsole

# PATH
export PATH="$HOME/.local/bin:/usr/pkg/bin:/usr/local/bin:$PATH"

# Platform info
echo ""
echo "  ★ Star-Talk / 星语 — NetBSD $(uname -r) | KDE Plasma"
echo ""
PROFILE

success "User skeleton created"

# ── Post-install hooks ────────────────────────────────────────────────
mkdir -p "$ROOTFS_DIR/usr/local/etc/star-talk"
cat > "$ROOTFS_DIR/usr/local/etc/star-talk/version" << VER
STAR_TALK_VERSION="2.0.0"
STAR_TALK_CODENAME="NetBSD KDE"
STAR_TALK_KERNEL="NetBSD ${NETBSD_VER}"
STAR_TALK_DESKTOP="KDE Plasma 5"
STAR_TALK_BUILD_DATE="$(date '+%Y-%m-%d %H:%M:%S')"
STAR_TALK_ARCH="${NETBSD_ARCH}"
VER

success "Star-Talk version info written"

cd "$PROJECT_ROOT"
build_summary "$PHASE" "$START_TIME"
