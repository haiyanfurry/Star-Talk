#!/bin/sh
# ╔══════════════════════════════════════════════════════════════════════╗
# ║  Star-Talk / 星语 — NetBSD Kernel Build Script                    ║
# ║  Builds the SWIMSTAR kernel for amd64                              ║
# ╚══════════════════════════════════════════════════════════════════════╝
set -e
. "$(dirname "$0")/utils-netbsd.sh"

PHASE="N01"
START_TIME=$(date +%s)
step "Phase ${PHASE}: Building NetBSD kernel (SWIMSTAR)"

# ── Fetch source ──────────────────────────────────────────────────────
fetch_netbsd_src || die "NetBSD source not available"

# ── Copy kernel config ────────────────────────────────────────────────
step "Installing SWIMSTAR kernel config..."
KERNEL_CONF_SRC="$CONFIGS_DIR/netbsd/kernel/SWIMSTAR"
KERNEL_CONF_DEST="$NETBSD_SRC_DIR/sys/arch/${NETBSD_ARCH}/conf/SWIMSTAR"

if [ -f "$KERNEL_CONF_SRC" ]; then
    cp "$KERNEL_CONF_SRC" "$KERNEL_CONF_DEST"
    success "Kernel config SWIMSTAR installed"
else
    die "Kernel config not found: $KERNEL_CONF_SRC"
fi

# ── Build tools first (if not already built) ──────────────────────────
step "Building NetBSD toolchain..."
cd "$NETBSD_SRC_DIR"
if [ ! -x "$NETBSD_TOOLDIR/bin/nbmake-${NETBSD_ARCH}" ]; then
    ./build.sh -m "$NETBSD_ARCH" -j "$JOBS" -U \
        -T "$NETBSD_TOOLDIR" -O "$NETBSD_OBJ_DIR" \
        tools 2>&1 | tail -5
    success "Toolchain built"
else
    info "Toolchain already built"
fi

# ── Build kernel ──────────────────────────────────────────────────────
step "Building SWIMSTAR kernel (${JOBS} jobs)..."

./build.sh -m "$NETBSD_ARCH" -j "$JOBS" -U \
    -T "$NETBSD_TOOLDIR" -O "$NETBSD_OBJ_DIR" \
    kernel=SWIMSTAR 2>&1 | tail -10

if [ -f "$NETBSD_OBJ_DIR/sys/arch/${NETBSD_ARCH}/compile/SWIMSTAR/netbsd" ]; then
    cp "$NETBSD_OBJ_DIR/sys/arch/${NETBSD_ARCH}/compile/SWIMSTAR/netbsd" "$OUT_DIR/netbsd"
    success "Kernel built: $OUT_DIR/netbsd ($(du -h "$OUT_DIR/netbsd" | cut -f1))"
else
    die "Kernel build failed — check output above"
fi

cd "$PROJECT_ROOT"
build_summary "$PHASE" "$START_TIME"
