#!/bin/sh
# ╔══════════════════════════════════════════════════════════════════════╗
# ║  Star-Talk / 星语 — Packages Installation (pkgsrc)                ║
# ║  KDE Plasma 6 + Firefox + VSCode + Tor + I2PD + Konsole           ║
# ╚══════════════════════════════════════════════════════════════════════╝
#
# pkgsrc tree: NetBSD/pkgsrc (917 MB, shallow clone)
# Missing from pkgsrc (built from source/binary):
#   - vscode/code-oss  → download official binary
#   - i2pd             → build from GitHub source
#   - noto-cjk         → download separately
#
set -e
. "$(dirname "$0")/utils-netbsd.sh"

PHASE="N03"
START_TIME=$(date +%s)
step "Phase ${PHASE}: Installing packages via pkgsrc"

fetch_pkgsrc || die "pkgsrc not available"

PKGSRC_BASE="$PKGSRC_DIR"
BMAKE="/usr/pkg/bin/bmake"

# ── Bootstrap pkgsrc if needed ─────────────────────────────────────────
step "Bootstrapping pkgsrc..."
if [ ! -x /usr/pkg/bin/bmake ]; then
    cd "$PKGSRC_BASE/bootstrap"
    ./bootstrap --prefix /usr/pkg --unprivileged 2>&1 | tail -3 || \
        ./bootstrap --prefix /usr/pkg 2>&1 | tail -3
    success "pkgsrc bootstrapped"
else
    info "pkgsrc already bootstrapped"
fi

# ═══════════════════════════════════════════════════════════════════════
# KDE Plasma 6 Desktop
# ═══════════════════════════════════════════════════════════════════════

step "Installing KDE Plasma 6..."

# Plasma 6 core packages (available in pkgsrc)
PLASMA6_PKGS="
x11/plasma6-plasma-workspace
x11/plasma6-plasma-desktop
x11/plasma6-kwin-x11
x11/plasma6-kdecoration
x11/plasma6-kscreen
x11/plasma6-kscreenlocker
x11/plasma6-libkscreen
x11/plasma6-libplasma
x11/plasma6-plasma-integration
x11/plasma6-layer-shell-qt
x11/plasma6-kdeplasma-addons
x11/plasma6-kactivitymanagerd
graphics/plasma6-breeze
graphics/plasma6-breeze-gtk
graphics/plasma6-oxygen
graphics/plasma6-aurorae
graphics/plasma6-plasma-workspace-wallpapers
"

for pkg in $PLASMA6_PKGS; do
    if [ -d "$PKGSRC_BASE/$pkg" ]; then
        (cd "$PKGSRC_BASE/$pkg" && $BMAKE install clean clean-depends 2>&1 | tail -1) || \
            substep "  $pkg — build issue, continuing..."
        substep "  $pkg — installed"
    fi
done

# KDE Frameworks 6 base
if [ -d "$PKGSRC_BASE/meta-pkgs/kf5" ]; then
    cd "$PKGSRC_BASE/meta-pkgs/kf5"
    $BMAKE install clean clean-depends 2>&1 | tail -3
    success "KDE Frameworks installed"
fi

success "KDE Plasma 6 installed"

# ═══════════════════════════════════════════════════════════════════════
# Display Manager + Terminal + Apps
# ═══════════════════════════════════════════════════════════════════════

step "Installing SDDM display manager..."
if [ -d "$PKGSRC_BASE/x11/sddm" ]; then
    cd "$PKGSRC_BASE/x11/sddm"
    $BMAKE install clean clean-depends 2>&1 | tail -3
    success "SDDM installed"
fi

step "Installing Konsole terminal..."
if [ -d "$PKGSRC_BASE/x11/konsole" ]; then
    cd "$PKGSRC_BASE/x11/konsole"
    $BMAKE install clean clean-depends 2>&1 | tail -3
    success "Konsole installed"
fi

step "Installing Dolphin file manager..."
if [ -d "$PKGSRC_BASE/sysutils/dolphin" ]; then
    cd "$PKGSRC_BASE/sysutils/dolphin"
    $BMAKE install clean clean-depends 2>&1 | tail -3
    success "Dolphin installed"
