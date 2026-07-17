#!/bin/sh
# ╔══════════════════════════════════════════════════════════════════════╗
# ║  Star-Talk / 星语 — NetBSD Build Utilities                        ║
# ║  Shared functions for all NetBSD build scripts                     ║
# ╚══════════════════════════════════════════════════════════════════════╝
#
# Source this in all NetBSD build scripts:
#   . "$(dirname "$0")/utils-netbsd.sh"

set -e

# ── Color output ──────────────────────────────────────────────────────
RED='\033[0;31m'; GREEN='\033[0;32m'; CYAN='\033[0;36m'
YELLOW='\033[1;33m'; BOLD='\033[1m'; NC='\033[0m'

# ── Global paths ──────────────────────────────────────────────────────
: "${PROJECT_ROOT:=$(cd "$(dirname "$0")/../.." && pwd)}"
: "${WORK_DIR:=$PROJECT_ROOT/work}"
: "${OUT_DIR:=$PROJECT_ROOT/out}"
: "${CONFIGS_DIR:=$PROJECT_ROOT/configs}"
: "${BRANDING_DIR:=$PROJECT_ROOT/branding}"

# Use local NetBSD source tree if available (priority 1),
# fall back to work/ download otherwise.
if [ -f "$PROJECT_ROOT/NetBSD/src/build.sh" ]; then
    NETBSD_SRC_DIR="$PROJECT_ROOT/NetBSD/src"
elif [ -d "$WORK_DIR/netbsd-src" ]; then
    NETBSD_SRC_DIR="$WORK_DIR/netbsd-src"
else
    NETBSD_SRC_DIR="$WORK_DIR/netbsd-src"
fi
NETBSD_OBJ_DIR="$WORK_DIR/netbsd-obj"
NETBSD_DESTDIR="$WORK_DIR/netbsd-dest"
NETBSD_TOOLDIR="$WORK_DIR/netbsd-tools"
ROOTFS_DIR="$WORK_DIR/rootfs-staging"

# pkgsrc — check local NetBSD dir first
if [ -d "$PROJECT_ROOT/NetBSD/pkgsrc/Makefile" ]; then
    PKGSRC_DIR="$PROJECT_ROOT/NetBSD/pkgsrc"
elif [ -d "$WORK_DIR/pkgsrc" ]; then
    PKGSRC_DIR="$WORK_DIR/pkgsrc"
else
    PKGSRC_DIR="$WORK_DIR/pkgsrc"
fi

: "${JOBS:=$(sysctl -n hw.ncpu 2>/dev/null || nproc 2>/dev/null || echo 4)}"
: "${NETBSD_VER:=10.1}"
: "${NETBSD_ARCH:=amd64}"

# Ensure directories
mkdir -p "$OUT_DIR" "$WORK_DIR"

# ── Logging functions ─────────────────────────────────────────────────
step()   { printf "${CYAN}[STEP]${NC} $(date '+%H:%M:%S') — %s\n" "$*"; }
substep(){ printf "${CYAN}  └─${NC} %s\n" "$*"; }
success(){ printf "${GREEN}[ OK ]${NC} $(date '+%H:%M:%S') — %s\n" "$*"; }
info()   { printf "${BOLD}[INFO]${NC} %s\n" "$*"; }
warn()   { printf "${YELLOW}[WARN]${NC} %s\n" "$*"; }
die()    { printf "${RED}[FAIL]${NC} $(date '+%H:%M:%S') — %s\n" "$*"; exit 1; }

# ── Check prerequisites ───────────────────────────────────────────────
check_prereq() {
    local missing=""
    for cmd in git curl tar make gcc; do
        command -v "$cmd" >/dev/null 2>&1 || missing="$missing $cmd"
    done
    if [ -n "$missing" ]; then
        warn "Missing build tools:$missing"
        info "On NetBSD: pkgin install git curl"
        info "On Linux:  apt install git curl build-essential (cross-building)"
    fi
}

# ── Fetch NetBSD source ───────────────────────────────────────────────
fetch_netbsd_src() {
    # Priority 1: Use local source tree (already present)
    if [ -f "$NETBSD_SRC_DIR/build.sh" ]; then
        info "Using local NetBSD source: $NETBSD_SRC_DIR"
        info "Source size: $(du -sh "$NETBSD_SRC_DIR" 2>/dev/null | cut -f1)"
        return 0
    fi

    step "Fetching NetBSD ${NETBSD_VER} source tree..."

    # Try local tarball first
    local tarball="$PROJECT_ROOT/src/tarballs/netbsd-${NETBSD_VER}-src.tar.xz"
    if [ -f "$tarball" ]; then
        substep "Extracting local source tarball..."
        mkdir -p "$NETBSD_SRC_DIR"
        tar -xJf "$tarball" -C "$NETBSD_SRC_DIR" --strip-components=1
        success "NetBSD source extracted from local tarball"
        return 0
    fi

    # Fetch from official mirror
    substep "Downloading from NetBSD CDN..."
    local netbsd_url="https://cdn.netbsd.org/pub/NetBSD/NetBSD-${NETBSD_VER}/source/sets/src.tgz"

    curl -sL --connect-timeout 30 -o "$WORK_DIR/netbsd-src.tgz" "$netbsd_url" || \
        curl -sL --connect-timeout 30 -o "$WORK_DIR/netbsd-src.tgz" \
            "https://github.com/NetBSD/src/archive/refs/tags/netbsd-${NETBSD_VER//./-}.tar.gz"

    if [ -s "$WORK_DIR/netbsd-src.tgz" ]; then
        mkdir -p "$NETBSD_SRC_DIR"
        tar -xzf "$WORK_DIR/netbsd-src.tgz" -C "$NETBSD_SRC_DIR" --strip-components=1 2>/dev/null || \
            tar -xzf "$WORK_DIR/netbsd-src.tgz" -C "$NETBSD_SRC_DIR"
        success "NetBSD source downloaded and extracted"
        rm -f "$WORK_DIR/netbsd-src.tgz"
    else
        warn "Could not download NetBSD source automatically."
        info "Clone it manually:"
        info "  git clone https://github.com/NetBSD/src $NETBSD_SRC_DIR"
        return 1
    fi
}

# ── Fetch pkgsrc ──────────────────────────────────────────────────────
fetch_pkgsrc() {
    if [ -d "$PKGSRC_DIR" ] && [ -f "$PKGSRC_DIR/Makefile" ]; then
        info "pkgsrc already present at $PKGSRC_DIR"
        return 0
    fi

    step "Fetching pkgsrc tree..."
    local pkgsrc_url="https://cdn.netbsd.org/pub/pkgsrc/current/pkgsrc.tar.gz"

    curl -sL --connect-timeout 30 -o "$WORK_DIR/pkgsrc.tar.gz" "$pkgsrc_url" || {
        warn "Could not download pkgsrc. Please place it at: $PKGSRC_DIR"
        return 1
    }

    mkdir -p "$PKGSRC_DIR"
    tar -xzf "$WORK_DIR/pkgsrc.tar.gz" -C "$PKGSRC_DIR" --strip-components=1
    success "pkgsrc downloaded"
}

# ── Build summary ─────────────────────────────────────────────────────
build_summary() {
    local phase="$1" start_time="$2"
    local elapsed=$(($(date +%s) - start_time))
    printf "\n"
    printf "${GREEN}╔══════════════════════════════════════════════════════════════╗${NC}\n"
    printf "${GREEN}║  Phase ${phase} complete — ${elapsed}s elapsed${NC}\n"
    printf "${GREEN}╚══════════════════════════════════════════════════════════════╝${NC}\n"
    printf "\n"
}

check_prereq
