# Star-Talk / 星語 — 组件清单 (NetBSD Edition)

## 核心系统
| 组件 | 来源 | 状态 |
|------|------|------|
| NetBSD 源码 | NetBSD/src/ | ✅ 已拉取 (7.1 GB) |
| SWIMSTAR 内核 | 本项目 configs/ | ✅ 编译通过 |
| NetBSD userland | NetBSD/src/ | ✅ 已构建 |
| pkgsrc | NetBSD/pkgsrc/ | ✅ 已拉取 (917 MB) |

## 桌面环境 (计划)
| 组件 | 来源 | 状态 |
|------|------|------|
| KDE Plasma 6 | pkgsrc plasma6-* | ❌ 需 NetBSD 原生编译 |
| SDDM | pkgsrc | ❌ 未安装 |
| Konsole | pkgsrc | ❌ 未安装 |

## 应用
| 组件 | 来源 | 状态 |
|------|------|------|
| Firefox | pkgsrc | ❌ 未安装 |
| VSCode | 官方二进制下载 | ⚠️ 兼容性未知 |
| OpenCode | 本项目占位符 | 📋 空模板 |

## 匿名工具
| 组件 | 来源 | 状态 |
|------|------|------|
| Tor | pkgsrc | ⚠️ rc.d 脚本就绪, 未安装 |
| I2PD | GitHub 源码 | ⚠️ 编译脚本就绪, 未测试 |

## Star-Talk 原创组件
| 组件 | 路径 | 状态 |
|------|------|------|
| SWIMSTAR 内核配置 | configs/netbsd/kernel/SWIMSTAR | ✅ 编译通过 |
| 新型风格启动屏 | configs/netbsd/etc/rc.d/startalk-splash | ✅ QEMU 验证运行 |
| 硬盘安装器 | configs/netbsd/install/install.sh | ⚠️ 未测试 |
| 构建脚本 | scripts/netbsd/ | ⚠️ 需手动修复分区 |

## 构建方式
```bash
make kernel      # ✅ 编译 SWIMSTAR 内核
make userland    # ✅ 构建 NetBSD 基础系统  
make image       # ⚠️ 需手动修复分区 + /dev 节点
```
