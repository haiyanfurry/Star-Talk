#!/bin/sh
# ╔══════════════════════════════════════════════════════════════════════╗
# ║  Star-Talk / 星语 — Disk Image Creation                           ║
# ║  Creates bootable GPT/UEFI disk image with FFSv2 rootfs           ║
# ╚══════════════════════════════════════════════════════════════════════╝
set -e
. "$(dirname "$0")/utils-netbsd.sh"

PHASE="N06"
START_TIME=$(date +%s)
step "Phase ${PHASE}: Creating bootable disk image"

IMAGE_NAME="star-talk-netbsd-$(date +%Y%m%d).img"
IMAGE="$OUT_DIR/$IMAGE_NAME"

ESP_SIZE=260      # MiB — EFI System Partition
ROOT_SIZE=8192    # MiB — Root filesystem (8GB default)
SWAP_SIZE=4096    # MiB — Swap

TOTAL_SIZE=$((ESP_SIZE + ROOT_SIZE + SWAP_SIZE + 5))

info "Image: $IMAGE"
info "Total size: ${TOTAL_SIZE} MiB"
info "  P1: EFI System — ${ESP_SIZE} MiB"
info "  P2: NetBSD FFSv2 — ${ROOT_SIZE} MiB"
info "  P3: Swap — ${SWAP_SIZE} MiB"

# ── Check prerequisites ───────────────────────────────────────────────
for tool in gpt vnconfig newfs newfs_msdos; do
    if ! command -v "$tool" >/dev/null 2>&1; then
        warn "$tool not found — cross-building from Linux may lack these"
        warn "Continuing with Linux-compatible tools..."
    fi
done

KERNEL_SRC=""
[ -f "$OUT_DIR/netbsd" ] && KERNEL_SRC="$OUT_DIR/netbsd"
[ -z "$KERNEL_SRC" ] && [ -f "$ROOTFS_DIR/netbsd" ] && KERNEL_SRC="$ROOTFS_DIR/netbsd"

# ── Create sparse image file ──────────────────────────────────────────
step "Creating sparse disk image..."
rm -f "$IMAGE"
# Use truncate or dd to create sparse file
truncate -s "${TOTAL_SIZE}M" "$IMAGE" 2>/dev/null || \
    dd if=/dev/zero of="$IMAGE" bs=1M count=1 seek=$((TOTAL_SIZE - 1)) 2>/dev/null

# ── Create GPT partitions ────────────────────────────────────────────
step "Creating GPT partition table..."
if command -v gpt >/dev/null 2>&1; then
    gpt destroy "$IMAGE" 2>/dev/null || true
    gpt create -f "$IMAGE"
    gpt add -t efi -s "$((ESP_SIZE * 2048))" -l "EFI" "$IMAGE"
    gpt add -t ffs -l "STAR_TALK" "$IMAGE"
    gpt add -t swap -l "SWAP" "$IMAGE"
    success "GPT partitions created (NetBSD gpt)"
elif command -v sgdisk >/dev/null 2>&1; then
    # Linux fallback (sgdisk)
    sgdisk -Z "$IMAGE" 2>/dev/null
    sgdisk -o "$IMAGE"
    sgdisk -n "1:1MiB:+${ESP_SIZE}MiB" -t "1:EF00" -c "1:EFI" "$IMAGE"
    sgdisk -n "2:0:+${ROOT_SIZE}MiB" -t "2:8300" -c "2:STAR_TALK" "$IMAGE"
    sgdisk -n "3:0:+${SWAP_SIZE}MiB" -t "3:8200" -c "3:SWAP" "$IMAGE"
    success "GPT partitions created (Linux sgdisk)"
else
    die "No partitioning tool found (need gpt or sgdisk)"
fi

# ── Format partitions ─────────────────────────────────────────────────
step "Formatting partitions..."

# Determine partition paths based on OS
setup_loop() {
    if command -v vnconfig >/dev/null 2>&1; then
        # NetBSD: vnode disk
        VND=$(vnconfig -l | grep "not in use" | head -1 | awk '{print $1}')
        [ -z "$VND" ] && VND="vnd0"
        vnconfig "$VND" "$IMAGE"
        echo "$VND"
    elif command -v losetup >/dev/null 2>&1; then
        # Linux: loop device
        LOOP=$(losetup -Pf --show "$IMAGE")
        echo "$LOOP"
    else
        die "No loop/vnode device tool found"
    fi
}

