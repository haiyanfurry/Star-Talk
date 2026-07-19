# Star-Talk / 星語 — 架构文档

## 当前构建状态 (2026-07-19)

**已验证可以启动到 login 提示符**（QEMU, amd64）。

### 已验证
- ✅ SWIMSTAR 内核编译 (NetBSD 11.99.7, 基于 GENERIC)
- ✅ NetBSD userland 构建 (distribution + release)
- ✅ UEFI 引导 → bootloader → 内核加载
- ✅ 内核自动挂载 ext2 root (分区 1)
- ✅ /etc/rc 完整初始化流程
- ✅ 新型风格启动屏 (ASCII 艺术 + LED 诊断码 + 硬件检测)
- ✅ getty → login 提示符

### 未完成
- ❌ KDE Plasma 6 (需 NetBSD 原生编译)
- ❌ 硬盘安装器测试
- ❌ 物理机启动测试
- ❌ 首次启动包安装 (star-talk-firstboot)

### 已知限制
- ext2 文件系统 (非原生 FFS, 交叉编译的 FFSv2 不兼容)
- /dev 节点需手动创建 (MAKEDEV)
- 首次启动后 ext2 需 fsck
- boot.cfg 不被 bootloader 读取 (需手动输入 `boot NAME=EFI:/netbsd`)

## 目标架构

### 引导流程
```
UEFI → bootx64.efi → boot NAME=EFI:/netbsd → 内核 → ext2 root → /etc/rc → login
```

### 分区布局
```
Part 1: ext2 root (dk0) — 内核自动选择第一个分区
Part 2: ESP FAT32 (dk1)
Part 3: swap (dk2)
```

### 新型风格启动屏
/etc/rc.d/startalk-splash:
1. LED 诊断码 (L200-L900)
2. 硬件自检面板 (CPU, RAM, GPU, 磁盘, 网络)
3. ASCII 艺术 Star-Talk 字体
4. 颜色编码状态输出
