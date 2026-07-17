# ╔══════════════════════════════════════════════════════════════════════╗
# ║  Star-Talk / 星语 — Top-Level Makefile (NetBSD Edition)            ║
# ║  NetBSD-based Desktop Operating System Build System                ║
# ╚══════════════════════════════════════════════════════════════════════╝
#
# Usage:
#   make all           — Build everything and create bootable disk image
#   make kernel        — Build NetBSD SWIMSTAR kernel only
#   make userland      — Build NetBSD userland (distribution)
#   make packages      — Install KDE, Firefox, VSCode, Tor, I2PD via pkgsrc
#   make desktop       — Configure KDE Plasma desktop + wallpapers
#   make rootfs        — Assemble root filesystem
#   make image         — Create final bootable disk image
#   make installer     — Build installer ISO/USB
#   make burn DEVICE=  — Write image to USB device
#   make test-qemu     — Test boot in QEMU
#   make clean         — Clean build artifacts
#   make clean-all     — Deep clean (remove all work)
#   make help          — Show this help
#
# Architecture: NetBSD kernel + KDE Plasma 5 desktop
# Init system: NetBSD rc.d (AIX-style boot splash)
# Package manager: pkgsrc

JOBS ?= $(shell nproc 2>/dev/null || sysctl -n hw.ncpu 2>/dev/null || echo 4)
PROJECT_ROOT := $(shell pwd)
SCRIPTS_DIR := $(PROJECT_ROOT)/scripts/netbsd
SHELL := /bin/sh

export PROJECT_ROOT JOBS

.PHONY: all kernel userland packages desktop rootfs image \
        installer burn test-qemu clean clean-all help

# ═══════════════════════════════════════════════════════════════════════
# Default target
# ═══════════════════════════════════════════════════════════════════════
all: kernel userland packages desktop rootfs image
	@echo ""
	@echo "  ★ Star-Talk / 星语 build complete!"
	@echo "  Image: out/star-talk-netbsd-$$(date +%Y%m%d).img"
	@echo ""

# ═══════════════════════════════════════════════════════════════════════
# Build Phases
# ═══════════════════════════════════════════════════════════════════════

kernel:
	@$(SCRIPTS_DIR)/01-kernel.sh

userland: kernel
	@$(SCRIPTS_DIR)/02-userland.sh

packages: userland
	@$(SCRIPTS_DIR)/03-packages.sh

desktop: packages
	@$(SCRIPTS_DIR)/04-desktop.sh

rootfs: desktop
	@$(SCRIPTS_DIR)/05-assemble-rootfs.sh

image: rootfs
	@$(SCRIPTS_DIR)/06-make-image.sh

installer: image
	@echo "Installer image built as part of disk image."

# ═══════════════════════════════════════════════════════════════════════
# Burn to USB
# ═══════════════════════════════════════════════════════════════════════
burn: image
	@if [ -z "$(DEVICE)" ]; then \
		echo "Usage: make burn DEVICE=/dev/sdX"; \
		echo ""; \
		echo "Available devices:"; \
		if command -v lsblk >/dev/null 2>&1; then \
			lsblk -o NAME,SIZE,TYPE,MOUNTPOINT; \
		else \
			echo "(lsblk not available — check dmesg)"; \
		fi; \
		exit 1; \
	fi
	@IMAGE=$$(ls -t out/star-talk-netbsd-*.img 2>/dev/null | head -1); \
	if [ -z "$$IMAGE" ]; then \
		echo "No image found. Run 'make image' first."; \
		exit 1; \
	fi; \
	echo "Writing $$IMAGE to $(DEVICE)..."; \
	echo "WARNING: This will DESTROY all data on $(DEVICE)!"; \
	echo "Press Ctrl+C within 5 seconds to cancel..."; \
	sleep 5; \
	dd if="$$IMAGE" of="$(DEVICE)" bs=1M conv=fsync status=progress && \
		echo "Done! $(DEVICE) is ready." || \
		echo "Write failed. Check device and permissions."

# ═══════════════════════════════════════════════════════════════════════
# Testing
# ═══════════════════════════════════════════════════════════════════════
test-qemu: image
	@$(SCRIPTS_DIR)/07-test-qemu.sh

# ═══════════════════════════════════════════════════════════════════════
# Maintenance
# ═══════════════════════════════════════════════════════════════════════
clean:
	rm -rf $(PROJECT_ROOT)/work/netbsd-obj/*
	rm -rf $(PROJECT_ROOT)/work/rootfs-staging/*
	rm -f $(PROJECT_ROOT)/out/star-talk-netbsd-*.img
	@echo "Build artifacts cleaned."
	@echo "Use 'make clean-all' to remove source trees too."

clean-all: clean
	rm -rf $(PROJECT_ROOT)/work/netbsd-src
	rm -rf $(PROJECT_ROOT)/work/pkgsrc
	rm -rf $(PROJECT_ROOT)/work/netbsd-tools
	rm -rf $(PROJECT_ROOT)/work/netbsd-dest
	rm -rf $(PROJECT_ROOT)/work/rootfs-staging
	rm -f $(PROJECT_ROOT)/out/netbsd
	@echo "Deep clean complete. All sources removed."

# ═══════════════════════════════════════════════════════════════════════
# Help
# ═══════════════════════════════════════════════════════════════════════
help:
	@echo "╔══════════════════════════════════════════════════════════════╗"
	@echo "║        Star-Talk / 星语 — NetBSD Build System              ║"
	@echo "╠══════════════════════════════════════════════════════════════╣"
	@echo "║  make all         Build everything → disk image             ║"
	@echo "║  make kernel      Build NetBSD SWIMSTAR kernel             ║"
	@echo "║  make userland    Build NetBSD distribution                ║"
	@echo "║  make packages    Install KDE/Firefox/VSCode/Tor/I2PD      ║"
	@echo "║  make desktop     Configure KDE Plasma + wallpapers        ║"
	@echo "║  make rootfs      Assemble root filesystem                 ║"
	@echo "║  make image       Create bootable disk image               ║"
	@echo "║  make burn DEVICE=/dev/sdX  Write to USB                   ║"
	@echo "║  make test-qemu   Test boot in QEMU                        ║"
	@echo "║  make clean       Clean artifacts                          ║"
	@echo "║  make clean-all   Deep clean (remove sources)              ║"
	@echo "║  make help        Show this help                           ║"
	@echo "╠══════════════════════════════════════════════════════════════╣"
	@echo "║  Kernel:    NetBSD-current (SWIMSTAR config) ✅ compiled   ║"
	@echo "║  Desktop:   KDE Plasma 6 + SDDM (⏳ not yet built)        ║"
	@echo "║  Terminal:  Konsole                                        ║"
	@echo "║  Browser:   Firefox (zh-CN)                                ║"
	@echo "║  Editor:    VSCode (code-oss) + OpenCode                   ║"
	@echo "║  Anonymity: Tor + I2PD (disabled by default)               ║"
	@echo "║  Arch:      ${shell uname -m}                               ║"
	@echo "║  Jobs:      ${JOBS}                                         ║"
	@echo "╚══════════════════════════════════════════════════════════════╝"
	@echo ""
	@echo "Project: $(PROJECT_ROOT)"
	@echo "License: GPL-3.0 — Copyright (C) 2026 Hai Yan (海盐)"
