#!/bin/bash
# ╔══════════════════════════════════════════════════════════════╗
# ║     Star-Talk / 星语 — 00-prepare.sh                      ║
# ║     Create directories, download all source tarballs       ║
# ╚══════════════════════════════════════════════════════════════╝
set -euo pipefail
source "$(dirname "$0")/utils.sh"

PHASE="00"
START_TIME=$(date +%s)

step "Phase ${PHASE}: Preparing build environment"

# ── Create directory structure ───────────────────────────────────
step "Creating directory structure..."
mkdir -p "$OUT_DIR"
mkdir -p "$SOURCES_DIR"
mkdir -p "$BUILD_DIR"
mkdir -p "$SYSROOT_DIR"
mkdir -p "$INITRAMFS_DIR/bin"
mkdir -p "$INITRAMFS_DIR"/{dev,proc,sys,tmp,run,mnt/root}
mkdir -p "$ROOTFS_DIR"/{etc/init.d,usr/{bin,sbin,lib,share},opt,var/log,home/startalk,dev,proc,sys,run,tmp}
success "Directories created"

# ── Package version definitions ──────────────────────────────────
# Format: PKG_VER_pkgname="version"
PKG_VER_binutils="2.44"
PKG_VER_gcc="16.1.0"
PKG_VER_glibc="2.41"
PKG_VER_busybox="1.37.0"
PKG_VER_zlib="1.3.1"
PKG_VER_xz="5.6.4"
PKG_VER_zstd="1.5.7"
PKG_VER_libffi="3.4.7"
PKG_VER_ncurses="6.5"
PKG_VER_readline="8.2"
PKG_VER_openssl="3.5.0"
PKG_VER_expat="2.7.1"
PKG_VER_libxml2="2.14.0"
PKG_VER_libcap="2.72"
PKG_VER_util_linux="2.41"
PKG_VER_dbus="1.16.2"
PKG_VER_elogind="255.7"
PKG_VER_libdrm="2.4.124"
PKG_VER_wayland="1.24.0"
PKG_VER_wayland_protocols="1.43"
PKG_VER_mesa="25.2.0"
PKG_VER_libxkbcommon="1.8.1"
PKG_VER_pixman="0.44.2"
PKG_VER_cairo="1.18.4"
PKG_VER_pango="1.56.2"
PKG_VER_libinput="1.28.1"
PKG_VER_libevdev="1.13.4"
PKG_VER_vulkan_loader="1.4.309"
PKG_VER_jsoncpp="1.9.6"
PKG_VER_fmt="11.1.4"
PKG_VER_spdlog="1.15.2"
PKG_VER_niri="25.02"
PKG_VER_waybar="0.11.0"
PKG_VER_wofi="1.4.1"
PKG_VER_foot="1.20.2"
PKG_VER_swaybg="1.2.1"
PKG_VER_swaylock="1.8.0"
PKG_VER_mako="1.9.0"
PKG_VER_pipewire="1.4.2"
PKG_VER_wireplumber="0.5.8"
PKG_VER_libevent="2.1.12"
PKG_VER_tor="0.4.8.16"
PKG_VER_obfs4proxy="0.0.14"
PKG_VER_i2pd="2.55.0"
PKG_VER_boost="1.87.0"

# ── Download all sources in parallel ─────────────────────────────
step "Downloading source tarballs..."

download_source() {
    local pkg="$1" ver="$2" url="$3"
    local dest="$SOURCES_DIR/${pkg}-${ver}.tar.${url##*.}"
    [ -f "$dest" ] && { info "Already have ${pkg}-${ver}"; return 0; }
    substep "Downloading ${pkg} ${ver}"
    download "$url" "$dest" &
}

# Core toolchain
download_source "binutils" "$PKG_VER_binutils" \
    "https://ftp.gnu.org/gnu/binutils/binutils-${PKG_VER_binutils}.tar.xz"

download_source "gcc" "$PKG_VER_gcc" \
    "https://ftp.gnu.org/gnu/gcc/gcc-${PKG_VER_gcc}/gcc-${PKG_VER_gcc}.tar.xz"

