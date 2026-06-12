#!/bin/bash
# ╔══════════════════════════════════════════════════════════════╗
# ║     Star-Talk / 星语 — 10-applications.sh                ║
# ║     Download pre-built: Firefox, Steam, Proton, Wine      ║
# ╚══════════════════════════════════════════════════════════════╝
set -euo pipefail
source "$(dirname "$0")/utils.sh"

PHASE="10"
START_TIME=$(date +%s)
step "Phase ${PHASE}: Fetching pre-built applications"

# ── Firefox ─────────────────────────────────────────────────────
step "Downloading Firefox"
if [ ! -f "$ROOTFS_DIR/opt/firefox/firefox" ]; then
    FIREFOX_VER="latest"
    FIREFOX_URL="https://download.mozilla.org/?product=firefox-latest-ssl&os=linux64&lang=zh-CN"
    download "$FIREFOX_URL" "$SOURCES_DIR/firefox.tar.bz2"

    mkdir -p "$ROOTFS_DIR/opt/firefox"
    tar -xjf "$SOURCES_DIR/firefox.tar.bz2" -C "$ROOTFS_DIR/opt/firefox" --strip-components=1

    # Create symlink in PATH
    ln -sf /opt/firefox/firefox "$ROOTFS_DIR/usr/bin/firefox"

    # Create desktop entry
    mkdir -p "$ROOTFS_DIR/usr/share/applications"
    cat > "$ROOTFS_DIR/usr/share/applications/firefox.desktop" << 'EOF'
[Desktop Entry]
Name=Firefox
Name[zh_CN]=火狐浏览器
Comment=Browse the Web
Exec=firefox %u
Icon=firefox
Type=Application
Categories=Network;WebBrowser;
EOF
    success "Firefox: installed to /opt/firefox"
else
    info "Firefox: already installed"
fi

# ── Steam ────────────────────────────────────────────────────────
step "Downloading Steam (bootstrap)"
if [ ! -f "$ROOTFS_DIR/opt/steam/steam" ]; then
    mkdir -p "$ROOTFS_DIR/opt/steam"

    # Download Steam installer
    download "https://repo.steampowered.com/steam/archive/precise/steam_latest.tar.gz" \
        "$SOURCES_DIR/steam_latest.tar.gz"

    tar -xzf "$SOURCES_DIR/steam_latest.tar.gz" -C "$ROOTFS_DIR/opt/steam" --strip-components=1 2>/dev/null || \
        tar -xzf "$SOURCES_DIR/steam_latest.tar.gz" -C "$ROOTFS_DIR/opt/steam"

    # Create symlink
    ln -sf /opt/steam/steam "$ROOTFS_DIR/usr/bin/steam" 2>/dev/null || true

    # Create desktop entry
    cat > "$ROOTFS_DIR/usr/share/applications/steam.desktop" << 'EOF'
[Desktop Entry]
Name=Steam
Comment=Application for managing and playing games on Steam
Exec=steam %U
Icon=steam
Type=Application
Categories=Game;
MimeType=x-scheme-handler/steam;
EOF
    success "Steam: installed to /opt/steam"
else
    info "Steam: already installed"
fi

# ── Proton (Valve's Windows compatibility layer) ─────────────────
step "Downloading Proton GE"
if [ ! -d "$ROOTFS_DIR/opt/proton" ]; then
    mkdir -p "$ROOTFS_DIR/opt/proton"

    # Proton GE latest release URL
    PROTON_GE_URL="https://github.com/GloriousEggroll/proton-ge-custom/releases/download/GE-Proton9-23/GE-Proton9-23.tar.gz"
    download "$PROTON_GE_URL" "$SOURCES_DIR/proton-ge.tar.gz"

    tar -xzf "$SOURCES_DIR/proton-ge.tar.gz" -C "$ROOTFS_DIR/opt/proton"

    # Create compatibilitytools.d directory for Steam
    mkdir -p "$ROOTFS_DIR/home/startalk/.steam/root/compatibilitytools.d"
    ln -sf /opt/proton "$ROOTFS_DIR/home/startalk/.steam/root/compatibilitytools.d/Proton-GE" 2>/dev/null || true

    success "Proton GE: installed to /opt/proton"
else
    info "Proton: already installed"
fi

# ── Wine (Windows compatibility layer, standalone) ───────────────
step "Downloading Wine (optional)"
if [ ! -f "$ROOTFS_DIR/opt/wine/bin/wine" ] && [ ! -f "$ROOTFS_DIR/usr/bin/wine" ]; then
    mkdir -p "$ROOTFS_DIR/opt/wine"
    # WineHQ provides pre-built binaries for various distros
    # We'll use the AppImage or static build for maximum compatibility
    WINE_URL="https://github.com/Kron4ek/Wine-Builds/releases/download/10.2/wine-10.2-amd64.tar.xz"
    download "$WINE_URL" "$SOURCES_DIR/wine-amd64.tar.xz"

    tar -xJf "$SOURCES_DIR/wine-amd64.tar.xz" -C "$ROOTFS_DIR/opt/wine" --strip-components=1
    ln -sf /opt/wine/bin/wine "$ROOTFS_DIR/usr/bin/wine" 2>/dev/null || true
    ln -sf /opt/wine/bin/wine64 "$ROOTFS_DIR/usr/bin/wine64" 2>/dev/null || true
    success "Wine: installed to /opt/wine"
else
    info "Wine: already installed"
fi

# ── CJK Fonts ────────────────────────────────────────────────────
step "Downloading CJK Fonts (Noto Sans CJK)"
if [ ! -d "$ROOTFS_DIR/usr/share/fonts/noto-cjk" ]; then
    mkdir -p "$ROOTFS_DIR/usr/share/fonts"
    FONT_URL="https://github.com/googlefonts/noto-cjk/releases/download/Sans2.004/03_NotoSansCJKsc.zip"
    download "$FONT_URL" "$SOURCES_DIR/noto-cjk.zip"
    mkdir -p "$ROOTFS_DIR/usr/share/fonts/noto-cjk"
    unzip -qo "$SOURCES_DIR/noto-cjk.zip" -d "$ROOTFS_DIR/usr/share/fonts/noto-cjk" 2>/dev/null || \
        warn "Could not extract CJK font zip (may need unzip)"
    success "CJK Fonts: installed"
else
    info "CJK Fonts: already installed"
fi

cd "$PROJECT_ROOT"
build_summary "$PHASE" "$START_TIME"
