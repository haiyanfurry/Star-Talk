#!/bin/sh
# ╔══════════════════════════════════════════════════════════════════════╗
# ║  Star-Talk / 星语 — Disk Image Creation                           ║
# ║  Uses nbmakefs for FFSv2 root (NetBSD native filesystem)           ║
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

# ── Prerequisites ──────────────────────────────────────────────────────
for tool in sgdisk mkfs.vfat losetup; do
    command -v "$tool" >/dev/null 2>&1 || die "$tool not found"
done
[ -f "$KERNEL_SRC" ] || die "Kernel not found: $KERNEL_SRC"
[ -x "$MAKEFS" ] || die "nbmakefs not found: $MAKEFS (run make kernel first)"

info "Image: $IMAGE (${TOTAL_SIZE} MiB, FFSv2 root)"

# ── Create + partition ─────────────────────────────────────────────────
step "Creating GPT partitions..."
rm -f "$IMAGE"
# Use dd to create a non-sparse first chunk (avoids sgdisk sparse file issues)
dd if=/dev/zero of="$IMAGE" bs=1M count=10 2>/dev/null
truncate -s "${TOTAL_SIZE}M" "$IMAGE"
# Create GPT on loop device directly
LOOP=$(echo "kali" | echo "kali" | sudo -S -S losetup -Pf --show "$IMAGE")
sleep 1
echo "kali" | echo "kali" | sudo -S -S sgdisk -o "$LOOP" >/dev/null
echo "kali" | echo "kali" | sudo -S -S sgdisk -n "1:1MiB:+${ESP_SIZE}MiB" -t "1:EF00" -c "1:EFI" "$LOOP" >/dev/null
echo "kali" | echo "kali" | sudo -S -S sgdisk -n "2:0:+${ROOT_SIZE}MiB" -t "2:A902" -c "2:STAR_TALK" "$LOOP" >/dev/null
echo "kali" | echo "kali" | sudo -S -S sgdisk -n "3:0:+${SWAP_SIZE}MiB" -t "3:8200" -c "3:SWAP" "$LOOP" >/dev/null
# Verify GPT
echo "kali" | echo "kali" | sudo -S -S sgdisk -p "$LOOP" 2>/dev/null | grep -E "^   1|^   2|^   3" || warn "GPT verification failed"
success "GPT: EFI(${ESP_SIZE}M) + FFSv2(${ROOT_SIZE}M) + Swap(${SWAP_SIZE}M)"

# ── Format EFI ─────────────────────────────────────────────────────────
step "Formatting EFI partition..."
cleanup() { echo "kali" | echo "kali" | sudo -S -S losetup -d "$LOOP" 2>/dev/null || true; rm -rf /tmp/st-esp /tmp/st-root-contents /tmp/st-root.ffs 2>/dev/null || true; }
trap cleanup EXIT

echo "kali" | sudo -S mkfs.vfat -F32 -n "EFI" "${LOOP}p1" >/dev/null 2>&1
success "P1: FAT32"

# ── Populate EFI ───────────────────────────────────────────────────────
step "Populating EFI..."
mkdir -p /tmp/st-esp
echo "kali" | sudo -S mount "${LOOP}p1" /tmp/st-esp
echo "kali" | sudo -S mkdir -p /tmp/st-esp/EFI/BOOT /tmp/st-esp/EFI/NetBSD
echo "kali" | sudo -S cp "$KERNEL_SRC" /tmp/st-esp/EFI/NetBSD/netbsd
echo "kali" | sudo -S cp "$KERNEL_SRC" /tmp/st-esp/netbsd

if [ -f "$BOOTX64" ]; then
    echo "kali" | sudo -S cp "$BOOTX64" /tmp/st-esp/EFI/BOOT/BOOTX64.EFI
    echo "kali" | sudo -S cp "$BOOTX64" /tmp/st-esp/EFI/NetBSD/bootx64.efi