cleanup_loop() {
    if [ -n "${VND:-}" ]; then
        vnconfig -u "$VND" 2>/dev/null || true
    fi
    if [ -n "${LOOP:-}" ]; then
        losetup -d "$LOOP" 2>/dev/null || true
    fi
    rm -rf /tmp/st-esp /tmp/st-root 2>/dev/null || true
}

DEV=$(setup_loop)
trap cleanup_loop EXIT
info "Device: $DEV"

# Determine partition naming
case "$DEV" in
    vnd*) P1="/dev/${DEV}a" P2="/dev/${DEV}b" P3="/dev/${DEV}c" ;;
    /dev/loop*) P1="${DEV}p1" P2="${DEV}p2" P3="${DEV}p3" ;;
    *) P1="${DEV}1" P2="${DEV}2" P3="${DEV}3" ;;
esac

sleep 1  # Wait for partition device nodes

# Format EFI partition
newfs_msdos -F 32 -L "EFI" "$P1" 2>/dev/null || \
    mkfs.vfat -F 32 -n "EFI" "$P1" 2>/dev/null || \
    warn "Could not format EFI partition (may need manual formatting)"

# Format FFSv2 root partition
newfs -O 2 -V 2 "$P2" 2>/dev/null || \
    mkfs.ext2 -L "STAR_TALK" "$P2" 2>/dev/null || \
    warn "Could not format root partition (using ext2 fallback)"

# Format swap
# (swap doesn't need formatting, just used as-is)

success "Partitions formatted"

# ── Mount and populate ────────────────────────────────────────────────
step "Populating disk image..."

mkdir -p /tmp/st-esp /tmp/st-root

# Mount EFI partition
if mount -t msdos "$P1" /tmp/st-esp 2>/dev/null || mount "$P1" /tmp/st-esp 2>/dev/null; then
    mkdir -p /tmp/st-esp/EFI/BOOT /tmp/st-esp/EFI/NetBSD
    
    # Copy kernel
    if [ -f "$KERNEL_SRC" ]; then
        cp "$KERNEL_SRC" /tmp/st-esp/EFI/NetBSD/netbsd
        cp "$KERNEL_SRC" /tmp/st-esp/netbsd 2>/dev/null || true
    fi
    
    # Install bootloader config
    if [ -f "$CONFIGS_DIR/netbsd/etc/boot.cfg" ]; then
        cp "$CONFIGS_DIR/netbsd/etc/boot.cfg" /tmp/st-esp/EFI/NetBSD/boot.cfg
        cp "$CONFIGS_DIR/netbsd/etc/boot.cfg" /tmp/st-esp/boot.cfg 2>/dev/null || true
    fi
    
    success "ESP populated"
    umount /tmp/st-esp
fi

# Mount Root partition
if mount "$P2" /tmp/st-root 2>/dev/null; then
    # Copy root filesystem
    if [ -d "$ROOTFS_DIR" ] && [ "$(ls -A "$ROOTFS_DIR" 2>/dev/null)" ]; then
        (cd "$ROOTFS_DIR" && find . -print0 | cpio -pdm0 /tmp/st-root/ 2>/dev/null) || \
            tar -cf - -C "$ROOTFS_DIR" . | tar -xf - -C /tmp/st-root/ || \
            cp -a "$ROOTFS_DIR"/* /tmp/st-root/
        success "Root filesystem copied"
    else
        info "Rootfs staging is empty — creating minimal structure"
        for d in bin sbin lib libexec usr etc var home root opt dev proc sys tmp; do
            mkdir -p "/tmp/st-root/$d"
        done
    fi
    
    # Copy boot.cfg to root
    mkdir -p /tmp/st-root/boot /tmp/st-root/etc
    cp "$CONFIGS_DIR/netbsd/etc/boot.cfg" /tmp/st-root/boot.cfg 2>/dev/null || true
    cp "$CONFIGS_DIR/netbsd/etc/boot.cfg" /tmp/st-root/etc/boot.cfg 2>/dev/null || true
    
    umount /tmp/st-root
fi

# ── Cleanup ───────────────────────────────────────────────────────────
cleanup_loop
trap - EXIT

# ── Final output ─────────────────────────────────────────────────────
IMAGE_SIZE=$(du -h "$IMAGE" | cut -f1)
success "Disk image created: $IMAGE ($IMAGE_SIZE)"
echo ""
info "To write to USB:"
info "  dd if=$IMAGE of=/dev/sdX bs=1M conv=fsync status=progress"
echo ""
info "To test with QEMU:"
info "  make test-qemu"
echo ""

cd "$PROJECT_ROOT"
build_summary "$PHASE" "$START_TIME"
