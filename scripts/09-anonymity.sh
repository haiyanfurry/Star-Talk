#!/bin/bash
# ╔══════════════════════════════════════════════════════════════╗
# ║     Star-Talk / 星语 — 09-anonymity.sh                   ║
# ║     Build Tor, obfs4proxy, i2pd                           ║
# ╚══════════════════════════════════════════════════════════════╝
set -euo pipefail
source "$(dirname "$0")/utils.sh"

PHASE="09"
START_TIME=$(date +%s)
step "Phase ${PHASE}: Building anonymity tools"

# ── libevent (tor dependency) ────────────────────────────────────
step "Building libevent 2.1.12"
LE_DIR="$BUILD_DIR/libevent-2.1.12-stable"
if [ ! -f "$ROOTFS_DIR/usr/lib/libevent.so" ]; then
    extract_to "$SOURCES_DIR/libevent-2.1.12-stable.tar.gz" "$(dirname "$LE_DIR")"
    cd "$LE_DIR"
    ./configure --prefix=/usr --disable-static
    make -j"$JOBS"
    make DESTDIR="$ROOTFS_DIR" install
    success "libevent: installed"
else
    info "libevent: already installed"
fi

# ── Tor ──────────────────────────────────────────────────────────
step "Building Tor 0.4.8.16"
TOR_DIR="$BUILD_DIR/tor-0.4.8.16"
if [ ! -f "$ROOTFS_DIR/usr/bin/tor" ]; then
    extract_to "$SOURCES_DIR/tor-0.4.8.16.tar.gz" "$(dirname "$TOR_DIR")"
    cd "$TOR_DIR"
    ./configure --prefix=/usr \
        --sysconfdir=/etc \
        --localstatedir=/var \
        --disable-systemd
    make -j"$JOBS"
    make DESTDIR="$ROOTFS_DIR" install

    # Create tor user and data directory
    mkdir -p "$ROOTFS_DIR/var/lib/tor"
    mkdir -p "$ROOTFS_DIR/etc/tor"
    success "tor: installed"
else
    info "tor: already installed"
fi

# ── obfs4proxy (Tor bridge, requires Go) ─────────────────────────
step "Building obfs4proxy 0.0.14"
if [ ! -f "$ROOTFS_DIR/usr/bin/obfs4proxy" ]; then
    if command -v go &>/dev/null; then
        OBFS4_DIR="$BUILD_DIR/obfs4proxy"
        mkdir -p "$OBFS4_DIR"
        cd "$OBFS4_DIR"
        # Download and build
        go get gitlab.com/yawning/obfs4.git/cmd/obfs4proxy 2>/dev/null || true
        go build -o obfs4proxy gitlab.com/yawning/obfs4.git/cmd/obfs4proxy 2>/dev/null || {
            warn "Could not compile obfs4proxy from source"
            # Try downloading pre-built
            download "https://github.com/Yawning/obfs4/releases/download/obfs4proxy-0.0.14/obfs4proxy-0.0.14-linux-x86_64.tar.gz" \
                "$SOURCES_DIR/obfs4proxy.tar.gz" 2>/dev/null || true
            if [ -f "$SOURCES_DIR/obfs4proxy.tar.gz" ]; then
                tar -xzf "$SOURCES_DIR/obfs4proxy.tar.gz" -C "$OBFS4_DIR"
                cp "$OBFS4_DIR/obfs4proxy" "$ROOTFS_DIR/usr/bin/" 2>/dev/null || true
            fi
        }
        [ -f obfs4proxy ] && cp obfs4proxy "$ROOTFS_DIR/usr/bin/"
        success "obfs4proxy: installed"
    else
        warn "Go not available — downloading pre-built obfs4proxy"
        download "https://github.com/Yawning/obfs4/releases/download/obfs4proxy-0.0.14/obfs4proxy-0.0.14-linux-x86_64.tar.gz" \
            "$SOURCES_DIR/obfs4proxy.tar.gz"
        extract_to "$SOURCES_DIR/obfs4proxy.tar.gz" "$BUILD_DIR/obfs4proxy-prebuilt"
        cp "$BUILD_DIR/obfs4proxy-prebuilt/obfs4proxy" "$ROOTFS_DIR/usr/bin/" 2>/dev/null || \
            warn "Could not find obfs4proxy binary in tarball"
        success "obfs4proxy: pre-built"
    fi
else
    info "obfs4proxy: already installed"
fi

# ── i2pd (I2P daemon, requires C++17) ────────────────────────────
step "Building i2pd 2.55.0"
I2PD_DIR="$BUILD_DIR/i2pd-2.55.0"
if [ ! -f "$ROOTFS_DIR/usr/bin/i2pd" ]; then
    extract_to "$SOURCES_DIR/i2pd-2.55.0.tar.gz" "$(dirname "$I2PD_DIR")"
    cd "$I2PD_DIR"

    if [ -d "build" ]; then
        cd build
    else
        mkdir -p build && cd build
        cmake .. -DCMAKE_INSTALL_PREFIX=/usr \
            -DCMAKE_BUILD_TYPE=Release \
            -DWITH_BINARY=ON \
            -DWITH_STATIC=OFF \
            -DWITH_UPNP=OFF
    fi

    make -j"$JOBS"
    make DESTDIR="$ROOTFS_DIR" install

    mkdir -p "$ROOTFS_DIR/var/lib/i2pd"
    mkdir -p "$ROOTFS_DIR/etc/i2pd"
    success "i2pd: installed"
else
    info "i2pd: already installed"
fi

cd "$PROJECT_ROOT"
build_summary "$PHASE" "$START_TIME"
