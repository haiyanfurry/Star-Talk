#!/bin/bash
# ╔══════════════════════════════════════════════════════════════╗
# ║     Star-Talk / 星语 — 08-audio.sh                        ║
# ║     Build PipeWire + wireplumber                          ║
# ╚══════════════════════════════════════════════════════════════╝
set -euo pipefail
source "$(dirname "$0")/utils.sh"

PHASE="08"
START_TIME=$(date +%s)
step "Phase ${PHASE}: Building audio stack"

# ── PipeWire ─────────────────────────────────────────────────────
step "Building PipeWire 1.4.2"
PW_DIR="$BUILD_DIR/pipewire-1.4.2"
if [ ! -f "$ROOTFS_DIR/usr/bin/pipewire" ]; then
    extract_to "$SOURCES_DIR/pipewire-1.4.2.tar.gz" "$(dirname "$PW_DIR")"
    cd "$PW_DIR"
    meson setup build --prefix=/usr \
        -Dsystemd=disabled \
        -Dpipewire-alsa=disabled \
        -Dpipewire-jack=disabled \
        -Dsession-managers=[] \
        -Dexamples=disabled \
        -Dtests=disabled \
        -Dudevrulesdir=/usr/lib/udev/rules.d \
        -Dvideotestsrc=disabled \
        -Dvolume=disabled \
        -Dbluez5=disabled \
        -Dvulkan=disabled \
        -Dlibcamera=disabled \
        -Droc=disabled \
        -Davb=disabled
    ninja -C build -j"$JOBS"
    DESTDIR="$ROOTFS_DIR" ninja -C build install
    success "PipeWire: installed"
else
    info "PipeWire: already installed"
fi

# ── WirePlumber ──────────────────────────────────────────────────
step "Building WirePlumber 0.5.8"
WP_DIR="$BUILD_DIR/wireplumber-0.5.8"
if [ ! -f "$ROOTFS_DIR/usr/bin/wireplumber" ]; then
    extract_to "$SOURCES_DIR/wireplumber-0.5.8.tar.gz" "$(dirname "$WP_DIR")"
    cd "$WP_DIR"
    meson setup build --prefix=/usr \
        -Dsystemd=disabled \
        -Dsystem-lua=true \
        -Dtests=false \
        -Ddoc=false
    ninja -C build -j"$JOBS"
    DESTDIR="$ROOTFS_DIR" ninja -C build install
    success "WirePlumber: installed"
else
    info "WirePlumber: already installed"
fi

cd "$PROJECT_ROOT"
build_summary "$PHASE" "$START_TIME"
