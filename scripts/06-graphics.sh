#!/bin/bash
# ╔══════════════════════════════════════════════════════════════╗
# ║     Star-Talk / 星语 — 06-graphics.sh                     ║
# ║     Build Mesa, Wayland, graphics stack                    ║
# ╚══════════════════════════════════════════════════════════════╝
set -euo pipefail
source "$(dirname "$0")/utils.sh"

PHASE="06"
START_TIME=$(date +%s)
step "Phase ${PHASE}: Building graphics stack (Mesa, Wayland, etc.)"

# ── libdrm ───────────────────────────────────────────────────────
step "Building libdrm 2.4.124"
DRM_DIR="$BUILD_DIR/libdrm-2.4.124"
if [ ! -f "$ROOTFS_DIR/usr/lib/libdrm.so" ]; then
    extract_to "$SOURCES_DIR/libdrm-2.4.124.tar.xz" "$(dirname "$DRM_DIR")"
    cd "$DRM_DIR"
    meson setup build --prefix=/usr \
        -Dintel=enabled \
        -Damdgpu=disabled \
        -Dnouveau=disabled \
        -Dvmwgfx=disabled \
        -Dudev=true
    ninja -C build -j"$JOBS"
    DESTDIR="$ROOTFS_DIR" ninja -C build install
    success "libdrm: installed"
else
    info "libdrm: already installed"
fi

# ── wayland ──────────────────────────────────────────────────────
step "Building wayland 1.24.0"
WL_DIR="$BUILD_DIR/wayland-1.24.0"
if [ ! -f "$ROOTFS_DIR/usr/lib/libwayland-server.so" ]; then
    extract_to "$SOURCES_DIR/wayland-1.24.0.tar.xz" "$(dirname "$WL_DIR")"
    cd "$WL_DIR"
    meson setup build --prefix=/usr -Ddocumentation=false -Dtests=false
    ninja -C build -j"$JOBS"
    DESTDIR="$ROOTFS_DIR" ninja -C build install
    success "wayland: installed"
else
    info "wayland: already installed"
fi

# ── wayland-protocols ────────────────────────────────────────────
step "Building wayland-protocols 1.43"
WLP_DIR="$BUILD_DIR/wayland-protocols-1.43"
if [ ! -f "$ROOTFS_DIR/usr/share/wayland-protocols/stable/xdg-shell/xdg-shell.xml" ]; then
    extract_to "$SOURCES_DIR/wayland-protocols-1.43.tar.xz" "$(dirname "$WLP_DIR")"
    cd "$WLP_DIR"
    meson setup build --prefix=/usr -Dtests=false
    ninja -C build -j"$JOBS"
    DESTDIR="$ROOTFS_DIR" ninja -C build install
    success "wayland-protocols: installed"
else
    info "wayland-protocols: already installed"
fi

# ── libxkbcommon ─────────────────────────────────────────────────
step "Building libxkbcommon 1.8.1"
XKB_DIR="$BUILD_DIR/libxkbcommon-1.8.1"
if [ ! -f "$ROOTFS_DIR/usr/lib/libxkbcommon.so" ]; then
    extract_to "$SOURCES_DIR/libxkbcommon-1.8.1.tar.xz" "$(dirname "$XKB_DIR")"
    cd "$XKB_DIR"
    meson setup build --prefix=/usr -Denable-docs=false
    ninja -C build -j"$JOBS"
    DESTDIR="$ROOTFS_DIR" ninja -C build install
    success "libxkbcommon: installed"
else
    info "libxkbcommon: already installed"
fi

# ── pixman ───────────────────────────────────────────────────────
step "Building pixman 0.44.2"
PIXMAN_DIR="$BUILD_DIR/pixman-0.44.2"
if [ ! -f "$ROOTFS_DIR/usr/lib/libpixman-1.so" ]; then
    extract_to "$SOURCES_DIR/pixman-0.44.2.tar.gz" "$(dirname "$PIXMAN_DIR")"
    cd "$PIXMAN_DIR"
    meson setup build --prefix=/usr
    ninja -C build -j"$JOBS"
    DESTDIR="$ROOTFS_DIR" ninja -C build install
    success "pixman: installed"
else
    info "pixman: already installed"
fi

