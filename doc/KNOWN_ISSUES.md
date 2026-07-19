# Star-Talk / 星語 — 已知问题

## 已验证的问题

### 1. login 失败 (PAM 权限)
/etc/login.conf 和 /etc/pam.d/* 的所有权是 1000:1000 而非 root:wheel。
**修复**: 启动后 `chown -R root:wheel /etc`

### 2. boot.cfg 不被读取
bootloader 默认设备为 NAME=STAR_TALK，无法找到 ESP 上的 boot.cfg。
**绕过**: 手动输入 `boot NAME=EFI:/netbsd`

### 3. ext2 文件系统不稳定
首次启动后 ext2 可能产生不一致，后续启动 fsck 失败。
**修复**: 每次启动前 `e2fsck -f -y` 或使用 FFS

### 4. /dev 节点不完整
交叉编译无法生成完整设备节点。dk 大号码为 168 (非标准 92)。
**修复**: 预创建或用 MAKEDEV

### 5. FFSv2 不可用
nbmakefs 创建的 FFSv2 内核无法挂载 (error 79)。
**绕过**: 使用 ext2

### 6. Steam/QQ/微信 不支持
Linux 兼容层不足以运行这些应用。

### 7. SSH 未配置
基础系统未配置 sshd，远程访问不可用。

## 未测试项

- 物理机 UEFI 启动
- USB dd 写入启动
- 硬盘安装器
- KDE/桌面环境
- Wi-Fi 驱动
- 多用户环境
