#!/bin/bash
# ╔══════════════════════════════════════════════════════════════╗
# ║     Star-Talk / 星语 — 23-make-usb-image.sh               ║
# ║     Create final GPT USB disk image                       ║
# ╚══════════════════════════════════════════════════════════════╝
set -euo pipefail
source "$(dirname "$0")/utils.sh"

PHASE="23"
START_TIME=$(date +%s)
step "Phase ${PHASE}: Creating USB disk image"

# ── Configuration ────────────────────────────────────────────────
IMAGE_NAME="star-talk-$(date +%Y%m%d).img"
IMAGE="$OUT_DIR/$IMAGE_NAME"

ESP_SIZE="${ESP_SIZE:-512}"      # MiB
ROOT_SIZE="${ROOT_SIZE:-4096}"   # MiB
PERSIST_SIZE="${PERSIST_SIZE:-2048}"  # MiB
INCLUDE_PERSIST="${INCLUDE_PERSIST:-yes}"

# ── Check prerequisites ──────────────────────────────────────────
if [ ! -f "$OUT_DIR/bzImage" ]; then
    die "Kernel bzImage not found at $OUT_DIR/bzImage. Run 'make kernel' first."
fi

if [ ! -f "$OUT_DIR/initramfs.cpio.zst" ] && [ ! -f "$OUT_DIR/initramfs.cpio" ]; then
    die "initramfs not found. Run 'make initramfs' first."
fi

INITRAMFS_SRC=""
[ -f "$OUT_DIR/initramfs.cpio.zst" ] && INITRAMFS_SRC="$OUT_DIR/initramfs.cpio.zst"
[ -f "$OUT_DIR/initramfs.cpio" ] && INITRAMFS_SRC="$OUT_DIR/initramfs.cpio"

# ── Check tools ──────────────────────────────────────────────────
for tool in sgdisk mkfs.vfat mkfs.ext4 losetup; do
    if ! command -v "$tool" &>/dev/null; then
        die "$tool not found. Please install: gdisk dosfstools e2fsprogs util-linux"
    fi
done

# ── Calculate total size ────────────────────────────────────────
RESERVED=2   # MiB for GPT headers
TOTAL_SIZE=$((RESERVED + ESP_SIZE + ROOT_SIZE))
[ "$INCLUDE_PERSIST" = "yes" ] && TOTAL_SIZE=$((TOTAL_SIZE + PERSIST_SIZE))

info "Image: $IMAGE"
info "Total size: ${TOTAL_SIZE} MiB"
info "Partitions:"
info "  P1: ESP (FAT32) — ${ESP_SIZE} MiB — STARTALK_EFI"
info "  P2: Root (ext4) — ${ROOT_SIZE} MiB — STARTALK_ROOT"
[ "$INCLUDE_PERSIST" = "yes" ] && \
info "  P3: Persist (ext4) — ${PERSIST_SIZE} MiB — STARTALK_PERSIST"

# ── Create sparse image ──────────────────────────────────────────
step "Creating sparse disk image..."
rm -f "$IMAGE"
truncate -s "${TOTAL_SIZE}M" "$IMAGE"

# ── Partition with sgdisk ────────────────────────────────────────
step "Partitioning disk (GPT)..."

sgdisk -Z "$IMAGE" 2>/dev/null  # Zap existing GPT/MBR
sgdisk -o "$IMAGE"              # Create fresh GPT

# Partition 1: ESP (FAT32, type EF00)
sgdisk -n "1:1MiB:+${ESP_SIZE}MiB" -t "1:EF00" -c "1:STARTALK_EFI" "$IMAGE"

# Partition 2: Root (ext4)
ESP_END=$((ESP_SIZE + 1))
sgdisk -n "2:${ESP_END}MiB:+${ROOT_SIZE}MiB" -t "2:8300" -c "2:STARTALK_ROOT" "$IMAGE"

# Partition 3: Persistence (optional)
if [ "$INCLUDE_PERSIST" = "yes" ]; then
    ROOT_END=$((ESP_SIZE + ROOT_SIZE + 1))
    sgdisk -n "3:${ROOT_END}MiB:+${PERSIST_SIZE}MiB" -t "3:8300" -c "3:STARTALK_PERSIST" "$IMAGE"
fi

success "Partitions created"

# ── Set up loop device ───────────────────────────────────────────
step "Setting up loop device..."
LOOP=$(losetup -Pf --show "$IMAGE")
info "Loop device: $LOOP"

# Cleanup function
cleanup_loop() {
    losetup -d "$LOOP" 2>/dev/null || true
    rm -rf /tmp/star-talk-esp /tmp/star-talk-root /tmp/star-talk-persist 2>/dev/null || true
}
trap cleanup_loop EXIT

# Wait for kernel to create partitions
sleep 1

