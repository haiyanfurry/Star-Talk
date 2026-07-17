#!/bin/sh
# ╔══════════════════════════════════════════════════════════════════════╗
# ║  Star-Talk / 星语 — NetBSD Userland Build                         ║
# ║  Builds distribution + release (base system)                       ║
# ╚══════════════════════════════════════════════════════════════════════╝
set -e
. "$(dirname "$0")/utils-netbsd.sh"

PHASE="N02"
START_TIME=$(date +%s)
step "Phase ${PHASE}: Building NetBSD userland (distribution)"

fetch_netbsd_src || die "NetBSD source not available"

cd "$NETBSD_SRC_DIR"

# ── Build distribution ────────────────────────────────────────────────
step "Building distribution (this takes a while — ${JOBS} jobs)..."
./build.sh -m "$NETBSD_ARCH" -j "$JOBS" -U \
    -T "$NETBSD_TOOLDIR" -O "$NETBSD_OBJ_DIR" \
    -D "$NETBSD_DESTDIR" \
    distribution 2>&1 | tail -5

success "Distribution built"

# ── Build release (ISO images, sets) ──────────────────────────────────
step "Building release..."
./build.sh -m "$NETBSD_ARCH" -j "$JOBS" -U \
    -T "$NETBSD_TOOLDIR" -O "$NETBSD_OBJ_DIR" \
    -D "$NETBSD_DESTDIR" \
    release 2>&1 | tail -5

success "Release built"

# ── Copy to output ────────────────────────────────────────────────────
step "Copying release artifacts..."
cp -r "$NETBSD_DESTDIR"/* "$ROOTFS_DIR/" 2>/dev/null || {
    substep "Using destdir directly as staging"
    ROOTFS_DIR="$NETBSD_DESTDIR"
}

info "Userland at: $ROOTFS_DIR"
success "NetBSD userland ready"

cd "$PROJECT_ROOT"
build_summary "$PHASE" "$START_TIME"
