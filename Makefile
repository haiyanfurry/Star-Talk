# Star-Talk / 星语 — Top-Level Makefile
# Live Linux Distribution Build System
#
# Usage:
#   make all          — Build everything and create USB image
#   make kernel       — Recompile kernel only
#   make busybox      — Build BusyBox (static + dynamic)
#   make core-libs    — Build core system libraries
#   make system-daemons — Build dbus, elogind
#   make graphics     — Build Mesa, Wayland, graphics stack
#   make desktop      — Build Niri, waybar, wofi, foot
#   make audio        — Build PipeWire
#   make anonymity    — Build Tor, obfs4proxy, i2pd
#   make apps         — Fetch Firefox, Steam, Proton
#   make initramfs    — Assemble initramfs
#   make rootfs       — Assemble root filesystem
#   make usb-image    — Create final USB disk image
#   make burn DEVICE=/dev/sdX — Write image to USB
#   make clean        — Clean build artifacts
#   make clean-all    — Deep clean (remove downloaded sources)
#   make test-qemu    — Test image in QEMU

JOBS ?= $(shell nproc)
PROJECT_ROOT := $(shell pwd)
SCRIPTS_DIR := $(PROJECT_ROOT)/scripts
SHELL := /bin/bash

export PROJECT_ROOT JOBS

.PHONY: all kernel busybox core-libs system-daemons graphics desktop \
        audio anonymity apps initramfs rootfs squashfs usb-image \
        burn clean clean-all test-qemu help

# ── Default target ──────────────────────────────────────────────
all: kernel busybox core-libs system-daemons graphics desktop \
     audio anonymity apps initramfs rootfs usb-image

# ── Build phases ────────────────────────────────────────────────
prepare:
	@$(SCRIPTS_DIR)/00-prepare.sh

kernel:
	@$(SCRIPTS_DIR)/01-kernel.sh

busybox: prepare
	@$(SCRIPTS_DIR)/03-busybox.sh

core-libs: busybox
	@$(SCRIPTS_DIR)/04-core-libs.sh

system-daemons: core-libs
	@$(SCRIPTS_DIR)/05-system-daemons.sh

graphics: system-daemons
	@$(SCRIPTS_DIR)/06-graphics.sh

desktop: graphics
	@$(SCRIPTS_DIR)/07-desktop.sh

audio: system-daemons
	@$(SCRIPTS_DIR)/08-audio.sh

anonymity: system-daemons
	@$(SCRIPTS_DIR)/09-anonymity.sh

apps: desktop
	@$(SCRIPTS_DIR)/10-applications.sh

initramfs: busybox
	@$(SCRIPTS_DIR)/20-assemble-initramfs.sh

rootfs: busybox core-libs system-daemons graphics desktop audio anonymity apps
	@$(SCRIPTS_DIR)/21-assemble-rootfs.sh

squashfs: rootfs
	@$(SCRIPTS_DIR)/22-make-squashfs.sh

usb-image: kernel initramfs rootfs
	@$(SCRIPTS_DIR)/23-make-usb-image.sh

# ── Burn to USB ─────────────────────────────────────────────────
burn: usb-image
	@if [ -z "$(DEVICE)" ]; then \
		echo "Usage: make burn DEVICE=/dev/sdX"; \
		lsblk -o NAME,SIZE,TYPE,MOUNTPOINT,LABEL; \
		exit 1; \
	fi
	@$(SCRIPTS_DIR)/24-burn-usb.sh $(DEVICE)

# ── Testing ─────────────────────────────────────────────────────
test-qemu: usb-image
	@$(SCRIPTS_DIR)/25-test-qemu.sh

# ── Maintenance ─────────────────────────────────────────────────
clean:
	rm -rf $(PROJECT_ROOT)/work/build/*
	rm -f $(PROJECT_ROOT)/out/*.squashfs
	rm -f $(PROJECT_ROOT)/out/initramfs.cpio.zst
	@echo "Build artifacts cleaned."

clean-all: clean
	rm -rf $(PROJECT_ROOT)/work/sources/*
	rm -f $(PROJECT_ROOT)/out/*.img
	@echo "Deep clean complete."

# ── Help ────────────────────────────────────────────────────────
help:
	@echo "╔══════════════════════════════════════════════════════════╗"
	@echo "║          Star-Talk / 星语 — Build System                ║"
	@echo "╠══════════════════════════════════════════════════════════╣"
	@echo "║  make all          Build everything → USB image         ║"
	@echo "║  make kernel       Recompile kernel (SQUASHFS+OVERLAY)  ║"
	@echo "║  make busybox      Build BusyBox static + dynamic       ║"
	@echo "║  make core-libs    Build zlib, openssl, ncurses, etc.   ║"
	@echo "║  make system-daemons Build dbus + elogind               ║"
	@echo "║  make graphics     Build Mesa + Wayland stack           ║"
	@echo "║  make desktop      Build Niri + waybar + wofi + foot    ║"
	@echo "║  make audio        Build PipeWire + wireplumber         ║"
	@echo "║  make anonymity    Build tor + obfs4proxy + i2pd        ║"
	@echo "║  make apps         Fetch Firefox/Steam/Proton binaries  ║"
	@echo "║  make initramfs    Assemble initramfs cpio              ║"
	@echo "║  make rootfs       Assemble root filesystem             ║"
	@echo "║  make usb-image    Create final USB disk image          ║"
	@echo "║  make burn DEVICE=/dev/sdX  Write image to USB          ║"
	@echo "║  make test-qemu    Test boot in QEMU                    ║"
	@echo "║  make clean        Clean build artifacts                ║"
	@echo "║  make clean-all    Deep clean (remove sources)          ║"
	@echo "╚══════════════════════════════════════════════════════════╝"
	@echo ""
	@echo "Jobs: $(JOBS) cores"
	@echo "Project: $(PROJECT_ROOT)"
