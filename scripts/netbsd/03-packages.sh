#!/bin/sh
# ╔══════════════════════════════════════════════════════════════════════╗
# ║  Star-Talk / 星语 — Packages Installation                         ║
# ║  NOTE: pkgsrc packages must be compiled ON NetBSD, not Linux.     ║
# ║  This script creates a first-boot setup script for NetBSD.        ║
# ╚══════════════════════════════════════════════════════════════════════╝
set -e
. "$(dirname "$0")/utils-netbsd.sh"

PHASE="N03"
START_TIME=$(date +%s)
step "Phase ${PHASE}: Preparing package installation for NetBSD"

# ── Detect if we're on NetBSD ──────────────────────────────────────────
ON_NETBSD="no"
if [ "$(uname -s)" = "NetBSD" ]; then
    ON_NETBSD="yes"
fi

if [ "$ON_NETBSD" = "no" ]; then
    warn "Running on $(uname -s), not NetBSD."
    warn "pkgsrc packages CANNOT be cross-compiled from Linux."
    info "Creating first-boot setup script instead..."
fi

# ── Create first-boot package install script ────────────────────────────
SETUP_SCRIPT="$ROOTFS_DIR/usr/local/sbin/star-talk-firstboot"
mkdir -p "$(dirname "$SETUP_SCRIPT")"

cat > "$SETUP_SCRIPT" << 'FIRSTBOOT'
#!/bin/sh
# ╔══════════════════════════════════════════════════════════════════════╗
# ║  Star-Talk / 星语 — First Boot Setup                              ║
# ║  Runs once on first NetBSD boot to install all packages.          ║
# ╚══════════════════════════════════════════════════════════════════════╝

set -e
PKGSRC=/usr/pkgsrc

echo "╔══════════════════════════════════════════════════════════════╗"
echo "║  Star-Talk / 星语 — First Boot Package Installation        ║"
echo "╚══════════════════════════════════════════════════════════════╝"
echo ""
echo "This will install KDE Plasma 6, Firefox, Tor, and other packages."
echo "Time estimate: 4-12 hours depending on CPU."
echo ""

# Ensure pkgsrc is available
if [ ! -f "$PKGSRC/Makefile" ]; then
    echo "ERROR: pkgsrc not found at $PKGSRC"
    echo "Please clone: cd /usr && git clone --depth 1 https://github.com/NetBSD/pkgsrc"
    exit 1
fi

# Bootstrap pkgsrc
if [ ! -x /usr/pkg/bin/bmake ]; then
    echo "[1/5] Bootstrapping pkgsrc..."
    cd $PKGSRC/bootstrap
    ./bootstrap --prefix /usr/pkg
    echo "      Done."
else
    echo "[1/5] pkgsrc already bootstrapped."
fi

echo "[2/5] Installing KDE Plasma 6 + SDDM..."
cd $PKGSRC/x11/plasma6-plasma-desktop && /usr/pkg/bin/bmake install clean clean-depends
cd $PKGSRC/x11/plasma6-plasma-workspace && /usr/pkg/bin/bmake install clean clean-depends
cd $PKGSRC/x11/plasma6-kwin-x11 && /usr/pkg/bin/bmake install clean clean-depends
cd $PKGSRC/graphics/plasma6-breeze && /usr/pkg/bin/bmake install clean clean-depends
cd $PKGSRC/x11/sddm && /usr/pkg/bin/bmake install clean clean-depends
cd $PKGSRC/x11/konsole && /usr/pkg/bin/bmake install clean clean-depends
echo "      KDE Plasma 6 installed."

echo "[3/5] Installing Firefox..."
cd $PKGSRC/www/firefox && /usr/pkg/bin/bmake install clean clean-depends
echo "      Firefox installed."

echo "[4/5] Installing Tor..."
cd $PKGSRC/net/tor && /usr/pkg/bin/bmake install clean clean-depends
echo "      Tor installed (disabled by default)."

echo "[5/5] Installing fonts and input method..."
cd $PKGSRC/fonts/noto-ttf && /usr/pkg/bin/bmake install clean clean-depends
cd $PKGSRC/inputmethod/fcitx5 && /usr/pkg/bin/bmake install clean clean-depends
echo "      Fonts installed."

# Configure SDDM to start at boot
echo 'sddm=YES' >> /etc/rc.conf

# Mark first boot as complete
mv /usr/local/sbin/star-talk-firstboot /usr/local/sbin/star-talk-firstboot.done
echo ""
echo "╔══════════════════════════════════════════════════════════════╗"
echo "║  Installation complete! Starting SDDM...                   ║"
echo "╚══════════════════════════════════════════════════════════════╝"
service sddm start
FIRSTBOOT
chmod +x "$SETUP_SCRIPT"

