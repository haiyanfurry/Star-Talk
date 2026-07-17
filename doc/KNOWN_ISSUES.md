# Star-Talk / 星語 — 已知问题与风险分析

## 🔴 未验证项 (Unverified)

> 以下组件尚未实际构建或测试，仅基于设计分析。

### 1. 整个系统未启动测试
用户态、桌面环境、安装器、引导流程均未经过实际启动验证。所有启动相关的 LED 码、时间估算、硬件检测逻辑均为设计预期。

### 2. i2pd 源码编译未验证
i2pd 不在 pkgsrc 中，构建脚本设计了从 GitHub 源码编译的方案，但**未实际执行编译测试**。

### 3. VSCode 二进制兼容性未知
pkgsrc 不包含 VSCode，计划下载 Linux x86_64 官方二进制包。在 NetBSD 上的运行兼容性（尤其是通过 COMPAT_LINUX）**未经验证**。

## 🔴 已知平台限制

### 4. Steam 不支持 NetBSD
Steam 是 Linux ELF 二进制，深度依赖 Linux 特性（DRM ioctl、systemd、glibc）。即使用 COMPAT_LINUX 也**极不可能**正常运行。

### 5. QQ / 微信桌面版不支持
腾讯官方 Linux 客户端依赖 systemd 和特定 glibc 版本。可尝试 Web 版本作为替代。

### 6. NVIDIA GPU 仅有开源驱动
NetBSD 无 NVIDIA 官方闭源驱动，仅 nouveau 可用，性能和功能有限。

## 🟡 待验证问题

### 7. KDE Plasma 6 完整安装
pkgsrc 中有 plasma6-* 独立包，但缺少诸如 `meta-pkgs/plasma6` 的统一元包。需要逐个安装，依赖解析和编译时间待实测。

### 8. UEFI 引导兼容性
NetBSD bootx64.efi 在某些固件上的兼容性未经验证。

### 9. Wi-Fi 驱动覆盖
NetBSD Wi-Fi 驱动版本普遍滞后于 Linux，较新芯片可能无驱动。

### 10. 中文输入法集成
fcitx5 在 pkgsrc 中可用，但需在 `/etc/rc.local` 或环境变量中手动配置，KDE 集成度待验证。

## 🟢 设计层面的考虑

### 11. 时区设置
需要安装后手动设置：`ln -sf /usr/share/zoneinfo/Asia/Shanghai /etc/localtime`

### 12. PulseAudio 与 OSS
NetBSD 原生使用 OSS，KDE 偏向 PulseAudio，可能存在设备占用冲突，需要配置协调。

## 🚨 不进系统故障排查 (参考)

以下基于 NetBSD 通用经验，**未在 Star-Talk 上验证**：

| 症状 | 可能原因 | 排查方向 |
|------|---------|---------|
| 黑屏无输出 | 内核 panic | boot.cfg 加 `-v` 参数 |
| 找不到 root 设备 | FFSv2 分区未识别 | `dmesg \| grep wd` |
| SDDM 不启动 | GPU/DRM 问题 | Ctrl+Alt+F1 检查 tty |
| 网络不通 | dhcpcd 未运行 | `ifconfig -a` |
