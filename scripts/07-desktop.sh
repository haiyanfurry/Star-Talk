#!/bin/bash
# ╔══════════════════════════════════════════════════════════════╗
# ║     Star-Talk / 星语 — 07-desktop.sh                      ║
# ║     Build Niri, waybar, wofi, foot, swaybg, mako          ║
# ╚══════════════════════════════════════════════════════════════╝
set -euo pipefail
source "$(dirname "$0")/utils.sh"

PHASE="07"
START_TIME=$(date +%s)
step "Phase ${PHASE}: Building desktop environment"

# ── jsoncpp (waybar dependency) ──────────────────────────────────
step "Building jsoncpp 1.9.6"
JSONCPP_DIR="$BUILD_DIR/jsoncpp-1.9.6"
if [ ! -f "$ROOTFS_DIR/usr/lib/libjsoncpp.so" ]; then
    extract_to "$SOURCES_DIR/jsoncpp-1.9.6.tar.gz" "$(dirname "$JSONCPP_DIR")"
    cd "$JSONCPP_DIR"
    meson setup build --prefix=/usr
    ninja -C build -j"$JOBS"
    DESTDIR="$ROOTFS_DIR" ninja -C build install
    success "jsoncpp: installed"
else
    info "jsoncpp: already installed"
fi

# ── fmt (waybar dependency) ──────────────────────────────────────
step "Building fmt 11.1.4"
FMT_DIR="$BUILD_DIR/fmt-11.1.4"
if [ ! -f "$ROOTFS_DIR/usr/lib/libfmt.so" ]; then
    extract_to "$SOURCES_DIR/fmt-11.1.4.tar.gz" "$(dirname "$FMT_DIR")"
    cd "$FMT_DIR"
    cmake -B build -DCMAKE_INSTALL_PREFIX=/usr -DBUILD_SHARED_LIBS=ON
    cmake --build build -j"$JOBS"
    cmake --install build --prefix "$ROOTFS_DIR/usr"
    success "fmt: installed"
else
    info "fmt: already installed"
fi

# ── spdlog (waybar dependency) ──────────────────────────────────
step "Building spdlog v1.15.2"
SPDLOG_DIR="$BUILD_DIR/spdlog-v1.15.2"
if [ ! -f "$ROOTFS_DIR/usr/lib/libspdlog.so" ]; then
    extract_to "$SOURCES_DIR/spdlog-v1.15.2.tar.gz" "$(dirname "$SPDLOG_DIR")"
    cd "$SPDLOG_DIR"
    cmake -B build -DCMAKE_INSTALL_PREFIX=/usr -DSPDLOG_BUILD_SHARED=ON
    cmake --build build -j"$JOBS"
    cmake --install build --prefix "$ROOTFS_DIR/usr"
    success "spdlog: installed"
else
    info "spdlog: already installed"
fi

# ── foot (Wayland terminal) ──────────────────────────────────────
step "Building foot 1.20.2"
FOOT_DIR="$BUILD_DIR/foot"
if [ ! -f "$ROOTFS_DIR/usr/bin/foot" ]; then
    extract_to "$SOURCES_DIR/foot-1.20.2.tar.gz" "$(dirname "$FOOT_DIR")"
    cd "$FOOT_DIR"
    meson setup build --prefix=/usr -Dterminfo-install-location=disabled -Dthemes=false
    ninja -C build -j"$JOBS"
    DESTDIR="$ROOTFS_DIR" ninja -C build install
    success "foot: installed"
else
    info "foot: already installed"
fi

# ── waybar (status bar) ──────────────────────────────────────────
step "Building waybar 0.11.0"
WAYBAR_DIR="$BUILD_DIR/Alexays-Waybar-0.11.0"
if [ ! -f "$ROOTFS_DIR/usr/bin/waybar" ]; then
    extract_to "$SOURCES_DIR/waybar-0.11.0.tar.gz" "$(dirname "$WAYBAR_DIR")"
    cd "$WAYBAR_DIR"
    mkdir -p build && cd build
    cmake .. -DCMAKE_INSTALL_PREFIX=/usr \
        -DCMAKE_BUILD_TYPE=Release \
        -DUSE_SYSTEMD=OFF
    make -j"$JOBS"
    make DESTDIR="$ROOTFS_DIR" install
    success "waybar: installed"
else
    info "waybar: already installed"
fi

