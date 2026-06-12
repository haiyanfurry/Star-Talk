#!/bin/bash
# ╔══════════════════════════════════════════════════════════════╗
# ║     Star-Talk / 星语 — 01-kernel.sh                       ║
# ║     Download & compile Linux kernel from source            ║
# ╚══════════════════════════════════════════════════════════════╝
set -euo pipefail
source "$(dirname "$0")/utils.sh"

PHASE="01"
START_TIME=$(date +%s)

KERNEL_VER="7.0.12"
KERNEL_MAJOR="7.x"
KERNEL_SRC="$SOURCES_DIR/linux-${KERNEL_VER}.tar.xz"
KERNEL_DIR="$BUILD_DIR/linux-${KERNEL_VER}"
KERNEL_CONFIG="$CONFIGS_DIR/kernel/star-talk.config"

step "Phase ${PHASE}: Downloading & compiling Linux ${KERNEL_VER}"

# ── Get kernel source ────────────────────────────────────────
if [ ! -d "$KERNEL_DIR" ]; then
    KERNEL_TARBALL="$PROJECT_ROOT/src/tarballs/linux-${KERNEL_VER}.tar.xz"

    # Reassemble from chunks if needed
    if [ ! -f "$KERNEL_TARBALL" ]; then
        step "Reassembling kernel source from chunks..."
        cd "$PROJECT_ROOT/src/tarballs"
        ./merge-kernel.sh
        cd "$PROJECT_ROOT"
    fi

    if [ -f "$KERNEL_TARBALL" ]; then
        substep "Extracting kernel source (local tarball)..."
        extract_to "$KERNEL_TARBALL" "$(dirname "$KERNEL_DIR")"
    else
        # Fallback: download from kernel.org
        step "Downloading Linux kernel ${KERNEL_VER}..."
        KERNEL_URL="https://cdn.kernel.org/pub/linux/kernel/v${KERNEL_MAJOR}/linux-${KERNEL_VER}.tar.xz"
        download "$KERNEL_URL" "$KERNEL_SRC"
        extract_to "$KERNEL_SRC" "$(dirname "$KERNEL_DIR")"
    fi
fi
success "Kernel source: $KERNEL_DIR"

# ── Copy our kernel config ──────────────────────────────────────
cd "$KERNEL_DIR"

if [ -f "$KERNEL_CONFIG" ]; then
    cp "$KERNEL_CONFIG" .config
    success "Using Star-Talk kernel config"
else
    warn "No custom config at $KERNEL_CONFIG, generating defconfig..."
    make defconfig
fi

# ── Enable required features ────────────────────────────────────
step "Enabling SQUASHFS + OVERLAY_FS..."
./scripts/config -e CONFIG_SQUASHFS
./scripts/config -e CONFIG_SQUASHFS_XZ
./scripts/config -e CONFIG_SQUASHFS_ZSTD
./scripts/config -e CONFIG_SQUASHFS_LZ4
./scripts/config -e CONFIG_SQUASHFS_ZLIB
./scripts/config -e CONFIG_SQUASHFS_FILE_DIRECT
./scripts/config -e CONFIG_OVERLAY_FS
./scripts/config -e CONFIG_OVERLAY_FS_REDIRECT_DIR

# ── Resolve dependencies ────────────────────────────────────────
step "Resolving config dependencies..."
make -j"$JOBS" olddefconfig

# Save resolved config for reproducibility
mkdir -p "$(dirname "$KERNEL_CONFIG")"
cp .config "$KERNEL_CONFIG"
cp .config "$OUT_DIR/kernel.config"

# ── Compile ─────────────────────────────────────────────────────
step "Compiling kernel (${JOBS} jobs, ~30 min)..."
make -j"$JOBS"

step "Compiling kernel modules..."
make -j"$JOBS" modules

# ── Copy outputs ────────────────────────────────────────────────
cp arch/x86/boot/bzImage "$OUT_DIR/bzImage"
cp System.map "$OUT_DIR/System.map"
success "bzImage: $OUT_DIR/bzImage ($(du -h "$OUT_DIR/bzImage" | cut -f1))"

# ── Install modules to rootfs ──────────────────────────────────
if [ -d "$ROOTFS_DIR" ]; then
    step "Installing kernel modules to rootfs..."
    make INSTALL_MOD_PATH="$ROOTFS_DIR/usr" modules_install
fi

cd "$PROJECT_ROOT"
build_summary "$PHASE" "$START_TIME"
echo ""
info "Kernel source: $(du -sh "$KERNEL_DIR" | cut -f1)"
info "Kernel binary: $(du -sh "$OUT_DIR/bzImage" | cut -f1)"
