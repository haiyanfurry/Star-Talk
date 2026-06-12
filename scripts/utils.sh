#!/bin/bash
# ╔══════════════════════════════════════════════════════════════╗
# ║     Star-Talk / 星语 — Build Utilities                     ║
# ╚══════════════════════════════════════════════════════════════╝
# Source this in all build scripts:
#   source "$(dirname "$0")/utils.sh"

set -euo pipefail

# ── Color output ─────────────────────────────────────────────────
export RED='\033[0;31m'
export GREEN='\033[0;32m'
export CYAN='\033[0;36m'
export YELLOW='\033[1;33m'
export BOLD='\033[1m'
export NC='\033[0m' # No Color

# ── Global paths ─────────────────────────────────────────────────
export PROJECT_ROOT="${PROJECT_ROOT:-$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)}"
export WORK_DIR="${WORK_DIR:-$PROJECT_ROOT/work}"
export OUT_DIR="${OUT_DIR:-$PROJECT_ROOT/out}"
export INITRAMFS_DIR="${INITRAMFS_DIR:-$PROJECT_ROOT/initramfs}"
export ROOTFS_DIR="${ROOTFS_DIR:-$PROJECT_ROOT/rootfs}"
export CONFIGS_DIR="${CONFIGS_DIR:-$PROJECT_ROOT/configs}"
export SOURCES_DIR="$WORK_DIR/sources"
export BUILD_DIR="$WORK_DIR/build"
export SYSROOT_DIR="$WORK_DIR/sysroot"
export JOBS="${JOBS:-$(nproc)}"

# Ensure output directories exist
mkdir -p "$OUT_DIR" "$SOURCES_DIR" "$BUILD_DIR" "$SYSROOT_DIR"

# ── Logging functions ────────────────────────────────────────────
step() {
    echo -e "${CYAN}[STEP]${NC} $(date '+%H:%M:%S') — $*"
}

substep() {
    echo -e "${CYAN}  └─${NC} $*"
}

success() {
    echo -e "${GREEN}[ OK ]${NC} $(date '+%H:%M:%S') — $*"
}

info() {
    echo -e "${BOLD}[INFO]${NC} $*"
}

warn() {
    echo -e "${YELLOW}[WARN]${NC} $*"
}

die() {
    echo -e "${RED}[FAIL]${NC} $(date '+%H:%M:%S') — $*"
    exit 1
}

# ── Download helper (supports proxy) ─────────────────────────────
download() {
    local url="$1"
    local dest="${2:-}"
    local filename

    if [ -z "$dest" ]; then
        filename="$(basename "$url")"
        dest="$SOURCES_DIR/$filename"
    fi

    if [ -f "$dest" ] && [ -s "$dest" ]; then
        info "Already downloaded: $(basename "$dest")"
        return 0
    fi

    substep "Downloading: $url"

    # Try proxy first (port 10808 as configured by user)
    if curl -s --proxy http://127.0.0.1:10808 --connect-timeout 5 -o "$dest" "$url" 2>/dev/null; then
        return 0
    fi

    # Try direct
    if curl -sL --connect-timeout 10 -o "$dest" "$url" 2>/dev/null; then
        return 0
    fi

    # Try wget as fallback
    if wget -q --timeout=10 -O "$dest" "$url" 2>/dev/null; then
        return 0
    fi

    die "Failed to download: $url"
}

# ── Extract helpers ──────────────────────────────────────────────
extract_to() {
    local archive="$1"
    local dest="$2"
    local strip="${3:-1}"

    rm -rf "$dest"
    mkdir -p "$dest"

    case "$archive" in
        *.tar.gz|*.tgz)
            tar -xzf "$archive" -C "$dest" --strip-components="$strip" ;;
        *.tar.bz2|*.tbz2)
            tar -xjf "$archive" -C "$dest" --strip-components="$strip" ;;
        *.tar.xz|*.txz)
            tar -xJf "$archive" -C "$dest" --strip-components="$strip" ;;
        *.tar.zst)
            tar --zstd -xf "$archive" -C "$dest" --strip-components="$strip" ;;
        *.tar)
            tar -xf "$archive" -C "$dest" --strip-components="$strip" ;;
        *.zip)
            unzip -q "$archive" -d "$dest" ;;
        *)
            die "Unknown archive format: $archive" ;;
    esac
}

# ── Standard build recipe ────────────────────────────────────────
# Usage: standard_build PKG_NAME VERSION URL [configure_args...]
standard_build() {
    local pkg="$1"
    local ver="$2"
    local url="$3"
    shift 3

    local archive="$SOURCES_DIR/${pkg}-${ver}.tar.xz"
    local build_dir="$BUILD_DIR/${pkg}-${ver}"

    step "Building ${pkg} ${ver}"

    # Download
    download "$url" "$archive"

    # Extract
    substep "Extracting..."
    extract_to "$archive" "$build_dir"

    # Build
    cd "$build_dir"

    # Configure (if there's a configure script)
    if [ -f ./configure ]; then
        substep "Configuring..."
        ./configure --prefix=/usr \
            --sysconfdir=/etc \
            --localstatedir=/var \
            "$@"
    elif [ -f ./meson.build ]; then
        substep "Configuring with Meson..."
        meson setup build --prefix=/usr "$@"
        cd build
    fi

    # Compile
    substep "Compiling (${JOBS} jobs)..."
    if [ -d build ] && [ -f build/build.ninja ]; then
        ninja -C build -j"$JOBS"
    else
        make -j"$JOBS"
    fi

    # Install to rootfs
    substep "Installing to rootfs..."
    if [ -d build ] && [ -f build/build.ninja ]; then
        DESTDIR="$ROOTFS_DIR" ninja -C build install
    else
        make DESTDIR="$ROOTFS_DIR" install
    fi

    cd "$PROJECT_ROOT"
    success "Built ${pkg} ${ver}"
}

# ── CMake build recipe ───────────────────────────────────────────
cmake_build() {
    local pkg="$1"
    local ver="$2"
    local url="$3"
    shift 3

    local archive="$SOURCES_DIR/${pkg}-${ver}.tar.xz"
    local build_dir="$BUILD_DIR/${pkg}-${ver}"

    step "Building ${pkg} ${ver} (CMake)"

    download "$url" "$archive"
    extract_to "$archive" "$build_dir"

    cd "$build_dir"
    mkdir -p build && cd build

    cmake .. -DCMAKE_INSTALL_PREFIX=/usr "$@"
    make -j"$JOBS"
    make DESTDIR="$ROOTFS_DIR" install

    cd "$PROJECT_ROOT"
    success "Built ${pkg} ${ver}"
}

# ── Check if command exists ──────────────────────────────────────
has_command() {
    command -v "$1" >/dev/null 2>&1
}

# ── Print build summary ──────────────────────────────────────────
build_summary() {
    local phase="$1"
    local start_time="$2"
    local end_time=$(date +%s)
    local elapsed=$((end_time - start_time))

    echo ""
    echo -e "${GREEN}╔══════════════════════════════════════════════════════════════╗${NC}"
    echo -e "${GREEN}║  Phase ${phase} complete — ${elapsed}s elapsed${NC}"
    echo -e "${GREEN}╚══════════════════════════════════════════════════════════════╝${NC}"
    echo ""
}

# ── Export for use in config scripts ─────────────────────────────
export -f step substep success info warn die
export -f download extract_to standard_build cmake_build
