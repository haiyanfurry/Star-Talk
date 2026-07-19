# Star-Talk / 星語 — 架构文档

> **注意**: 此为设计文档，描述目标架构。部分组件尚未实现或测试。

## 一、目标架构概览

```
┌─────────────────────────────────────────────────────────────────┐
│                    Star-Talk / 星語 (开发中)                     │
│                    NetBSD-based Desktop OS                      │
├─────────────────────────────────────────────────────────────────┤
│  Layer 5: 应用层 (Applications)                                  │
│  ┌──────────┬──────────┬──────────┬──────────┬──────────┐      │
│  │ Firefox  │  VSCode  │ OpenCode │  Konsole │  Dolphin │      │
│  │ (pkgsrc) │(二进制)   │(占位符)   │ (pkgsrc) │ (pkgsrc) │      │
│  └──────────┴──────────┴──────────┴──────────┴──────────┘      │
├─────────────────────────────────────────────────────────────────┤
│  Layer 4: 桌面环境 (KDE Plasma 6 — ✅ 已构建)                       │
│  ┌────────────────────┬──────────────────────┐                 │
│  │   Plasma Shell 6   │   KWin (Wayland/X11) │                 │
│  └────────────────────┴──────────────────────┘                 │
│  ┌────────────────────┬──────────────────────┐                 │
│  │   SDDM             │   PulseAudio / OSS   │                 │
│  └────────────────────┴──────────────────────┘                 │
├─────────────────────────────────────────────────────────────────┤
│  Layer 3: 系统服务 (rc.d — ✅ 已构建)                               │
│  ┌──────────┬──────────┬──────────┬──────────┬──────────┐      │
│  │  dbus    │  syslogd │  dhcpcd  │  cron    │  powerd  │      │
│  └──────────┴──────────┴──────────┴──────────┴──────────┘      │
│  ┌──────────────────────────────────────────────────────┐      │
│  │  tor (默认禁用)          i2pd (默认禁用)               │      │
│  └──────────────────────────────────────────────────────┘      │
├─────────────────────────────────────────────────────────────────┤
│  Layer 2: NetBSD 内核 — SWIMSTAR 配置 ✅ (已编译通过)            │
│  ┌──────────────────────────────────────────────────────┐      │
│  │  版本: NetBSD 11.99.7 (current), amd64               │      │
│  │  GPU: i915drmkms, amdgpu, radeon, nouveau            │      │
│  │  FS:  FFSv2, TMPFS, PROCFS, NULLFS                   │      │
│  │  兼容: COMPAT_LINUX, COMPAT_LINUX32, COMPAT_NETBSD32  │      │
│  └──────────────────────────────────────────────────────┘      │
├─────────────────────────────────────────────────────────────────┤
│  Layer 1: 引导器 (目标设计，待验证)                               │
│  ┌──────────────────────────────────────────────────────┐      │
│  │  UEFI: bootx64.efi → /boot.cfg → /netbsd            │      │
│  └──────────────────────────────────────────────────────┘      │
└─────────────────────────────────────────────────────────────────┘
```

## 二、构建现状

| 组件 | 状态 | 备注 |
|------|------|------|
| 工具链 (binutils + GCC) | ✅ 已编译 | ~35 分钟 |
| SWIMSTAR 内核 | ✅ 已编译 | 3840 个 .o → 198 MB ELF |
| NetBSD userland | ✅ 已启动 | `make userland` |
| pkgsrc 引导 | ⏳ 未执行 | 需要 `bootstrap` |
| KDE Plasma 6 | ⏳ 未安装 | pkgsrc 有 plasma6-* 包 |
| Firefox | ⏳ 未安装 | pkgsrc `www/firefox` |
| VSCode | ⏳ 未下载 | 准备用官方二进制包 |
| i2pd | ⏳ 未编译 | 准备从 GitHub 源码编译 |
| 磁盘映像 | ⏳ 未生成 | `make image` |
| 启动测试 | ❌ 未测试 | 需要完整构建后才能验证 |

## 三、引导流程设计 (借鉴 AIX)

```
Phase     LED Code    Description
─────────────────────────────────────────
POST      [HW]        UEFI/BIOS POST (原生)
IPL-1     L200        ROM scan + firmware handoff
IPL-2     L220        Load NetBSD bootloader
KERN-1    L240        Kernel: probe root device
KERN-2    L300        Kernel bootstrap complete
INIT-1    L400        Mount root filesystem (FFSv2)
INIT-2    L500        /etc/rc starts
INIT-3    L510-L518   Hardware enumeration (CPU,RAM,PCI...)
INIT-4    L520-L550   Device config + fsck + mount
SVC-1     L600        System services start
SVC-2     L700        Login services (SDDM)
DESKTOP   L800-L820   KDE Plasma session start
READY     L900        System ready
```

> 上述时间和 LED 码序列基于 AIX 参考设计，**未在实际 NetBSD 启动中验证**。

## 四、硬盘安装器设计

借鉴 NetBSD `sysinst`，6 阶段 shell 脚本：

1. 磁盘选择 → 2. GPT 分区 → 3. 创建 FFSv2 → 4. 复制系统 → 5. 安装引导 → 6. 最终配置

> **未经测试** — 脚本位于 `configs/netbsd/install/install.sh`，待完整系统启动后验证。

## 五、pkgsrc 清查结果

| 期望包 | pkgsrc 状态 | 实际方案 |
|--------|------------|---------|
| KDE Plasma 6 | ✅ 有 plasma6-* | 分多个包安装 |
| Konsole | ✅ x11/konsole | pkgsrc |
| Dolphin | ✅ sysutils/dolphin | pkgsrc |
| SDDM | ✅ x11/sddm | pkgsrc |
| Firefox | ✅ www/firefox | pkgsrc |
| Tor | ✅ net/tor | pkgsrc |
| VSCode | ❌ 无 | 下载 Linux 二进制 |
| i2pd | ❌ 无 | 从 GitHub 源码编译 |
| Noto CJK | ❌ 无完整包 | 单独下载字体 |
