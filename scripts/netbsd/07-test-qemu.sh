#!/bin/sh
# ╔══════════════════════════════════════════════════════════════════════╗
# ║  Star-Talk / 星语 — QEMU Testing Script                           ║
# ║  Tests the Star-Talk disk image in a virtual machine               ║
# ╚══════════════════════════════════════════════════════════════════════╝
set -e
. "$(dirname "$0")/utils-netbsd.sh"

# Find the latest image
IMAGE=$(ls -t "$OUT_DIR"/star-talk-netbsd-*.img 2>/dev/null | head -1)
if [ -z "$IMAGE" ]; then
    die "No disk image found in $OUT_DIR. Run 'make image' first."
fi

info "Testing: $IMAGE ($(du -h "$IMAGE" | cut -f1))"

# Check for QEMU
if ! command -v qemu-system-x86_64 >/dev/null 2>&1; then
    die "qemu-system-x86_64 not found. Install: pkgin install qemu"
fi

step "Starting QEMU..."

qemu-system-x86_64 \
    -m 4096 \
    -smp 4 \
    -cpu host \
    -enable-kvm 2>/dev/null || true \
    -drive file="$IMAGE",format=raw,if=virtio \
    -netdev user,id=net0,hostfwd=tcp::2222-:22 \
    -device virtio-net,netdev=net0 \
    -display gtk,gl=on \
    -vga virtio \
    -usb \
    -device usb-tablet \
    -name "Star-Talk / 星语" \
    -boot menu=on &

QEMU_PID=$!
success "QEMU started (PID: $QEMU_PID)"
info "SSH available at: localhost:2222"
info "Press Ctrl+C to stop QEMU"

# Wait for QEMU
wait $QEMU_PID 2>/dev/null || true
