#!/bin/bash
# ╔══════════════════════════════════════════════════════════════╗
# ║     Star-Talk / 星语 — 25-test-qemu.sh                    ║
# ║     Test the USB image in QEMU                            ║
# ╚══════════════════════════════════════════════════════════════╝
set -euo pipefail
source "$(dirname "$0")/utils.sh"

IMAGE=""
if [ -f "$OUT_DIR/star-talk-$(date +%Y%m%d).img" ]; then
    IMAGE="$OUT_DIR/star-talk-$(date +%Y%m%d).img"
else
    IMAGE=$(ls -t "$OUT_DIR"/star-talk-*.img 2>/dev/null | head -1)
fi

if [ -z "$IMAGE" ]; then
    die "No image found. Run 'make usb-image' first."
fi

step "Starting QEMU with $IMAGE..."

# Check for QEMU
QEMU=""
for q in qemu-system-x86_64 qemu-kvm; do
    command -v "$q" &>/dev/null && { QEMU="$q"; break; }
done

if [ -z "$QEMU" ]; then
    die "qemu-system-x86_64 not found. Install qemu-system-x86."
fi

# Check for KVM
KVM=""
[ -e /dev/kvm ] && [ -r /dev/kvm ] && [ -w /dev/kvm ] && KVM="-enable-kvm"

# Launch QEMU
# Uses OVMF (Tianocore) UEFI firmware — must be installed
OVMF_CODE=""
[ -f /usr/share/ovmf/x64/OVMF_CODE.fd ] && OVMF_CODE="/usr/share/ovmf/x64/OVMF_CODE.fd"
[ -f /usr/share/edk2-ovmf/x64/OVMF_CODE.fd ] && OVMF_CODE="/usr/share/edk2-ovmf/x64/OVMF_CODE.fd"
[ -f /usr/share/OVMF/OVMF_CODE.fd ] && OVMF_CODE="/usr/share/OVMF/OVMF_CODE.fd"

if [ -z "$OVMF_CODE" ]; then
    warn "OVMF UEFI firmware not found. Install edk2-ovmf."
    warn "Falling back to BIOS boot (may not work with GPT)..."
    exec $QEMU $KVM -m 2048 -smp 2 \
        -drive file="$IMAGE",format=raw,if=virtio \
        -net nic,model=virtio -net user \
        -vga virtio \
        -display gtk,gl=on \
        "$@"
else
    exec $QEMU $KVM -m 2048 -smp 2 \
        -drive file="$OVMF_CODE",if=pflash,format=raw,readonly=on \
        -drive file="$IMAGE",format=raw,if=virtio \
        -net nic,model=virtio -net user \
        -vga virtio \
        -display gtk,gl=on \
        -device virtio-tablet-pci \
        "$@"
fi
