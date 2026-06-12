#!/bin/bash
# ╔══════════════════════════════════════════════════════════════╗
# ║     Star-Talk / 星语 — 03-busybox.sh                      ║
# ║     Builds BusyBox: static (initramfs) + dynamic (rootfs)  ║
# ╚══════════════════════════════════════════════════════════════╝
set -euo pipefail
source "$(dirname "$0")/utils.sh"

PHASE="03"
START_TIME=$(date +%s)
PKG="busybox"
VER="1.37.0"

step "Phase ${PHASE}: Building ${PKG} ${VER}"

# Use local source if available, otherwise use work/sources/
ARCHIVE="$PROJECT_ROOT/src/tarballs/${PKG}-${VER}.tar.bz2"
[ ! -f "$ARCHIVE" ] && ARCHIVE="$SOURCES_DIR/${PKG}-${VER}.tar.bz2"

BUILD="$BUILD_DIR/${PKG}-${VER}"

# ── Extract (or use pre-extracted src/) ────────────────────────
if [ ! -d "$BUILD" ]; then
    substep "Extracting ${PKG}..."
    # Use pre-extracted source if available
    if [ -d "$PROJECT_ROOT/src/${PKG}-${VER}" ]; then
        cp -a "$PROJECT_ROOT/src/${PKG}-${VER}" "$BUILD_DIR/"
        success "Using pre-extracted source"
    elif [ -f "$ARCHIVE" ]; then
        extract_to "$ARCHIVE" "$(dirname "$BUILD")"
    else
        die "BusyBox source not found. Download to src/tarballs/ or work/sources/"
    fi
fi

# ── Create BusyBox config files if they don't exist ──────────────
BUSYBOX_STATIC_CONFIG="$CONFIGS_DIR/busybox/static.config"
BUSYBOX_DYNAMIC_CONFIG="$CONFIGS_DIR/busybox/dynamic.config"

if [ ! -f "$BUSYBOX_STATIC_CONFIG" ]; then
    substep "Creating default BusyBox static config..."
    cd "$BUILD"
    make defconfig
    # Enable static linking
    sed -i 's/.*CONFIG_STATIC.*/CONFIG_STATIC=y/' .config
    cp .config "$BUSYBOX_STATIC_CONFIG"
fi

if [ ! -f "$BUSYBOX_DYNAMIC_CONFIG" ]; then
    substep "Creating default BusyBox dynamic config..."
    cp "$BUSYBOX_STATIC_CONFIG" "$BUSYBOX_DYNAMIC_CONFIG"
    sed -i 's/CONFIG_STATIC=y/# CONFIG_STATIC is not set/' "$BUSYBOX_DYNAMIC_CONFIG"
fi

# ── Build 1: Static BusyBox for initramfs ────────────────────────
step "Building static BusyBox (for initramfs)"

rm -rf "$BUILD"
extract_to "$ARCHIVE" "$(dirname "$BUILD")"
cd "$BUILD"

cp "$BUSYBOX_STATIC_CONFIG" .config
make oldconfig 2>/dev/null || true
make -j"$JOBS"

# Install to initramfs
make CONFIG_PREFIX="$INITRAMFS_DIR" install

success "Static BusyBox installed to initramfs/"

# ── Build 2: Dynamic BusyBox for rootfs ─────────────────────────
step "Building dynamic BusyBox (for rootfs)"

cd "$BUILD"
make distclean 2>/dev/null || true

cp "$BUSYBOX_DYNAMIC_CONFIG" .config
make oldconfig 2>/dev/null || true
make -j"$JOBS"

# Install to rootfs
make CONFIG_PREFIX="$ROOTFS_DIR" install

success "Dynamic BusyBox installed to rootfs/"

# ── Verify ───────────────────────────────────────────────────────
if [ -f "$INITRAMFS_DIR/bin/busybox" ]; then
    INITRAMFS_BB=$(file "$INITRAMFS_DIR/bin/busybox" 2>/dev/null || echo "ok")
    info "initramfs busybox: $(echo "$INITRAMFS_BB" | grep -o 'statically linked' || echo 'linked')"
else
    die "BusyBox not found in initramfs!"
fi

if [ -f "$ROOTFS_DIR/bin/busybox" ]; then
    info "rootfs busybox: ready"
else
    die "BusyBox not found in rootfs!"
fi

# ── Create essential symlinks in initramfs ───────────────────────
step "Creating initramfs symlinks..."
cd "$INITRAMFS_DIR/bin"

# Remove existing symlinks
find . -type l -exec rm {} \; 2>/dev/null || true

# Create required symlinks
for app in sh mount umount switch_root ls cat grep awk head cut \
           find modprobe mdev blkid clear sleep dmesg echo \
           mkdir rm cp mv sleep reboot halt poweroff; do
    ln -sf busybox "$app" 2>/dev/null || true
done

# Make init executable
chmod +x "$INITRAMFS_DIR/init"
success "Initramfs symlinks created"

cd "$PROJECT_ROOT"
build_summary "$PHASE" "$START_TIME"
