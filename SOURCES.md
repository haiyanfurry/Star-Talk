# Star-Talk / 星語 — 组件源码清单

本项目所有构建产物均可从源码编译。以下是各组件的源码地址和许可证信息。

## 核心系统 Core System

| 组件 | 版本 | 源码地址 | 许可证 |
|------|------|----------|--------|
| Linux Kernel | 7.0.12 | https://cdn.kernel.org/pub/linux/kernel/v7.x/linux-7.0.12.tar.xz | GPL-2.0 |
| Gentoo Stage3 | latest | https://distfiles.gentoo.org/releases/amd64/autobuilds/latest-stage3-amd64-openrc.txt | GPL-2.0 |
| BusyBox | 1.37.0 | https://busybox.net/downloads/busybox-1.37.0.tar.bz2 | GPL-2.0 |

## 图形栈 Graphics Stack

| 组件 | 版本 | 源码地址 | 许可证 |
|------|------|----------|--------|
| Mesa | 25.2.0 | https://archive.mesa3d.org/mesa-25.2.0.tar.xz | MIT |
| Wayland | 1.24.0 | https://gitlab.freedesktop.org/wayland/wayland/-/tags/1.24.0 | MIT |
| wayland-protocols | 1.43 | https://gitlab.freedesktop.org/wayland/wayland-protocols/-/tags/1.43 | MIT |
| libdrm | 2.4.124 | https://dri.freedesktop.org/libdrm/ | MIT |
| libxkbcommon | 1.8.1 | https://xkbcommon.org/download/ | MIT |
| libinput | 1.28.1 | https://gitlab.freedesktop.org/libinput/libinput/ | MIT |
| pixman | 0.44.2 | https://cairographics.org/releases/ | MIT |
| cairo | 1.18.4 | https://cairographics.org/releases/ | LGPL-2.1 / MPL-1.1 |
| pango | 1.56.2 | https://download.gnome.org/sources/pango/ | LGPL-2.1 |
| Vulkan-Loader | 1.4.309 | https://github.com/KhronosGroup/Vulkan-Loader | Apache-2.0 |

## 桌面环境 Desktop

| 组件 | 版本 | 源码地址 | 许可证 |
|------|------|----------|--------|
| Niri | 25.02 | https://github.com/YaLTeR/niri | GPL-3.0 |
| Waybar | 0.11.0 | https://github.com/Alexays/Waybar | MIT |
| Foot | 1.20.2 | https://codeberg.org/dnkl/foot | MIT |
| Wofi | 1.4.1 | https://hg.sr.ht/~scoopta/wofi | GPL-3.0 |
| Swaybg | 1.2.1 | https://github.com/swaywm/swaybg | MIT |
| Swaylock | 1.8.0 | https://github.com/swaywm/swaylock | MIT |
| Mako | 1.9.0 | https://github.com/emersion/mako | MIT |

## 音频 Audio

| 组件 | 版本 | 源码地址 | 许可证 |
|------|------|----------|--------|
| PipeWire | 1.4.2 | https://gitlab.freedesktop.org/pipewire/pipewire/ | MIT |
| WirePlumber | 0.5.8 | https://gitlab.freedesktop.org/pipewire/wireplumber/ | MIT |

## 匿名工具 Anonymity

| 组件 | 版本 | 源码地址 | 许可证 |
|------|------|----------|--------|
| Tor | 0.4.8.16 | https://dist.torproject.org/ | BSD-3-Clause |
| obfs4proxy | 0.0.14 | https://gitlab.com/yawning/obfs4 | GPL-3.0 |
| i2pd | 2.55.0 | https://github.com/PurpleI2P/i2pd | BSD-3-Clause |
| libevent | 2.1.12 | https://github.com/libevent/libevent | BSD-3-Clause |

## 应用 Applications

| 组件 | 源码地址 | 许可证 |
|------|----------|--------|
| Firefox | https://hg.mozilla.org/mozilla-central/ | MPL-2.0 |
| Steam | https://github.com/ValveSoftware/steam-for-linux | Proprietary (客户端) |
| Proton GE | https://github.com/GloriousEggroll/proton-ge-custom | BSD-3-Clause / GPL |

## 基础库 Libraries

| 组件 | 版本 | 源码地址 | 许可证 |
|------|------|----------|--------|
| glibc | 2.41 | https://ftp.gnu.org/gnu/glibc/ | LGPL-2.1 |
| GCC | 16.1.0 | https://ftp.gnu.org/gnu/gcc/ | GPL-3.0 |
| binutils | 2.44 | https://ftp.gnu.org/gnu/binutils/ | GPL-3.0 |
| zlib | 1.3.1 | https://zlib.net/ | zlib |
| OpenSSL | 3.5.0 | https://www.openssl.org/source/ | Apache-2.0 |
| ncurses | 6.5 | https://ftp.gnu.org/gnu/ncurses/ | MIT |
| readline | 8.2 | https://ftp.gnu.org/gnu/readline/ | GPL-3.0 |
| expat | 2.7.1 | https://github.com/libexpat/libexpat | MIT |
| libxml2 | 2.14.0 | https://download.gnome.org/sources/libxml2/ | MIT |
| util-linux | 2.41 | https://git.kernel.org/pub/scm/utils/util-linux/ | GPL-2.0 |
| D-Bus | 1.16.2 | https://dbus.freedesktop.org/releases/dbus/ | AFL-2.1 / GPL-2.0 |
| jsoncpp | 1.9.6 | https://github.com/open-source-parsers/jsoncpp | MIT |
| fmt | 11.1.4 | https://github.com/fmtlib/fmt | MIT |
| spdlog | 1.15.2 | https://github.com/gabime/spdlog | MIT |

## 构建方式

### 从源码编译（完全 LFS 模式）

```bash
# 下载所有源码 (~2GB)
make prepare

# 从源码编译内核
make kernel

# 从源码编译 BusyBox
make busybox

# 从源码编译完整图形栈 (~2-3 小时)
make graphics

# 从源码编译桌面环境
make desktop

# 从源码编译匿名工具
make anonymity

# 生成 USB 镜像
make usb-image
```

### 快速构建（使用系统预编译包 + Gentoo stage3）

```bash
# 下载 Gentoo stage3 + 内核源码
make prepare

# 编译内核
make kernel

# 编译 BusyBox
make busybox

# 组装 initramfs
make initramfs

# 生成 USB 镜像（从系统复制桌面组件）
make usb-image
```

## Star-Talk 自身

| 组件 | 源码 | 许可证 |
|------|------|--------|
| initramfs/init | 本仓库 `initramfs/init` | GPL-3.0 |
| build scripts | 本仓库 `scripts/` | GPL-3.0 |
| configs | 本仓库 `configs/` | GPL-3.0 |

---

所有 Star-Talk 原创代码以 **GPL-3.0** 授权。各第三方组件分别遵循其各自的许可证。