download_source "glibc" "$PKG_VER_glibc" \
    "https://ftp.gnu.org/gnu/glibc/glibc-${PKG_VER_glibc}.tar.xz"

download_source "busybox" "$PKG_VER_busybox" \
    "https://busybox.net/downloads/busybox-${PKG_VER_busybox}.tar.bz2"

# Libraries
download_source "zlib" "$PKG_VER_zlib" \
    "https://zlib.net/zlib-${PKG_VER_zlib}.tar.xz"

download_source "xz" "$PKG_VER_xz" \
    "https://github.com/tukaani-project/xz/releases/download/v${PKG_VER_xz}/xz-${PKG_VER_xz}.tar.xz"

download_source "zstd" "$PKG_VER_zstd" \
    "https://github.com/facebook/zstd/releases/download/v${PKG_VER_zstd}/zstd-${PKG_VER_zstd}.tar.gz"

download_source "libffi" "$PKG_VER_libffi" \
    "https://github.com/libffi/libffi/releases/download/v${PKG_VER_libffi}/libffi-${PKG_VER_libffi}.tar.gz"

download_source "ncurses" "$PKG_VER_ncurses" \
    "https://ftp.gnu.org/gnu/ncurses/ncurses-${PKG_VER_ncurses}.tar.gz"

download_source "readline" "$PKG_VER_readline" \
    "https://ftp.gnu.org/gnu/readline/readline-${PKG_VER_readline}.tar.gz"

download_source "openssl" "$PKG_VER_openssl" \
    "https://www.openssl.org/source/openssl-${PKG_VER_openssl}.tar.gz"

download_source "expat" "$PKG_VER_expat" \
    "https://github.com/libexpat/libexpat/releases/download/R_${PKG_VER_expat//./_}/expat-${PKG_VER_expat}.tar.xz"

download_source "libxml2" "$PKG_VER_libxml2" \
    "https://download.gnome.org/sources/libxml2/${PKG_VER_libxml2%.*}/libxml2-${PKG_VER_libxml2}.tar.xz"

download_source "libcap" "$PKG_VER_libcap" \
    "https://git.kernel.org/pub/scm/libs/libcap/libcap.git/snapshot/libcap-${PKG_VER_libcap}.tar.gz"

download_source "util-linux" "$PKG_VER_util_linux" \
    "https://git.kernel.org/pub/scm/utils/util-linux/util-linux.git/snapshot/util-linux-${PKG_VER_util_linux}.tar.gz"

# System daemons
download_source "dbus" "$PKG_VER_dbus" \
    "https://dbus.freedesktop.org/releases/dbus/dbus-${PKG_VER_dbus}.tar.xz"

download_source "elogind" "v${PKG_VER_elogind}" \
    "https://github.com/elogind/elogind/archive/refs/tags/v${PKG_VER_elogind}.tar.gz"

# Graphics stack
download_source "libdrm" "$PKG_VER_libdrm" \
    "https://dri.freedesktop.org/libdrm/libdrm-${PKG_VER_libdrm}.tar.xz"

download_source "wayland" "$PKG_VER_wayland" \
    "https://gitlab.freedesktop.org/wayland/wayland/-/releases/${PKG_VER_wayland}/downloads/wayland-${PKG_VER_wayland}.tar.xz"

download_source "wayland-protocols" "$PKG_VER_wayland_protocols" \
    "https://gitlab.freedesktop.org/wayland/wayland-protocols/-/releases/${PKG_VER_wayland_protocols}/downloads/wayland-protocols-${PKG_VER_wayland_protocols}.tar.xz"

download_source "mesa" "$PKG_VER_mesa" \
    "https://archive.mesa3d.org/mesa-${PKG_VER_mesa}.tar.xz"

download_source "libxkbcommon" "$PKG_VER_libxkbcommon" \
    "https://xkbcommon.org/download/libxkbcommon-${PKG_VER_libxkbcommon}.tar.xz"

download_source "pixman" "$PKG_VER_pixman" \
    "https://cairographics.org/releases/pixman-${PKG_VER_pixman}.tar.gz"

