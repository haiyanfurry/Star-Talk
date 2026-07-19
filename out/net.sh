qemu-system-x86_64 \
  -bios /usr/share/edk2/x64/OVMF.4m.fd \
  -drive file=star-talk-netbsd-20260719.img,format=raw,if=virtio \
  -m 2G \
  -netdev user,id=net0,hostfwd=tcp::2222-:22 \
  -device virtio-net-pci,netdev=net0 \
  -nographic \
  -serial mon:stdio \
  -append "console=com0 acpi=off"
