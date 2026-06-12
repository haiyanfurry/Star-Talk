#!/bin/bash
# Star-Talk / 星語 — Populate USB image with rootfs
# Run once with sudo to copy rootfs into the disk image
set -euo pipefail

IMAGE="/home/haiyan/Star-Talk/out/star-talk-20260613.img"

echo "Populating Star-Talk disk image..."
echo "Image: $IMAGE"

# Setup loop
LOOP=$(losetup -Pf --show "$IMAGE")
echo "Loop device: $LOOP"

# Mount root partition
mkdir -p /tmp/star-talk-root
mount "${LOOP}p2" /tmp/star-talk-root

# Copy rootfs
echo "Copying rootfs to root partition..."
cp -a /home/haiyan/Star-Talk/rootfs/* /tmp/star-talk-root/

# Ensure essential directories
for d in dev proc sys run tmp var/log home/startalk; do
    mkdir -p "/tmp/star-talk-root/$d"
done

# Set proper permissions (user startalk owns home)
chown -R 1000:1000 /tmp/star-talk-root/home/startalk 2>/dev/null || true

echo "Root partition populated."
df -h /tmp/star-talk-root

# Cleanup
umount /tmp/star-talk-root
losetup -d "$LOOP"
rmdir /tmp/star-talk-root

echo ""
echo "Done! Image is ready: $IMAGE"
echo "Test with QEMU:"
echo "  qemu-system-x86_64 -enable-kvm -m 2048 \\"
echo "    -drive file=$IMAGE,format=raw,if=virtio \\"
echo "    -bios /usr/share/ovmf/x64/OVMF.fd \\"
echo "    -display gtk,gl=on"