fi
if [ -f "$CONFIGS_DIR/netbsd/etc/boot.cfg" ]; then
    echo "kali" | sudo -S cp "$CONFIGS_DIR/netbsd/etc/boot.cfg" /tmp/st-esp/EFI/BOOT/boot.cfg
    echo "kali" | sudo -S cp "$CONFIGS_DIR/netbsd/etc/boot.cfg" /tmp/st-esp/boot.cfg
    echo "kali" | sudo -S cp "$CONFIGS_DIR/netbsd/etc/boot.cfg" /tmp/st-esp/EFI/NetBSD/boot.cfg
fi
echo "kali" | sudo -S umount /tmp/st-esp
success "EFI populated (kernel + bootx64.efi + boot.cfg)"

# ── Build FFSv2 root with nbmakefs ─────────────────────────────────────
step "Assembling FFSv2 root filesystem..."
ROOT_CONTENTS=/tmp/st-root-contents
rm -rf "$ROOT_CONTENTS"
mkdir -p "$ROOT_CONTENTS"

# Copy NetBSD userland
if [ -d "$NETBSD_DESTDIR" ] && [ "$(ls -A "$NETBSD_DESTDIR" 2>/dev/null)" ]; then
    info "Copying userland..."
    cp -a "$NETBSD_DESTDIR"/* "$ROOT_CONTENTS/" 2>/dev/null || \
        (cd "$NETBSD_DESTDIR" && tar -cf - .) | (cd "$ROOT_CONTENTS" && tar -xf -)
fi

# Copy Star-Talk configs
if [ -d "$ROOTFS_DIR" ] && [ "$(ls -A "$ROOTFS_DIR" 2>/dev/null)" ]; then
    cp -a "$ROOTFS_DIR"/* "$ROOT_CONTENTS/" 2>/dev/null || true
fi

# Essential directories
for d in dev proc sys tmp var/log var/run mnt media home boot; do
    mkdir -p "$ROOT_CONTENTS/$d"
done

# Copy boot.cfg to root too
if [ -f "$CONFIGS_DIR/netbsd/etc/boot.cfg" ]; then
    cp "$CONFIGS_DIR/netbsd/etc/boot.cfg" "$ROOT_CONTENTS/boot.cfg"
fi

# Copy pkgsrc tree (if available) for first-boot package installation
if [ -d "$PKGSRC_DIR" ] && [ -f "$PKGSRC_DIR/Makefile" ]; then
    info "Copying pkgsrc tree..."
    PKGSRC_TARGET="$ROOT_CONTENTS/usr/pkgsrc"
    mkdir -p "$PKGSRC_TARGET"
    cp -a "$PKGSRC_DIR"/* "$PKGSRC_TARGET/" 2>/dev/null || \
        (cd "$PKGSRC_DIR" && tar --exclude='.git' --exclude='distfiles' --exclude='packages' -cf - .) | \
        (cd "$PKGSRC_TARGET" && tar -xf -)
    success "pkgsrc tree copied"
fi

# Create FFSv2 image with nbmakefs
info "Creating FFSv2 (${ROOT_SIZE}M)..."
"$MAKEFS" -t ffs -o version=2,label=STAR_TALK -s "${ROOT_SIZE}m" \
    /tmp/st-root.ffs "$ROOT_CONTENTS" 2>&1 | tail -1

# Write FFS image to partition
echo "kali" | sudo -S dd if=/tmp/st-root.ffs of="${LOOP}p2" bs=1M conv=fsync status=progress 2>/dev/null
success "FFSv2 root written"

# ── Cleanup ────────────────────────────────────────────────────────────
cleanup; trap - EXIT

IMAGE_SIZE=$(du -h "$IMAGE" | cut -f1)
success "Image: $IMAGE ($IMAGE_SIZE)"
echo ""
info "Boot: qemu-system-x86_64 -bios /usr/share/edk2/x64/OVMF.4m.fd -drive file=$IMAGE,format=raw -m 2G -nographic -serial mon:stdio"