# ── cairo ────────────────────────────────────────────────────────
step "Building cairo 1.18.4"
CAIRO_DIR="$BUILD_DIR/cairo-1.18.4"
if [ ! -f "$ROOTFS_DIR/usr/lib/libcairo.so" ]; then
    extract_to "$SOURCES_DIR/cairo-1.18.4.tar.xz" "$(dirname "$CAIRO_DIR")"
    cd "$CAIRO_DIR"
    meson setup build --prefix=/usr \
        -Ddwrite=disabled -Dfontconfig=enabled
    ninja -C build -j"$JOBS"
    DESTDIR="$ROOTFS_DIR" ninja -C build install
    success "cairo: installed"
else
    info "cairo: already installed"
fi

# ── pango ────────────────────────────────────────────────────────
step "Building pango 1.56.2"
PANGO_DIR="$BUILD_DIR/pango-1.56.2"
if [ ! -f "$ROOTFS_DIR/usr/lib/libpango-1.0.so" ]; then
    extract_to "$SOURCES_DIR/pango-1.56.2.tar.xz" "$(dirname "$PANGO_DIR")"
    cd "$PANGO_DIR"
    meson setup build --prefix=/usr \
        -Dgtk_doc=false -Dintrospection=disabled
    ninja -C build -j"$JOBS"
    DESTDIR="$ROOTFS_DIR" ninja -C build install
    success "pango: installed"
else
    info "pango: already installed"
fi

# ── libinput ─────────────────────────────────────────────────────
step "Building libinput 1.28.1"
LINPUT_DIR="$BUILD_DIR/libinput-1.28.1"
if [ ! -f "$ROOTFS_DIR/usr/lib/libinput.so" ]; then
    extract_to "$SOURCES_DIR/libinput-1.28.1.tar.gz" "$(dirname "$LINPUT_DIR")"
    cd "$LINPUT_DIR"
    meson setup build --prefix=/usr \
        -Dtests=false -Ddocumentation=false \
        -Dlibwacom=false
    ninja -C build -j"$JOBS"
    DESTDIR="$ROOTFS_DIR" ninja -C build install
    success "libinput: installed"
else
    info "libinput: already installed"
fi

# ── Mesa (the big one) ───────────────────────────────────────────
step "Building Mesa 25.2.0 (this will take a while...)"
MESA_DIR="$BUILD_DIR/mesa-25.2.0"
if [ ! -f "$ROOTFS_DIR/usr/lib/dri/iris_dri.so" ]; then
    extract_to "$SOURCES_DIR/mesa-25.2.0.tar.xz" "$(dirname "$MESA_DIR")"
    cd "$MESA_DIR"
    meson setup build --prefix=/usr \
        -Dgallium-drivers=iris,zink,swrast \
        -Dvulkan-drivers=intel \
        -Dplatforms=wayland \
        -Dglx=disabled \
        -Dllvm=disabled \
        -Dvideo-codecs=[] \
        -Dshared-glapi=enabled \
        -Dgles1=disabled \
        -Dgles2=enabled \
        -Dopengl=true \
        -Dgbm=enabled \
        -Degl=enabled \
        -Dgallium-va=disabled \
        -Dgallium-vdpau=disabled \
        -Dtools=[] \
        -Dlmsensors=disabled
    ninja -C build -j"$JOBS"
    DESTDIR="$ROOTFS_DIR" ninja -C build install
    success "Mesa: installed (iris, zink, swrast)"
else
    info "Mesa: already installed"
fi

# ── Vulkan Loader ────────────────────────────────────────────────
step "Building Vulkan Loader"
VL_DIR="$BUILD_DIR/Vulkan-Loader-sdk-1.4.309"
if [ ! -f "$ROOTFS_DIR/usr/lib/libvulkan.so" ]; then
    extract_to "$SOURCES_DIR/vulkan-loader-sdk-1.4.309.tar.gz" "$(dirname "$VL_DIR")"
    cd "$VL_DIR"
    mkdir -p build && cd build
    cmake .. -DCMAKE_INSTALL_PREFIX=/usr \
        -DBUILD_TESTS=OFF \
        -DCMAKE_BUILD_TYPE=Release
    make -j"$JOBS"
    make DESTDIR="$ROOTFS_DIR" install
    success "vulkan-loader: installed"
else
    info "vulkan-loader: already installed"
fi

cd "$PROJECT_ROOT"
build_summary "$PHASE" "$START_TIME"
