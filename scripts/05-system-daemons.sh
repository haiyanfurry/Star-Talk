#!/bin/bash
# ╔══════════════════════════════════════════════════════════════╗
# ║     Star-Talk / 星语 — 05-system-daemons.sh               ║
# ║     Build dbus + elogind                                  ║
# ╚══════════════════════════════════════════════════════════════╝
set -euo pipefail
source "$(dirname "$0")/utils.sh"

PHASE="05"
START_TIME=$(date +%s)
step "Phase ${PHASE}: Building system daemons"

# ── dbus ─────────────────────────────────────────────────────────
step "Building dbus 1.16.2"
DBUS_DIR="$BUILD_DIR/dbus-1.16.2"
if [ ! -f "$ROOTFS_DIR/usr/bin/dbus-daemon" ]; then
    extract_to "$SOURCES_DIR/dbus-1.16.2.tar.xz" "$(dirname "$DBUS_DIR")"
    cd "$DBUS_DIR"
    ./configure --prefix=/usr --sysconfdir=/etc \
        --localstatedir=/var --runstatedir=/run \
        --disable-static --disable-systemd \
        --without-x --disable-xml-docs \
        --with-dbus-user=dbus
    make -j"$JOBS"
    make DESTDIR="$ROOTFS_DIR" install

    # Create dbus user/group in rootfs
    mkdir -p "$ROOTFS_DIR/etc/dbus-1"
    success "dbus: installed"
else
    info "dbus: already installed"
fi

# ── elogind ──────────────────────────────────────────────────────
step "Building elogind v255.7"
ELOGIND_DIR="$BUILD_DIR/elogind-v255.7"
if [ ! -f "$ROOTFS_DIR/usr/libexec/elogind" ] && [ ! -f "$ROOTFS_DIR/usr/libexec/elogind/elogind" ]; then
    extract_to "$SOURCES_DIR/elogind-v255.7.tar.gz" "$(dirname "$ELOGIND_DIR")"

    # elogind uses meson
    cd "$ELOGIND_DIR"

    meson setup build --prefix=/usr \
        -Dlibexecdir=libexec \
        -Ddefault-hierarchy=legacy \
        -Dcgroup-controller=elogind \
        -Dhalt-path=/sbin/halt \
        -Dpoweroff-path=/sbin/poweroff \
        -Dreboot-path=/sbin/reboot

    ninja -C build -j"$JOBS"
    DESTDIR="$ROOTFS_DIR" ninja -C build install

    success "elogind: installed"
else
    info "elogind: already installed"
fi

cd "$PROJECT_ROOT"
build_summary "$PHASE" "$START_TIME"