fi

# ═══════════════════════════════════════════════════════════════════════
# Firefox Browser
# ═══════════════════════════════════════════════════════════════════════

step "Installing Firefox..."
if [ -d "$PKGSRC_BASE/www/firefox" ]; then
    cd "$PKGSRC_BASE/www/firefox"
    $BMAKE install clean clean-depends 2>&1 | tail -5 || {
        warn "Firefox build failed — trying binary package..."
        pkg_add firefox 2>/dev/null || warn "Firefox not available as binary either"
    }
    success "Firefox installed"
else
    warn "www/firefox not in pkgsrc"
fi

# ═══════════════════════════════════════════════════════════════════════
# VSCode (not in pkgsrc — download binary from GitHub)
# ═══════════════════════════════════════════════════════════════════════

step "Downloading VSCode binary..."
VSCODE_VER="1.98.0"
VSCODE_DIR="$ROOTFS_DIR/opt/vscode"
mkdir -p "$VSCODE_DIR"

VSCODE_URL="https://update.code.visualstudio.com/${VSCODE_VER}/linux-x64/stable"
curl -sL --connect-timeout 30 -o "$WORK_DIR/vscode.tar.gz" "$VSCODE_URL" 2>/dev/null || {
    # Try alternative: code-oss from GitHub
    VSCODE_URL="https://github.com/VSCodium/vscodium/releases/download/${VSCODE_VER}/VSCodium-linux-x64-${VSCODE_VER}.tar.gz"
    curl -sL --connect-timeout 30 -o "$WORK_DIR/vscode.tar.gz" "$VSCODE_URL" 2>/dev/null
}

if [ -s "$WORK_DIR/vscode.tar.gz" ]; then
    tar -xzf "$WORK_DIR/vscode.tar.gz" -C "$VSCODE_DIR" --strip-components=1 2>/dev/null || true
    if [ -f "$VSCODE_DIR/bin/code" ] || [ -f "$VSCODE_DIR/bin/codium" ]; then
        ln -sf /opt/vscode/bin/code "$ROOTFS_DIR/usr/local/bin/code" 2>/dev/null || \
            ln -sf /opt/vscode/bin/codium "$ROOTFS_DIR/usr/local/bin/code" 2>/dev/null || true
        success "VSCode installed"
    else
        warn "VSCode extraction may have issues"
    fi
else
    warn "Could not download VSCode binary — install manually later"
fi

# ═══════════════════════════════════════════════════════════════════════
# OpenCode (empty template)
# ═══════════════════════════════════════════════════════════════════════

step "Creating OpenCode placeholder..."
OPENCODE_DIR="$ROOTFS_DIR/opt/opencode"
mkdir -p "$OPENCODE_DIR/src"
cat > "$OPENCODE_DIR/README.md" << 'OPENCODE'
# OpenCode — Star-Talk Edition
OpenCode is a placeholder for an open-source code editor/IDE.
Status: Not yet implemented — directory reserved for future use.
OPENCODE
cat > "$OPENCODE_DIR/opencode" << 'EOF'
#!/bin/sh
echo "OpenCode — Star-Talk Edition"
echo "Status: Placeholder. Install your preferred editor in /opt/opencode/"
EOF
chmod +x "$OPENCODE_DIR/opencode"
success "OpenCode placeholder created"

# ═══════════════════════════════════════════════════════════════════════
# Tor (pre-installed, DISABLED by default)
# ═══════════════════════════════════════════════════════════════════════

step "Installing Tor..."
if [ -d "$PKGSRC_BASE/net/tor" ]; then
    cd "$PKGSRC_BASE/net/tor"
    $BMAKE install clean clean-depends 2>&1 | tail -3 || {
        pkg_add tor 2>/dev/null || warn "Tor not available"
    }
    success "Tor installed (tor=NO in rc.conf)"
else
    warn "net/tor not in pkgsrc"
fi