# ── Also create script to download VSCode binary on NetBSD ─────────────
VSCODE_SCRIPT="$ROOTFS_DIR/usr/local/sbin/star-talk-install-vscode"
cat > "$VSCODE_SCRIPT" << 'VSCODESH'
#!/bin/sh
echo "Downloading VSCode..."
VSCODE_URL="https://update.code.visualstudio.com/latest/linux-x64/stable"
fetch -o /tmp/vscode.tar.gz "$VSCODE_URL" 2>/dev/null || \
    curl -sL -o /tmp/vscode.tar.gz "$VSCODE_URL" 2>/dev/null || {
    echo "ERROR: Could not download VSCode."
    echo "Try manually: https://code.visualstudio.com/download"
    exit 1
}
mkdir -p /opt/vscode
tar -xzf /tmp/vscode.tar.gz -C /opt/vscode --strip-components=1
ln -sf /opt/vscode/bin/code /usr/local/bin/code
echo "VSCode installed to /opt/vscode"
rm -f /tmp/vscode.tar.gz
VSCODESH
chmod +x "$VSCODE_SCRIPT"

# ── Create I2PD build script ───────────────────────────────────────────
I2PD_SCRIPT="$ROOTFS_DIR/usr/local/sbin/star-talk-install-i2pd"
cat > "$I2PD_SCRIPT" << 'I2PDSH'
#!/bin/sh
echo "Building I2PD from source..."
I2PD_VER="2.55.0"
fetch -o /tmp/i2pd.tar.gz "https://github.com/PurpleI2P/i2pd/archive/refs/tags/${I2PD_VER}.tar.gz" 2>/dev/null || \
    curl -sL -o /tmp/i2pd.tar.gz "https://github.com/PurpleI2P/i2pd/archive/refs/tags/${I2PD_VER}.tar.gz" 2>/dev/null || {
    echo "ERROR: Could not download I2PD source."
    exit 1
}
cd /tmp
tar -xzf i2pd.tar.gz
cd i2pd-${I2PD_VER}
make -j$(sysctl -n hw.ncpu)
cp i2pd /usr/pkg/sbin/
mkdir -p /usr/pkg/etc/i2pd
cp contrib/i2pd.conf /usr/pkg/etc/i2pd/
echo "I2PD installed (i2pd=NO in rc.conf)"
cd / && rm -rf /tmp/i2pd-${I2PD_VER} /tmp/i2pd.tar.gz
I2PDSH
chmod +x "$I2PD_SCRIPT"

# ── Create OpenCode placeholder ────────────────────────────────────────
OPENCODE_DIR="$ROOTFS_DIR/opt/opencode"
mkdir -p "$OPENCODE_DIR/src"
cat > "$OPENCODE_DIR/README.md" << 'OCREADME'
# OpenCode — Star-Talk Edition
Placeholder for an open-source code editor. Not yet implemented.
OCREADME
cat > "$OPENCODE_DIR/opencode" << 'OCEXEC'
#!/bin/sh
echo "OpenCode — Star-Talk Edition (placeholder)"
echo "Install your preferred editor:"
echo "  vscode:  star-talk-install-vscode"
echo "  vim:     pkg_add vim"
echo "  emacs:   pkg_add emacs"
OCEXEC
chmod +x "$OPENCODE_DIR/opencode"

# ── Add firstboot to rc.local ──────────────────────────────────────────
mkdir -p "$ROOTFS_DIR/etc"
cat >> "$ROOTFS_DIR/etc/rc.local" << 'RCLOCAL'

# Star-Talk first boot setup (runs once)
if [ -x /usr/local/sbin/star-talk-firstboot ]; then
    echo "Running Star-Talk first-boot setup..."
    /usr/local/sbin/star-talk-firstboot
fi
RCLOCAL

# ── Copy configs to rootfs ─────────────────────────────────────────────
mkdir -p "$ROOTFS_DIR/etc/rc.d"
cp "$CONFIGS_DIR/netbsd/etc/rc.d/tor" "$ROOTFS_DIR/etc/rc.d/tor" 2>/dev/null || true
cp "$CONFIGS_DIR/netbsd/etc/rc.d/i2pd" "$ROOTFS_DIR/etc/rc.d/i2pd" 2>/dev/null || true
cp "$CONFIGS_DIR/netbsd/etc/rc.d/startalk-splash" "$ROOTFS_DIR/etc/rc.d/startalk-splash" 2>/dev/null || true
chmod +x "$ROOTFS_DIR/etc/rc.d/"* 2>/dev/null || true

# ── Copy wallpaper ─────────────────────────────────────────────────────
WALLPAPER_SRC="$PROJECT_ROOT/56616da29a9bd0e3038e2490aeea4aae.png"
WALLPAPER_DEST="$ROOTFS_DIR/usr/local/share/star-talk/wallpapers/star-talk.png"
if [ -f "$WALLPAPER_SRC" ]; then
    mkdir -p "$(dirname "$WALLPAPER_DEST")"
    cp "$WALLPAPER_SRC" "$WALLPAPER_DEST"
    success "Wallpaper installed"
fi

step "Summary:"
info "  star-talk-firstboot       — installs KDE + Firefox + Tor on first boot"
info "  star-talk-install-vscode   — download VSCode binary (run manually)"
info "  star-talk-install-i2pd     — build I2PD from source (run manually)"
info "  OpenCode placeholder       — /opt/opencode/"

touch "$WORK_DIR/.packages-done"
success "Package installation scripts ready for NetBSD first boot"

cd "$PROJECT_ROOT"
build_summary "$PHASE" "$START_TIME"