download_source "cairo" "$PKG_VER_cairo" \
    "https://cairographics.org/releases/cairo-${PKG_VER_cairo}.tar.xz"

download_source "pango" "$PKG_VER_pango" \
    "https://download.gnome.org/sources/pango/${PKG_VER_pango%.*}/pango-${PKG_VER_pango}.tar.xz"

download_source "libinput" "$PKG_VER_libinput" \
    "https://gitlab.freedesktop.org/libinput/libinput/-/archive/${PKG_VER_libinput}/libinput-${PKG_VER_libinput}.tar.gz"

download_source "libevdev" "$PKG_VER_libevdev" \
    "https://gitlab.freedesktop.org/libevdev/libevdev/-/archive/${PKG_VER_libevdev}/libevdev-${PKG_VER_libevdev}.tar.gz"

download_source "vulkan-loader" "sdk-${PKG_VER_vulkan_loader}" \
    "https://github.com/KhronosGroup/Vulkan-Loader/archive/refs/tags/sdk-${PKG_VER_vulkan_loader}.tar.gz"

# Desktop
download_source "waybar" "$PKG_VER_waybar" \
    "https://github.com/Alexays/Waybar/archive/refs/tags/${PKG_VER_waybar}.tar.gz"

download_source "wofi" "v${PKG_VER_wofi}" \
    "https://github.com/SimplyCEO/wofi/archive/refs/tags/v${PKG_VER_wofi}.tar.gz"

download_source "foot" "$PKG_VER_foot" \
    "https://codeberg.org/dnkl/foot/archive/${PKG_VER_foot}.tar.gz"

download_source "swaybg" "$PKG_VER_swaybg" \
    "https://github.com/swaywm/swaybg/archive/refs/tags/${PKG_VER_swaybg}.tar.gz"

download_source "swaylock" "$PKG_VER_swaylock" \
    "https://github.com/swaywm/swaylock/archive/refs/tags/${PKG_VER_swaylock}.tar.gz"

download_source "mako" "v${PKG_VER_mako}" \
    "https://github.com/emersion/mako/archive/refs/tags/v${PKG_VER_mako}.tar.gz"

# Audio
download_source "pipewire" "$PKG_VER_pipewire" \
    "https://gitlab.freedesktop.org/pipewire/pipewire/-/archive/${PKG_VER_pipewire}/pipewire-${PKG_VER_pipewire}.tar.gz"

download_source "wireplumber" "$PKG_VER_wireplumber" \
    "https://gitlab.freedesktop.org/pipewire/wireplumber/-/archive/${PKG_VER_wireplumber}/wireplumber-${PKG_VER_wireplumber}.tar.gz"

# Anonymity
download_source "libevent" "$PKG_VER_libevent" \
    "https://github.com/libevent/libevent/releases/download/release-${PKG_VER_libevent}-stable/libevent-${PKG_VER_libevent}-stable.tar.gz"

download_source "tor" "$PKG_VER_tor" \
    "https://dist.torproject.org/tor-${PKG_VER_tor}.tar.gz"

download_source "i2pd" "$PKG_VER_i2pd" \
    "https://github.com/PurpleI2P/i2pd/archive/refs/tags/${PKG_VER_i2pd}.tar.gz"

# JSON, fmt, spdlog (waybar deps)
download_source "jsoncpp" "$PKG_VER_jsoncpp" \
    "https://github.com/open-source-parsers/jsoncpp/archive/refs/tags/${PKG_VER_jsoncpp}.tar.gz"

download_source "fmt" "$PKG_VER_fmt" \
    "https://github.com/fmtlib/fmt/archive/refs/tags/${PKG_VER_fmt}.tar.gz"

download_source "spdlog" "v${PKG_VER_spdlog}" \
    "https://github.com/gabime/spdlog/archive/refs/tags/v${PKG_VER_spdlog}.tar.gz"

# Wait for all downloads to finish
wait

success "All sources downloaded"

# ── Summary ──────────────────────────────────────────────────────
info "Sources directory: $SOURCES_DIR"
info "Source count: $(ls "$SOURCES_DIR" | wc -l) files"

build_summary "$PHASE" "$START_TIME"
