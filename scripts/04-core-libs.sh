#!/bin/bash
# ╔══════════════════════════════════════════════════════════════╗
# ║     Star-Talk / 星语 — 04-core-libs.sh                    ║
# ║     Build zlib, openssl, ncurses, util-linux, etc.        ║
# ╚══════════════════════════════════════════════════════════════╝
set -euo pipefail
source "$(dirname "$0")/utils.sh"

PHASE="04"
START_TIME=$(date +%s)
step "Phase ${PHASE}: Building core system libraries"

# ── zlib ─────────────────────────────────────────────────────────
step "Building zlib 1.3.1"
ZLIB_DIR="$BUILD_DIR/zlib-1.3.1"
if [ ! -f "$ROOTFS_DIR/usr/lib/libz.so.1" ]; then
    extract_to "$SOURCES_DIR/zlib-1.3.1.tar.xz" "$(dirname "$ZLIB_DIR")"
    cd "$ZLIB_DIR"
    ./configure --prefix=/usr
    make -j"$JOBS"
    make DESTDIR="$ROOTFS_DIR" install
    success "zlib: installed"
else
    info "zlib: already installed"
fi

# ── xz (LZMA) ───────────────────────────────────────────────────
step "Building xz 5.6.4"
XZ_DIR="$BUILD_DIR/xz-5.6.4"
if [ ! -f "$ROOTFS_DIR/usr/lib/liblzma.so" ]; then
    extract_to "$SOURCES_DIR/xz-5.6.4.tar.xz" "$(dirname "$XZ_DIR")"
    cd "$XZ_DIR"
    ./configure --prefix=/usr --disable-static
    make -j"$JOBS"
    make DESTDIR="$ROOTFS_DIR" install
    success "xz: installed"
else
    info "xz: already installed"
fi

# ── zstd ─────────────────────────────────────────────────────────
step "Building zstd 1.5.7"
ZSTD_DIR="$BUILD_DIR/zstd-1.5.7"
if [ ! -f "$ROOTFS_DIR/usr/lib/libzstd.so" ]; then
    extract_to "$SOURCES_DIR/zstd-1.5.7.tar.gz" "$(dirname "$ZSTD_DIR")"
    cd "$ZSTD_DIR"
    make -j"$JOBS" prefix=/usr
    make DESTDIR="$ROOTFS_DIR" prefix=/usr install
    success "zstd: installed"
else
    info "zstd: already installed"
fi

# ── libffi ───────────────────────────────────────────────────────
step "Building libffi 3.4.7"
LIBFFI_DIR="$BUILD_DIR/libffi-3.4.7"
if [ ! -f "$ROOTFS_DIR/usr/lib/libffi.so" ]; then
    extract_to "$SOURCES_DIR/libffi-3.4.7.tar.gz" "$(dirname "$LIBFFI_DIR")"
    cd "$LIBFFI_DIR"
    ./configure --prefix=/usr --disable-static
    make -j"$JOBS"
    make DESTDIR="$ROOTFS_DIR" install
    success "libffi: installed"
else
    info "libffi: already installed"
fi

# ── ncurses ──────────────────────────────────────────────────────
step "Building ncurses 6.5"
NCURSES_DIR="$BUILD_DIR/ncurses-6.5"
if [ ! -f "$ROOTFS_DIR/usr/lib/libncursesw.so" ]; then
    extract_to "$SOURCES_DIR/ncurses-6.5.tar.gz" "$(dirname "$NCURSES_DIR")"
    cd "$NCURSES_DIR"
    ./configure --prefix=/usr --with-shared --with-termlib \
        --enable-widec --enable-pc-files \
        --without-debug --without-ada --without-manpages
    make -j"$JOBS"
    make DESTDIR="$ROOTFS_DIR" install
    success "ncurses: installed"
else
    info "ncurses: already installed"
fi

# ── readline ─────────────────────────────────────────────────────
step "Building readline 8.2"
READLINE_DIR="$BUILD_DIR/readline-8.2"
if [ ! -f "$ROOTFS_DIR/usr/lib/libreadline.so" ]; then
    extract_to "$SOURCES_DIR/readline-8.2.tar.gz" "$(dirname "$READLINE_DIR")"
    cd "$READLINE_DIR"
    ./configure --prefix=/usr --disable-static
    make -j"$JOBS"
    make DESTDIR="$ROOTFS_DIR" install
    success "readline: installed"
else
    info "readline: already installed"
fi

# ── openssl ──────────────────────────────────────────────────────
step "Building openssl 3.5.0"
OPENSSL_DIR="$BUILD_DIR/openssl-3.5.0"
if [ ! -f "$ROOTFS_DIR/usr/lib/libssl.so" ]; then
    extract_to "$SOURCES_DIR/openssl-3.5.0.tar.gz" "$(dirname "$OPENSSL_DIR")"
    cd "$OPENSSL_DIR"
    ./Configure --prefix=/usr --openssldir=/etc/ssl \
        enable-ec_nistp_64_gcc_128 linux-x86_64 \
        no-tests no-docs
    make -j"$JOBS"
    make DESTDIR="$ROOTFS_DIR" install_sw
    success "openssl: installed"
else
    info "openssl: already installed"
fi

# ── expat ────────────────────────────────────────────────────────
step "Building expat 2.7.1"
EXPAT_DIR="$BUILD_DIR/expat-2.7.1"
if [ ! -f "$ROOTFS_DIR/usr/lib/libexpat.so" ]; then
    extract_to "$SOURCES_DIR/expat-2.7.1.tar.xz" "$(dirname "$EXPAT_DIR")"
    cd "$EXPAT_DIR"
    ./configure --prefix=/usr --without-docbook
    make -j"$JOBS"
    make DESTDIR="$ROOTFS_DIR" install
    success "expat: installed"
else
    info "expat: already installed"
fi

# ── libcap ───────────────────────────────────────────────────────
step "Building libcap 2.72"
LIBCAP_DIR="$BUILD_DIR/libcap-2.72"
if [ ! -f "$ROOTFS_DIR/usr/lib/libcap.so" ]; then
    extract_to "$SOURCES_DIR/libcap-2.72.tar.gz" "$(dirname "$LIBCAP_DIR")"
    cd "$LIBCAP_DIR"
    make -j"$JOBS" prefix=/usr
    make DESTDIR="$ROOTFS_DIR" prefix=/usr lib=lib install
    success "libcap: installed"
else
    info "libcap: already installed"
fi

# ── util-linux ───────────────────────────────────────────────────
step "Building util-linux 2.41"
UTIL_DIR="$BUILD_DIR/util-linux-2.41"
if [ ! -f "$ROOTFS_DIR/usr/bin/mount" ] || [ ! -f "$ROOTFS_DIR/usr/sbin/blkid" ]; then
    extract_to "$SOURCES_DIR/util-linux-2.41.tar.gz" "$(dirname "$UTIL_DIR")"
    cd "$UTIL_DIR"
    ./configure --prefix=/usr --disable-static \
        --disable-makeinstall-chown --disable-makeinstall-setuid \
        --without-systemd --without-python \
        --enable-libblkid --enable-libmount --enable-libuuid
    make -j"$JOBS"
    make DESTDIR="$ROOTFS_DIR" install
    success "util-linux: installed"
else
    info "util-linux: already installed"
fi

cd "$PROJECT_ROOT"
build_summary "$PHASE" "$START_TIME"
