#!/bin/bash
# ╔══════════════════════════════════════════════════════════════╗
# ║     Star-Talk / 星语 — 24-burn-usb.sh                     ║
# ║     Write disk image to USB device (with safety checks)   ║
# ╚══════════════════════════════════════════════════════════════╝
set -euo pipefail
source "$(dirname "$0")/utils.sh"

DEVICE="${1:-}"

# ── Find latest image ────────────────────────────────────────────
IMAGE=""
if [ -f "$OUT_DIR/star-talk-$(date +%Y%m%d).img" ]; then
    IMAGE="$OUT_DIR/star-talk-$(date +%Y%m%d).img"
else
    # Find most recent image
    IMAGE=$(ls -t "$OUT_DIR"/star-talk-*.img 2>/dev/null | head -1)
fi

if [ -z "$IMAGE" ]; then
    die "No disk image found in $OUT_DIR/. Run 'make usb-image' first."
fi

# ── Check device argument ────────────────────────────────────────
if [ -z "$DEVICE" ]; then
    echo "Usage: $0 /dev/sdX"
    echo ""
    echo "Available block devices:"
    lsblk -o NAME,SIZE,TYPE,MOUNTPOINT,LABEL,MODEL 2>/dev/null || lsblk
    echo ""
    echo "Image to write: $IMAGE ($(du -h "$IMAGE" | cut -f1))"
    exit 1
fi

if [ ! -b "$DEVICE" ]; then
    die "$DEVICE is not a valid block device"
fi

# ── Safety checks ────────────────────────────────────────────────
step "Safety inspection of $DEVICE..."

# Get device info
DEV_INFO=$(lsblk "$DEVICE" -o NAME,SIZE,MODEL,LABEL,MOUNTPOINT 2>/dev/null)
echo "$DEV_INFO"
echo ""

# Check 1: Is it mounted?
MOUNTED=$(mount | grep "^$DEVICE" || true)
if [ -n "$MOUNTED" ]; then
    echo "$MOUNTED"
    warn "Device has mounted partitions. Attempting to unmount..."
    for mp in $(mount | grep "^$DEVICE" | awk '{print $1}'); do
        umount "$mp" 2>/dev/null || true
    done
fi

# Check 2: Does it look like a system disk?
if mount | grep -qE "on / type"; then
    ROOT_DISK=$(mount | grep "on / type" | awk '{print $1}' | sed 's/[0-9]*$//' | sed 's/p$//')
    if echo "$DEVICE" | grep -q "$ROOT_DISK"; then
        die "REFUSING TO OVERWRITE SYSTEM DISK: $DEVICE appears to be the root disk ($ROOT_DISK)"
    fi
fi

# Check 3: Size check
DEV_SIZE=$(lsblk -bno SIZE "$DEVICE" | head -1)
IMG_SIZE=$(stat -c%s "$IMAGE")
if [ "$IMG_SIZE" -gt "$DEV_SIZE" ]; then
    die "Image ($(numfmt --to=iec $IMG_SIZE)) is larger than device ($(numfmt --to=iec $DEV_SIZE))"
fi

# ── Confirm with user ────────────────────────────────────────────
echo ""
echo "  ╔══════════════════════════════════════════════════════════════╗"
echo "  ║  WARNING: This will DESTROY ALL DATA on $DEVICE"
echo "  ║  Image: $(basename $IMAGE) ($(du -h "$IMAGE" | cut -f1))"
echo "  ╚══════════════════════════════════════════════════════════════╝"
echo ""
read -r -p "  Type 'YES' (uppercase) to confirm: " CONFIRM

if [ "$CONFIRM" != "YES" ]; then
    echo "  Aborted."
    exit 0
fi

# ── Write image ──────────────────────────────────────────────────
step "Writing $IMAGE to $DEVICE..."
echo "  This may take a few minutes depending on image size..."

dd if="$IMAGE" of="$DEVICE" bs=4M status=progress conv=fsync

step "Syncing..."
sync
sync

success "Star-Talk USB is ready!"
echo ""
echo "  ┌──────────────────────────────────────────────────────────┐"
echo "  │  Boot from USB:                                         │"
echo "  │  1. Insert USB into target computer                     │"
echo "  │  2. Enter BIOS/UEFI boot menu (F12/F2/Esc/Del)          │"
echo "  │  3. Select UEFI: STARTALK_EFI                           │"
echo "  │  4. Enjoy Star-Talk / 星语!                             │"
echo "  └──────────────────────────────────────────────────────────┘"
echo ""