# ── Format partitions ────────────────────────────────────────────
step "Formatting partitions..."

mkfs.vfat -F32 -n "STARTALK_EFI" "${LOOP}p1" >/dev/null 2>&1
success "P1: FAT32 formatted (STARTALK_EFI)"

mkfs.ext4 -L "STARTALK_ROOT" -q "${LOOP}p2" 2>/dev/null
success "P2: ext4 formatted (STARTALK_ROOT)"

if [ "$INCLUDE_PERSIST" = "yes" ]; then
    mkfs.ext4 -L "STARTALK_PERSIST" -q "${LOOP}p3" 2>/dev/null
    success "P3: ext4 formatted (STARTALK_PERSIST)"
fi

# ── Mount and populate ESP ──────────────────────────────────────
step "Populating EFI System Partition..."

mkdir -p /tmp/star-talk-esp
mount "${LOOP}p1" /tmp/star-talk-esp

mkdir -p /tmp/star-talk-esp/EFI/BOOT
mkdir -p /tmp/star-talk-esp/EFI/Linux
mkdir -p /tmp/star-talk-esp/loader/entries

# Install systemd-boot EFI
if command -v bootctl &>/dev/null; then
    bootctl install --esp-path=/tmp/star-talk-esp --no-variables 2>/dev/null || {
        warn "bootctl install failed, creating manual EFI entry..."
        # Manual EFI stub fallback
        cp "$OUT_DIR/bzImage" /tmp/star-talk-esp/EFI/BOOT/BOOTX64.EFI
    }
else
    warn "bootctl not available, using direct EFI stub..."
    # Use kernel as EFI stub directly
    cp "$OUT_DIR/bzImage" /tmp/star-talk-esp/EFI/BOOT/BOOTX64.EFI
fi

# Copy kernel and initramfs
cp "$OUT_DIR/bzImage" /tmp/star-talk-esp/EFI/Linux/vmlinuz.efi
cp "$INITRAMFS_SRC" /tmp/star-talk-esp/EFI/Linux/initramfs.cpio.zst 2>/dev/null || \
cp "$INITRAMFS_SRC" /tmp/star-talk-esp/EFI/Linux/initramfs.cpio

# ── systemd-boot config ──────────────────────────────────────────
cat > /tmp/star-talk-esp/loader/loader.conf << 'EOF'
timeout 3
default star-talk
console-mode auto
editor no
auto-entries no
auto-firmware no
EOF

cat > /tmp/star-talk-esp/loader/entries/star-talk.conf << 'EOF'
title   Star-Talk / 星语
linux   /EFI/Linux/vmlinuz.efi
initrd  /EFI/Linux/initramfs.cpio.zst
options root=LABEL=STARTALK_ROOT rw quiet loglevel=3
EOF

cat > /tmp/star-talk-esp/loader/entries/star-talk-persist.conf << 'EOF'
title   Star-Talk / 星语 (Persistent Mode)
linux   /EFI/Linux/vmlinuz.efi
initrd  /EFI/Linux/initramfs.cpio.zst
options root=LABEL=STARTALK_ROOT rw persistence quiet loglevel=3
EOF

# ── Populate Root partition ──────────────────────────────────────
step "Populating Root partition..."

mkdir -p /tmp/star-talk-root
mount "${LOOP}p2" /tmp/star-talk-root

# Copy rootfs contents
cp -a "$ROOTFS_DIR"/* /tmp/star-talk-root/ 2>/dev/null || \
    rsync -a "$ROOTFS_DIR/" /tmp/star-talk-root/

# Ensure essential directories exist
for d in dev proc sys run tmp var/log home/startalk; do
    mkdir -p "/tmp/star-talk-root/$d"
done

success "Rootfs copied to partition"

# ── Create SquashFS file on root partition (optional) ────────────
if [ -f "$OUT_DIR/rootfs.squashfs" ]; then
    step "Copying SquashFS file to root partition..."
    cp "$OUT_DIR/rootfs.squashfs" /tmp/star-talk-root/star-talk.squashfs
    success "SquashFS file placed on root partition"
fi

# ── Unmount ──────────────────────────────────────────────────────
step "Unmounting..."
umount /tmp/star-talk-esp
umount /tmp/star-talk-root
cleanup_loop
trap - EXIT

# ── Final output ─────────────────────────────────────────────────
IMAGE_SIZE=$(du -h "$IMAGE" | cut -f1)
success "USB image created: $IMAGE ($IMAGE_SIZE)"
echo ""
info "To write to USB: sudo dd if=$IMAGE of=/dev/sdX bs=4M status=progress conv=fsync"
info "Or: make burn DEVICE=/dev/sdX"
echo ""

cd "$PROJECT_ROOT"
build_summary "$PHASE" "$START_TIME"
