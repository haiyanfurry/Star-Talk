#!/bin/bash
# ╔══════════════════════════════════════════════════════════════╗
# ║     Star-Talk / 星语 — 20-assemble-initramfs.sh           ║
# ║     Package initramfs into compressed cpio archive         ║
# ╚══════════════════════════════════════════════════════════════╝
set -euo pipefail
source "$(dirname "$0")/utils.sh"

PHASE="20"
START_TIME=$(date +%s)
step "Phase ${PHASE}: Assembling initramfs"

# ── Verify initramfs contents ────────────────────────────────────
step "Verifying initramfs contents..."

if [ ! -x "$INITRAMFS_DIR/init" ]; then
    die "initramfs/init is not executable!"
fi

if [ ! -x "$INITRAMFS_DIR/bin/busybox" ]; then
    die "initramfs/bin/busybox not found! Run 'make busybox' first."
fi

info "init: $(file "$INITRAMFS_DIR/init" | head -1)"
info "busybox: $(file "$INITRAMFS_DIR/bin/busybox" | head -1)"
info "symlinks: $(find "$INITRAMFS_DIR/bin" -type l | wc -l) commands"

# ── Strip binaries to reduce size ────────────────────────────────
step "Stripping binaries..."
strip "$INITRAMFS_DIR/bin/busybox" 2>/dev/null || true

# ── Create cpio archive ──────────────────────────────────────────
step "Creating initramfs cpio archive..."

INITRAMFS_OUT="$OUT_DIR/initramfs.cpio.zst"

cd "$INITRAMFS_DIR"

# Create cpio archive with newc format, then compress with zstd
find . -print0 | cpio --null -ov --format=newc 2>/dev/null | \
    zstd -T"$JOBS" -19 -o "$INITRAMFS_OUT"

if [ $? -eq 0 ] && [ -f "$INITRAMFS_OUT" ]; then
    INITRAMFS_SIZE=$(du -h "$INITRAMFS_OUT" | cut -f1)
    success "initramfs created: $INITRAMFS_OUT ($INITRAMFS_SIZE)"
else
    # Fallback: create uncompressed cpio
    warn "zstd compression failed, creating uncompressed initramfs..."
    find . -print0 | cpio --null -ov --format=newc > "$OUT_DIR/initramfs.cpio"
    INITRAMFS_SIZE=$(du -h "$OUT_DIR/initramfs.cpio" | cut -f1)
    success "initramfs created (uncompressed): $OUT_DIR/initramfs.cpio ($INITRAMFS_SIZE)"
fi

cd "$PROJECT_ROOT"
build_summary "$PHASE" "$START_TIME"
