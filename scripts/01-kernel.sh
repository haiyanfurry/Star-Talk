#!/bin/bash
# ╔══════════════════════════════════════════════════════════════╗
# ║     Star-Talk / 星语 — 01-kernel.sh                       ║
# ║     Recompile kernel with SQUASHFS + OVERLAY_FS support    ║
# ╚══════════════════════════════════════════════════════════════╝
set -euo pipefail
source "$(dirname "$0")/utils.sh"

PHASE="01"
START_TIME=$(date +%s)

step "Phase ${PHASE}: Recompiling Linux kernel with SQUASHFS + OVERLAY_FS"

cd "$PROJECT_ROOT/linux-7.0.12"

# ── Check current config ─────────────────────────────────────────
if [ ! -f .config ]; then
    die "No .config found in linux-7.0.12/. Run 'make menuconfig' first or restore config"
fi

# ── Enable required features ─────────────────────────────────────
step "Enabling SQUASHFS support..."
./scripts/config -e CONFIG_SQUASHFS
./scripts/config -e CONFIG_SQUASHFS_XZ
./scripts/config -e CONFIG_SQUASHFS_ZSTD
./scripts/config -e CONFIG_SQUASHFS_LZ4
./scripts/config -e CONFIG_SQUASHFS_ZLIB
./scripts/config -e CONFIG_SQUASHFS_FILE_DIRECT

step "Enabling OVERLAY_FS support..."
./scripts/config -e CONFIG_OVERLAY_FS
./scripts/config -e CONFIG_OVERLAY_FS_REDIRECT_DIR
./scripts/config -e CONFIG_OVERLAY_FS_INDEX

# Verify changes
step "Verifying kernel config changes..."
if grep -q "CONFIG_SQUASHFS=y" .config; then
    success "SQUASHFS enabled in kernel config"
else
    warn "SQUASHFS may not have been enabled correctly"
fi

if grep -q "CONFIG_OVERLAY_FS=y" .config; then
    success "OVERLAY_FS enabled in kernel config"
else
    warn "OVERLAY_FS may not have been enabled correctly"
fi

# ── Update config (resolve dependencies automatically) ───────────
step "Running 'make olddefconfig' to resolve dependencies..."
make -j"$JOBS" olddefconfig

# ── Compile the kernel ──────────────────────────────────────────
step "Compiling kernel (${JOBS} jobs)..."
make -j"$JOBS"

# ── Compile modules ─────────────────────────────────────────────
step "Compiling kernel modules..."
make -j"$JOBS" modules

# ── Copy outputs ────────────────────────────────────────────────
step "Copying kernel artifacts to output..."
cp arch/x86/boot/bzImage "$OUT_DIR/bzImage"
cp System.map "$OUT_DIR/System.map"
cp .config "$OUT_DIR/kernel.config"

success "Kernel compiled: $OUT_DIR/bzImage ($(du -h "$OUT_DIR/bzImage" | cut -f1))"

# ── Install modules to rootfs ────────────────────────────────────
step "Installing kernel modules to rootfs..."
make INSTALL_MOD_PATH="$ROOTFS_DIR/usr" modules_install

MODULE_COUNT=$(find "$ROOTFS_DIR/usr/lib/modules" -name "*.ko" 2>/dev/null | wc -l)
success "Installed ${MODULE_COUNT} kernel modules to rootfs"

# ── Verify critical features ─────────────────────────────────────
step "Verifying compiled kernel features..."
KERNEL_STRING=$(strings "$OUT_DIR/bzImage" 2>/dev/null | head -50)

if echo "$KERNEL_STRING" | grep -qi "squashfs"; then
    success "SquashFS support confirmed in kernel binary"
else
    warn "Could not verify SquashFS in bzImage (may be compressed)"
fi

cd "$PROJECT_ROOT"
build_summary "$PHASE" "$START_TIME"
