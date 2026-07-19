#!/bin/sh
set -e
. "$(dirname "$0")/utils-netbsd.sh"
PHASE="N05"
step "Phase ${PHASE}: Assembling root filesystem"
for d in dev proc sys tmp var/log var/run mnt media home boot; do
    mkdir -p "$ROOTFS_DIR/$d"
done
cat > "$ROOTFS_DIR/etc/fstab" << 'FSTAB'
/dev/dk0    /           ext2fs  rw          1 1
/dev/dk2    none        swap    sw          0 0
tmpfs       /tmp        tmpfs   rw,-s256M   0 0
procfs      /proc       procfs  rw          0 0
ptyfs       /dev/pts    ptyfs   rw          0 0
kernfs      /kern       kernfs  rw          0 0
FSTAB
echo "startalk" > "$ROOTFS_DIR/etc/myname"
success "RootFS assembled"
