# Star-Talk / 星語

> 基于 NetBSD 内核的桌面操作系统项目，目标搭载 KDE Plasma 6 桌面环境。
> **当前状态：开发中 — 内核已编译通过，userland 和桌面环境待构建。**

---

## 📊 当前进度

| 阶段 | 状态 |
|------|------|
| 架构设计 + 文档 | ✅ 完成 |
| SWIMSTAR 内核编译 | ✅ 通过 (out/netbsd, 198 MB) |
| NetBSD userland 构建 | ⏳ 待执行 |
| pkgsrc 软件包安装 | ⏳ 待执行 |
| 根文件系统组装 | ⏳ 待执行 |
| 磁盘映像生成 | ⏳ 待执行 |
| 启动测试 | ❌ 未测试 |

## ✨ 计划特性

- **NetBSD 内核** — SWIMSTAR 配置，基于 GENERIC，添加桌面 GPU/音频/Wi-Fi 驱动
- **KDE Plasma 6** — Wayland 桌面环境（pkgsrc 提供 plasma6-* 包）
- **AIX 风格启动屏** — LED 诊断码 + 硬件面板检测 + ASCII 艺术
- **硬盘安装器** — 借鉴 NetBSD `sysinst` 的 6 阶段安装脚本（**未经测试**）
- **匿名工具** — Tor + i2pd 预装但默认不自启
- **Firefox** — 通过 pkgsrc 安装
- **VSCode** — 下载官方二进制包（不在 pkgsrc 中）
- **Konsole** — KDE 配套终端
- **pkgsrc 包管理** — NetBSD 原生包系统

## 🏗️ 构建

### 前置条件

- NetBSD 源码树 (`NetBSD/src/`) — 已拉取
- pkgsrc 树 (`NetBSD/pkgsrc/`) — 已拉取
- 构建工具: `git curl tar make gcc`

### 构建命令

```bash
make kernel       # ✅ 已验证：编译 SWIMSTAR 内核
make userland     # ⏳ 构建 NetBSD 基础系统
make packages     # ⏳ 安装 KDE + 应用
make image        # ⏳ 生成磁盘映像
make test-qemu    # ⏳ QEMU 测试
```

> **注意**: `make userland` 和 `make packages` 尚未执行，实际构建时间和结果待验证。

## 📂 项目结构

```
Star-Talk/
├── NetBSD/
│   ├── src/          # NetBSD 源码 (7.1 GB)
│   └── pkgsrc/       # pkgsrc 包管理 (917 MB)
├── branding/
│   └── splash.art    # ASCII 艺术 + LED 码定义
├── configs/
│   ├── netbsd/
│   │   ├── kernel/SWIMSTAR    # 内核配置 (✅ 编译通过)
│   │   ├── etc/rc.conf        # 系统服务配置
│   │   ├── etc/boot.cfg       # 引导器菜单
│   │   └── install/install.sh # 硬盘安装器 (⚠️ 未测试)
│   ├── kde/
│   │   └── plasma-setup.sh    # KDE 桌面配置
│   └── sddm/
│       └── sddm.conf          # SDDM 配置
├── scripts/netbsd/            # 构建脚本
├── doc/                       # 架构文档 + 已知问题
├── out/netbsd                 # 编译好的内核 (198 MB)
└── Makefile
```

## ⚠️ 已知限制

- **VSCode** 不在 NetBSD pkgsrc 中，通过下载 Linux 二进制包安装，兼容性未知
- **i2pd** 不在 pkgsrc 中，需要从源码编译，**未实际编译测试**
- **Steam / QQ / 微信** — NetBSD 的 Linux 兼容层支持有限
- **整个系统尚未启动测试** — userland、桌面环境、安装器均未验证
- 构建时间基于估算，实际可能差异很大

详见: [doc/KNOWN_ISSUES.md](doc/KNOWN_ISSUES.md)

## 📄 许可证

Star-Talk / 星語 — Copyright (C) 2026 **海盐 (Hai Yan)**

本项目原创代码使用 **GNU General Public License v3.0** 授权。
第三方组件遵循各自许可证。
