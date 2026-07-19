#!/bin/sh
# ╔══════════════════════════════════════════════════════════════════════╗
# ║  Star-Talk / 星语 — Disk Image Creation (GPT on loop device)      ║
# ╚══════════════════════════════════════════════════════════════════════╝
set -e
. "$(dirname "$0")/utils-netbsd.sh"

PHASE="N06"; START_TIME=$(date +%s)
step "Phase ${PHASE}: Creating bootable disk image"

IMAGE_NAME="star-talk-netbsd-$(date +%Y%m%d).img"
IMAGE="$OUT_DIR/$IMAGE_NAME"
ESP_SIZE=260; ROOT_SIZE=8192; SWAP_SIZE=4096
TOTAL_SIZE=$((ESP_SIZE + ROOT_SIZE + SWAP_SIZE + 5))
KERNEL_SRC="$OUT_DIR/netbsd"
BOOTX64="$OUT_DIR/bootx64.efi"
MAKEFS="$NETBSD_TOOLDIR/bin/nbmakefs"
ROOT_CONTENTS=/tmp/st-root-contents
FFS_IMG=/tmp/st-root.ffs
ESP_MNT=/tmp/st-esp

info "Image: $IMAGE (${TOTAL_SIZE} MiB)"

# Prerequisites
for tool in sgdisk mkfs.vfat losetup; do
    command -v "$tool" >/dev/null 2>&1 || die "$tool not found"
done
[ -f "$KERNEL_SRC" ] || die "Kernel not found"

cleanup() {
    sudo umount "$ESP_MNT" 2>/dev/null || true
    sudo losetup -d "$LOOP" 2>/dev/null || true
    rm -rf "$ESP_MNT" "$ROOT_CONTENTS" "$FFS_IMG" 2>/dev/null || true
}
trap cleanup EXIT

# ── 1. Create file + loop + GPT ────────────────────────────────────────
step "Creating GPT partitions..."
rm -f "$IMAGE"
dd if=/dev/zero of="$IMAGE" bs=1M count=1 2>/dev/null  # non-sparse header
truncate -s "${TOTAL_SIZE}M" "$IMAGE"
LOOP=$(sudo losetup -Pf --show "$IMAGE")
sleep 1

sudo sgdisk -o "$LOOP" >/dev/null
sudo sgdisk -n "1:1MiB:+${ESP_SIZE}MiB" -t "1:EF00" -c "1:EFI" "$LOOP" >/dev/null
sudo sgdisk -n "2:0:+${ROOT_SIZE}MiB" -t "2:A902" -c "2:STAR_TALK" "$LOOP" >/dev/null
sudo sgdisk -n "3:0:+${SWAP_SIZE}MiB" -t "3:8200" -c "3:SWAP" "$LOOP" >/dev/null
sudo partprobe "$LOOP" 2>/dev/null || true
sleep 1
success "GPT: EFI(${ESP_SIZE}M) + FFSv2(${ROOT_SIZE}M) + Swap(${SWAP_SIZE}M)"

# ── 2. Format ESP ──────────────────────────────────────────────────────
step "Formatting ESP..."
sudo mkfs.vfat -F32 -n "EFI" "${LOOP}p1" >/dev/null 2>&1
success "P1: FAT32"

# ── 3. Populate ESP ────────────────────────────────────────────────────
step "Populating ESP..."
mkdir -p "$ESP_MNT"
sudo mount "${LOOP}p1" "$ESP_MNT"
sudo mkdir -p "$ESP_MNT/EFI/BOOT" "$ESP_MNT/EFI/NetBSD"

sudo cp "$KERNEL_SRC" "$ESP_MNT/EFI/NetBSD/netbsd"
sudo cp "$KERNEL_SRC" "$ESP_MNT/netbsd"

if [ -f "$BOOTX64" ]; then
    sudo cp "$BOOTX64" "$ESP_MNT/EFI/BOOT/BOOTX64.EFI"
    sudo cp "$BOOTX64" "$ESP_MNT/EFI/NetBSD/bootx64.efi"
fi
if [ -f "$CONFIGS_DIR/netbsd/etc/boot.cfg" ]; then
    sudo cp "$CONFIGS_DIR/netbsd/etc/boot.cfg" "$ESP_MNT/EFI/BOOT/boot.cfg"
    sudo cp "$CONFIGS_DIR/netbsd/etc/boot.cfg" "$ESP_MNT/boot.cfg"
fi
sudo umount "$ESP_MNT"
success "ESP populated"

# ── 4. Assemble rootfs contents ────────────────────────────────────────
step "Assembling FFSv2 root..."
rm -rf "$ROOT_CONTENTS"
mkdir -p "$ROOT_CONTENTS"

if [ -d "$NETBSD_DESTDIR" ] && [ "$(ls -A "$NETBSD_DESTDIR" 2>/dev/null)" ]; then
    info "Copying userland..."
    cp -a "$NETBSD_DESTDIR"/* "$ROOT_CONTENTS/" 2>/dev/null || \
        (cd "$NETBSD_DESTDIR" && tar -cf - .) | (cd "$ROOT_CONTENTS" && tar -xf -)
fi
if [ -d "$ROOTFS_DIR" ] && [ "$(ls -A "$ROOTFS_DIR" 2>/dev/null)" ]; then
    cp -a "$ROOTFS_DIR"/* "$ROOT_CONTENTS/" 2>/dev/null || true
fi
for d in dev proc sys tmp var/log var/run mnt media home boot; do
    mkdir -p "$ROOT_CONTENTS/$d"
done
cp "$CONFIGS_DIR/netbsd/etc/boot.cfg" "$ROOT_CONTENTS/boot.cfg" 2>/dev/null || true

# Copy pkgsrc
if [ -d "$PKGSRC_DIR" ] && [ -f "$PKGSRC_DIR/Makefile" ]; then
    info "Copying pkgsrc..."
    mkdir -p "$ROOT_CONTENTS/usr/pkgsrc"
    (cd "$PKGSRC_DIR" && tar --exclude='.git' --exclude='distfiles' --exclude='packages' -cf - .) | \
        (cd "$ROOT_CONTENTS/usr/pkgsrc" && tar -xf -)
fi

# ── 5. Create + write FFSv2 ────────────────────────────────────────────
info "Creating FFSv2 (${ROOT_SIZE}M)..."
"$MAKEFS" -t ffs -o version=2,label=STAR_TALK -s "${ROOT_SIZE}m" \
    "$FFS_IMG" "$ROOT_CONTENTS" 2>&1 | tail -1

sudo dd if="$FFS_IMG" of="${LOOP}p2" bs=1M conv=fsync status=progress 2>/dev/null
success "FFSv2 root written"

# ── 6. Cleanup ─────────────────────────────────────────────────────────
cleanup; trap - EXIT

IMAGE_SIZE=$(du -h "$IMAGE" | cut -f1)
success "Image: $IMAGE ($IMAGE_SIZE)"
