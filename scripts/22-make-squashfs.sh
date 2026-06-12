#!/bin/bash
# ╔══════════════════════════════════════════════════════════════╗
# ║     Star-Talk / 星语 — 22-make-squashfs.sh                ║
# ║     Compress rootfs into SquashFS image (optional)        ║
# ╚══════════════════════════════════════════════════════════════╝
set -euo pipefail
source "$(dirname "$0")/utils.sh"

PHASE="22"
START_TIME=$(date +%s)
step "Phase ${PHASE}: Creating SquashFS image (optional)"

USE_SQUASHFS="${USE_SQUASHFS:-yes}"

if [ "$USE_SQUASHFS" != "yes" ]; then
    info "Skipping SquashFS creation (USE_SQUASHFS=$USE_SQUASHFS)"
    exit 0
fi

SQUASHFS_OUT="$OUT_DIR/rootfs.squashfs"

if ! command -v mksquashfs &>/dev/null; then
    warn "mksquashfs not available, skipping SquashFS creation"
    info "Install squashfs-tools to enable SquashFS compression"
    exit 0
fi

step "Creating SquashFS image from rootfs..."

mksquashfs "$ROOTFS_DIR" "$SQUASHFS_OUT" \
    -comp zstd \
    -Xcompression-level 15 \
    -b 1M \
    -noappend \
    -no-progress \
    -processors "$JOBS"

SQUASHFS_SIZE=$(du -h "$SQUASHFS_OUT" | cut -f1)
ROOTFS_SIZE=$(du -sh "$ROOTFS_DIR" | cut -f1)

success "SquashFS created: $SQUASHFS_OUT ($SQUASHFS_SIZE)"
info "Original rootfs: $ROOTFS_SIZE"
info "Compression ratio: $(echo "scale=1; $(du -sb "$SQUASHFS_OUT" | cut -f1) * 100 / $(du -sb "$ROOTFS_DIR" | cut -f1)" | bc)%"

cd "$PROJECT_ROOT"
build_summary "$PHASE" "$START_TIME"
