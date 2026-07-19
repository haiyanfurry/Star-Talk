#!/bin/bash
IMG="$(dirname "$0")/star-talk-netbsd-20260719.img"
OVMF="/usr/share/edk2/x64/OVMF.4m.fd"

qemu-system-x86_64 \
  -bios "$OVMF" \
  -drive file="$IMG",format=raw,if=virtio \
  -m 2G \
  -nographic \
  -serial mon:stdio