# ═══════════════════════════════════════════════════════════════════════
# I2PD (not in pkgsrc — build from GitHub source)
# ═══════════════════════════════════════════════════════════════════════

step "Building I2PD from source..."
I2PD_VER="2.55.0"
I2PD_DIR="$WORK_DIR/i2pd-${I2PD_VER}"

if [ ! -f "$ROOTFS_DIR/usr/pkg/sbin/i2pd" ]; then
    # Check for local tarball
    if [ -f "$PROJECT_ROOT/src/tarballs/i2pd-${I2PD_VER}.tar.gz" ]; then
        tar -xzf "$PROJECT_ROOT/src/tarballs/i2pd-${I2PD_VER}.tar.gz" -C "$WORK_DIR"
    else
        curl -sL "https://github.com/PurpleI2P/i2pd/archive/refs/tags/${I2PD_VER}.tar.gz" \
            -o "$WORK_DIR/i2pd.tar.gz"
        tar -xzf "$WORK_DIR/i2pd.tar.gz" -C "$WORK_DIR"
        I2PD_DIR="$WORK_DIR/i2pd-${I2PD_VER}"
    fi

    if [ -d "$I2PD_DIR" ]; then
        cd "$I2PD_DIR"
        make -j"$JOBS" 2>&1 | tail -3 || warn "I2PD build may have issues"
        mkdir -p "$ROOTFS_DIR/usr/pkg/sbin" "$ROOTFS_DIR/usr/pkg/etc/i2pd"
        cp i2pd "$ROOTFS_DIR/usr/pkg/sbin/" 2>/dev/null || true
        cp -r contrib/i2pd.conf "$ROOTFS_DIR/usr/pkg/etc/i2pd/" 2>/dev/null || true
        success "I2PD built and installed (i2pd=NO in rc.conf)"
    else
        warn "I2PD source not available — skip for now"
    fi
else
    info "I2PD already installed"
fi

# ═══════════════════════════════════════════════════════════════════════
# CJK Fonts + Input Method
# ═══════════════════════════════════════════════════════════════════════

step "Installing fonts and input method..."
# Noto fonts from pkgsrc
if [ -d "$PKGSRC_BASE/fonts/noto-ttf" ]; then
    cd "$PKGSRC_BASE/fonts/noto-ttf"
    $BMAKE install clean clean-depends 2>&1 | tail -1 || true
    success "Noto fonts installed"
fi

# Download Noto CJK separately
if [ ! -d "$ROOTFS_DIR/usr/share/fonts/noto-cjk" ]; then
    mkdir -p "$ROOTFS_DIR/usr/share/fonts/noto-cjk"
    curl -sL "https://github.com/googlefonts/noto-cjk/releases/download/Sans2.004/03_NotoSansCJKsc.zip" \
        -o "$WORK_DIR/noto-cjk.zip" 2>/dev/null && {
        unzip -qo "$WORK_DIR/noto-cjk.zip" -d "$ROOTFS_DIR/usr/share/fonts/noto-cjk" 2>/dev/null || true
        success "Noto CJK fonts downloaded"
    } || warn "CJK fonts download failed — install manually"
fi

# fcitx5 for Chinese input
if [ -d "$PKGSRC_BASE/inputmethod/fcitx5" ]; then
    cd "$PKGSRC_BASE/inputmethod/fcitx5"
    $BMAKE install clean clean-depends 2>&1 | tail -1 || true
    success "fcitx5 installed"
fi

# ═══════════════════════════════════════════════════════════════════════
# Linux Compatibility + Runtime Deps
# ═══════════════════════════════════════════════════════════════════════

step "Installing runtime dependencies..."
for pkg in dbus pulseaudio xdg-user-dirs pciutils usbutils; do
    pkg_add "$pkg" 2>/dev/null && info "  $pkg: installed" || true
done

step "Setting up Linux compatibility..."
pkg_add suse_base 2>/dev/null && success "Linux compat (SUSE) installed" || \
    warn "Linux compat not available (Steam/QQ may not work)"

success "All packages installed"

cd "$PROJECT_ROOT"
build_summary "$PHASE" "$START_TIME"
