# Star-Talk / 星語

> 基于 NetBSD 内核的桌面操作系统项目，搭载 KDE Plasma 6 桌面环境。
> **当前状态：开发中 — 内核 + 基础系统已可在 QEMU 启动到 login 提示符。**

---

## 📊 当前进度

| 阶段 | 状态 | 备注 |
|------|------|------|
| SWIMSTAR 内核编译 | ✅ 完成 | NetBSD 11.99.7, amd64 |
| NetBSD userland 构建 | ✅ 完成 | distribution + release |
| 基础系统启动 | ✅ **可启动到 login** | QEMU 验证, ext2 root |
| 新型风格启动屏 | ✅ 已运行 | ASCII 艺术 + LED 诊断码 + 硬件检测面板 |
| 系统登录 | ⚠️ 权限问题 | PAM/login 所有权需修复 |
| KDE Plasma 6 | ❌ 未安装 | 需 NetBSD 原生环境编译 |
| 硬盘安装器 | ⚠️ 脚本就绪，未测试 | 需完整 /dev 和 rw root |
| 首次启动包安装 | ❌ 未运行 | star-talk-firstboot 依赖 pkgsrc |
| QEMU 启动测试 | ✅ 已通过 | virtio 磁盘, UEFI 引导 |
| 物理机启动 | ❌ 未测试 | |
| dd 到 USB 启动 | ❌ 未测试 | |

## ✨ 已实现特性

- **NetBSD 内核** — SWIMSTAR 配置，基于 GENERIC + 桌面驱动
- **新型风格启动屏** — LED 诊断码 + 硬件面板检测 + ASCII 艺术 "Star-Talk" 字体
- **基础系统启动** — 内核 → root mount → /etc/rc → getty → login 提示符
- **pkgsrc 包管理** — 预置在 rootfs 中 (`/usr/pkgsrc/`)
- **Tor / I2PD** — rc.d 脚本就绪，默认禁用

## ⚠️ 已知问题

- **ext2 文件系统** — 非 NetBSD 原生 FFS，使用交叉编译的 nbmakefs 创建的 FFSv2 内核不能识别
- **login 失败** — /etc 文件所有权从 cp -a 继承，需启动后手动 `chown root:wheel`
- **/dev 节点缺失** — 交叉编译无法生成完整设备节点，MAKEDEV 需手动运行
- **首次启动不稳定** — ext2 在首启后被写脏，需 e2fsck 修复
- **分区布局要求** — ext2 root 必须在分区 1（内核自动选择第一个可挂载分区）
- **ESP 在分区 2** — boot.cfg 必须显式指定 `NAME=EFI:/netbsd`
- **KDE / 桌面** — 无法在 Linux 上交叉编译，需 NetBSD 原生环境
- **VSCode / i2pd** — 不在 pkgsrc 中，脚本设计为首次启动时下载/编译
- **SWIMSTAR 内核** — 约 200 MB（含调试符号），可进一步裁剪

## 🏗️ 构建

```bash
make kernel       # ✅ 编译内核
make userland     # ✅ 构建基础系统
make packages     # 📋 生成首次启动脚本
make image        # ⚠️ 需手动修复分区 + /dev 节点
```

## 📂 分区布局

```
Part 1: ext2 root (8GB)   — dk0, 内核自动挂载
Part 2: ESP FAT32 (260MB) — dk1, UEFI 引导
Part 3: swap (4GB)        — dk2
```

## 📄 许可证

Star-Talk / 星語 — Copyright (C) 2026 **海盐 (Hai Yan)** — GPL-3.0