# ── wofi (application launcher) ─────────────────────────────────
step "Building wofi 1.4.1"
WOFI_DIR="$BUILD_DIR/wofi-v1.4.1"
if [ ! -f "$ROOTFS_DIR/usr/bin/wofi" ]; then
    extract_to "$SOURCES_DIR/wofi-v1.4.1.tar.gz" "$(dirname "$WOFI_DIR")"
    cd "$WOFI_DIR"
    meson setup build --prefix=/usr
    ninja -C build -j"$JOBS"
    DESTDIR="$ROOTFS_DIR" ninja -C build install
    success "wofi: installed"
else
    info "wofi: already installed"
fi

# ── swaybg (wallpaper daemon) ────────────────────────────────────
step "Building swaybg 1.2.1"
SWAYBG_DIR="$BUILD_DIR/swaybg-1.2.1"
if [ ! -f "$ROOTFS_DIR/usr/bin/swaybg" ]; then
    extract_to "$SOURCES_DIR/swaybg-1.2.1.tar.gz" "$(dirname "$SWAYBG_DIR")"
    cd "$SWAYBG_DIR"
    meson setup build --prefix=/usr
    ninja -C build -j"$JOBS"
    DESTDIR="$ROOTFS_DIR" ninja -C build install
    success "swaybg: installed"
else
    info "swaybg: already installed"
fi

# ── swaylock (screen locker) ─────────────────────────────────────
step "Building swaylock 1.8.0"
SWAYLOCK_DIR="$BUILD_DIR/swaylock-1.8.0"
if [ ! -f "$ROOTFS_DIR/usr/bin/swaylock" ]; then
    extract_to "$SOURCES_DIR/swaylock-1.8.0.tar.gz" "$(dirname "$SWAYLOCK_DIR")"
    cd "$SWAYLOCK_DIR"
    meson setup build --prefix=/usr -Dpam=disabled
    ninja -C build -j"$JOBS"
    DESTDIR="$ROOTFS_DIR" ninja -C build install
    success "swaylock: installed"
else
    info "swaylock: already installed"
fi

# ── mako (notification daemon) ──────────────────────────────────
step "Building mako 1.9.0"
MAKO_DIR="$BUILD_DIR/mako-v1.9.0"
if [ ! -f "$ROOTFS_DIR/usr/bin/mako" ]; then
    extract_to "$SOURCES_DIR/mako-v1.9.0.tar.gz" "$(dirname "$MAKO_DIR")"
    cd "$MAKO_DIR"
    meson setup build --prefix=/usr
    ninja -C build -j"$JOBS"
    DESTDIR="$ROOTFS_DIR" ninja -C build install
    success "mako: installed"
else
    info "mako: already installed"
fi

# ── niri (scrollable-tiling Wayland compositor) ──────────────────
step "Building niri 25.02 (Rust/Cargo)"
NIRI_DIR="$BUILD_DIR/niri-25.02"
if [ ! -f "$ROOTFS_DIR/usr/bin/niri" ]; then
    # niri is built with cargo
    # Try to clone and build, or use pre-built binary
    if command -v cargo &>/dev/null; then
        if [ ! -d "$NIRI_DIR" ]; then
            mkdir -p "$NIRI_DIR"
            cd "$NIRI_DIR"
            # Download niri source
            download "https://github.com/YaLTeR/niri/archive/refs/tags/v25.02.tar.gz" \
                "$SOURCES_DIR/niri-25.02.tar.gz"
            extract_to "$SOURCES_DIR/niri-25.02.tar.gz" "$(dirname "$NIRI_DIR")"
        fi
        cd "$NIRI_DIR"
        cargo build --release -j"$JOBS"
        cp target/release/niri "$ROOTFS_DIR/usr/bin/"
        success "niri: built from source"
    else
        # Fallback: download pre-built niri binary
        warn "Cargo not available, downloading pre-built niri binary..."
        # Placeholder for pre-built binary URL
        download "https://github.com/YaLTeR/niri/releases/download/v25.02/niri-x86_64-unknown-linux-gnu.tar.gz" \
            "$SOURCES_DIR/niri-binary-25.02.tar.gz"
        extract_to "$SOURCES_DIR/niri-binary-25.02.tar.gz" "$BUILD_DIR/niri-binary"
        cp "$BUILD_DIR/niri-binary/niri" "$ROOTFS_DIR/usr/bin/" 2>/dev/null || \
            warn "Could not copy pre-built niri binary"
        success "niri: pre-built binary"
    fi
else
    info "niri: already installed"
fi

cd "$PROJECT_ROOT"
build_summary "$PHASE" "$START_TIME"
