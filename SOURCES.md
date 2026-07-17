# Star-Talk / 星語 — 组件清单

> 列出目标系统中各组件及其来源。标注"已测试"的为实际执行过的步骤。

## 核心系统

| 组件 | 来源 | 状态 |
|------|------|------|
| NetBSD 源码 | `NetBSD/src/` (git clone, 7.1 GB) | ✅ 已拉取 |
| SWIMSTAR 内核配置 | 本项目 `configs/netbsd/kernel/SWIMSTAR` | ✅ 已编译通过 |
| NetBSD userland | `NetBSD/src/` — `build.sh release` | ⏳ 待构建 |
| pkgsrc | `NetBSD/pkgsrc/` (git clone, 917 MB) | ✅ 已拉取 |

## 桌面环境

| 组件 | 来源 | 状态 |
|------|------|------|
| KDE Plasma 6 | pkgsrc `x11/plasma6-*` | ⏳ 待安装 |
| KDE Frameworks | pkgsrc `meta-pkgs/kf5` | ⏳ 待安装 |
| SDDM | pkgsrc `x11/sddm` | ⏳ 待安装 |
| Konsole | pkgsrc `x11/konsole` | ⏳ 待安装 |

## 应用

| 组件 | 来源 | 状态 |
|------|------|------|
| Firefox | pkgsrc `www/firefox` | ⏳ 待安装 |
| VSCode | 官方 Linux 二进制包 | ⚠️ 设计阶段，兼容性未知 |
| OpenCode | 本项目占位符 | 📋 空模板 |

## 匿名工具

| 组件 | 来源 | 状态 |
|------|------|------|
| Tor | pkgsrc `net/tor` | ⏳ 待安装 |
| i2pd | GitHub 源码编译 | ⚠️ 未执行编译测试 |

## Star-Talk 原创组件

| 组件 | 路径 | 状态 |
|------|------|------|
| SWIMSTAR 内核配置 | `configs/netbsd/kernel/SWIMSTAR` | ✅ 编译通过 |
| AIX 风格启动屏 | `configs/netbsd/etc/rc.d/startalk-splash` | ⚠️ 未启动测试 |
| 硬盘安装器 | `configs/netbsd/install/install.sh` | ⚠️ 未测试 |
| 构建脚本 | `scripts/netbsd/` | ⚠️ 仅内核步骤已验证 |
| ASCII 艺术/LED码 | `branding/splash.art` | ✅ 设计完成 |
