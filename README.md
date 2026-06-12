# Star-Talk / 星語

> A Gentoo-based Linux Live Distribution with Niri compositor, AIX-style boot splash, built-in anonymity tools, and gaming support.

基于 Gentoo 的 Linux Live 发行版，集成 Niri 滚动平铺 Wayland 合成器、AIX 风格启动欢迎屏、内置匿名工具和游戏支持。

---

## ✨ 特性 Features

- **风格启动屏** — 硬件检测 + ASCII 艺术欢迎界面
- **Niri 合成器** — 滚动平铺 Wayland 桌面，Catppuccin Mocha 主题
- **Gentoo 基础** — OpenRC 初始化系统，Portage 包管理
- **匿名工具** — Tor + obfs4proxy + i2pd 开箱即用
- **游戏支持** — Steam + Proton GE + Wine 兼容层
- **Firefox 浏览器** — 中文界面预装
- **PipeWire 音频** — 现代化音频服务
- **Live USB** — 即插即用，支持持久化存储

## 🚀 快速开始 Quick Start

### 写入 USB

```bash
sudo dd if=out/star-talk-YYYYMMDD.img of=/dev/sdX bs=4M status=progress conv=fsync
```

### 启动

1. 插入 USB 设备
2. 进入 BIOS/UEFI 启动菜单 (F12/F2/Esc)
3. 选择 `UEFI: STARTALK_EFI`
4. 系统自动登录用户 `startalk`，进入 Niri 桌面

### 桌面快捷键

| 按键 | 功能 |
|------|------|
| `Super+Return` | 终端 (Foot) |
| `Super+D` | 应用启动器 (Wofi) |
| `Super+Q` | 关闭窗口 |
| `Super+H/L/J/K` | 窗口导航 |
| `Super+1..9` | 工作区切换 |

## 🏗️ 构建 Build

### 依赖

- Linux x86_64 宿主机
- `mke2fs` `sgdisk` `mkfs.vfat` `mtools` `zstd` `cpio`
- `curl` `wget` `git` `gcc` `make` `meson` `ninja` `cargo`

### 构建步骤

```bash
# 完整构建
make all

# 单独阶段
make kernel       # 编译内核 (SQUASHFS + OVERLAY_FS)
make busybox      # 编译 BusyBox (静态 + 动态)
make initramfs    # 组装 initramfs (AIX 欢迎屏)
make usb-image    # 生成 USB 磁盘映像

# 写入 USB
make burn DEVICE=/dev/sdX

# QEMU 测试
make test-qemu
```

## 📂 项目结构 Project Structure

```
Star-Talk/
├── configs/                    # 配置模板 (Niri, Waybar, Wofi, Foot, 系统)
│   ├── niri/config.kdl         # Niri 合成器配置
│   ├── waybar/                 # Waybar 状态栏 (Catppuccin Mocha)
│   ├── wofi/                   # Wofi 启动器
│   ├── foot/foot.ini           # Foot 终端
│   ├── inittab, fstab, rcS     # 系统初始化
│   └── startalk-session        # 桌面会话启动脚本
├── initramfs/
│   └── init                    # 风格启动脚本 (PID 1)
├── scripts/                    # 构建脚本 (18 个)
│   ├── utils.sh                # 共享函数库
│   ├── 00-prepare.sh           # 下载源码
│   ├── 01-kernel.sh            # 编译内核
│   ├── 03-busybox.sh           # 编译 BusyBox
│   ├── 20-assemble-initramfs.sh
│   ├── 23-make-usb-image.sh    # 生成 USB 映像
│   └── 24-burn-usb.sh          # 写入 USB
├── out/                        # 构建产物
│   ├── bzImage                 # Linux 内核
│   ├── initramfs.cpio.zst      # 压缩 initramfs
│   └── star-talk-YYYYMMDD.img  # 最终 USB 映像
├── Makefile                    # 顶层构建入口
├── LICENSE                     # GPL-3.0
└── README.md
```

## 🔧 系统组件 System Components

| 组件 | 说明 |
|------|------|
| **Base** | Gentoo Linux (OpenRC, Portage) |
| **Kernel** | Linux 7.0.12 x86_64 (SQUASHFS + OVERLAY_FS) |
| **Init** | 自定义 initramfs + 定制启动屏 |
| **Compositor** | Niri (scrollable-tiling Wayland) |
| **Bar** | Waybar (Catppuccin Mocha 主题) |
| **Launcher** | Wofi (drun 模式) |
| **Terminal** | Foot (Wayland-native) |
| **Audio** | PipeWire + WirePlumber |
| **Browser** | Firefox (zh-CN) |
| **Gaming** | Steam + Proton GE + Wine |
| **Anonymity** | Tor + obfs4proxy + i2pd |

## 🌐 匿名工具 Anonymity Tools

| 服务 | 端口 | 说明 |
|------|------|------|
| Tor SOCKS | `127.0.0.1:9050` | Onion 路由匿名代理 |
| Tor Control | `127.0.0.1:9051` | Tor 控制端口 |
| I2P HTTP Proxy | `127.0.0.1:4444` | I2P 匿名网络代理 |
| I2P Console | `127.0.0.1:7070` | I2P Web 控制台 |
| obfs4proxy | — | Tor 网桥混淆插件 |

使用 `torsocks <command>` 通过 Tor 代理运行命令。

## 📄 许可证 License

Star-Talk / 星語 — Copyright (C) 2026 **海盐 (Hai Yan)**

本项目使用 **GNU General Public License v3.0** 授权。

本系统中包含的第三方组件（Linux Kernel, Gentoo, BusyBox, Niri, Firefox 等）分别遵循各自的许可证。

---

```
   ╔══════════════════════════════════════════════════════════════╗
   ║         .d8888b.  888                      888    888       ║
   ║        d88P  Y88b 888                      888    888       ║
   ║        Y88b.      888                      888    888       ║
   ║         "Y888b.   888888  8888b.  888d888  888888 888  888  ║
   ║            "Y88b. 888        "88b 888P"    888    888  888  ║
   ║              "888 888    .d888888 888      888    888  888  ║
   ║        Y88b  d88P Y88b.  888  888 888      Y88b.  Y88b 888  ║
   ║         "Y8888P"   "Y888 "Y888888 888       "Y888  "Y88888  ║
   ║                                                              ║
   ║             ★  Welcome to Star-Talk / 星语  ★               ║
   ╚══════════════════════════════════════════════════════════════╝
```
