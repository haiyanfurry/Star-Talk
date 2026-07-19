JOBS ?= $(shell nproc 2>/dev/null || echo 4)
PROJECT_ROOT := $(shell pwd)
SCRIPTS_DIR := $(PROJECT_ROOT)/scripts/netbsd
WORK_DIR := $(PROJECT_ROOT)/work
OUT_DIR := $(PROJECT_ROOT)/out
SHELL := /bin/sh
export PROJECT_ROOT JOBS WORK_DIR OUT_DIR

.PHONY: all kernel userland packages desktop rootfs image burn test-qemu clean clean-all help

all: kernel userland packages desktop rootfs image
	@echo ""
	@echo "  ★ Star-Talk build complete!"
	@echo "  Image: out/star-talk-netbsd-$$(date +%Y%m%d).img"
	@echo ""

kernel:
	@[ -f $(OUT_DIR)/netbsd ] && echo "Kernel already built." || $(SCRIPTS_DIR)/01-kernel.sh

userland:
	@[ -f $(WORK_DIR)/.userland-done ] && echo "Userland already built." || ($(SCRIPTS_DIR)/02-userland.sh && touch $(WORK_DIR)/.userland-done)

packages:
	@[ -f $(WORK_DIR)/.packages-done ] && echo "Packages already installed." || ($(SCRIPTS_DIR)/03-packages.sh && touch $(WORK_DIR)/.packages-done)

desktop:
	@[ -f $(WORK_DIR)/.desktop-done ] && echo "Desktop already configured." || ($(SCRIPTS_DIR)/04-desktop.sh && touch $(WORK_DIR)/.desktop-done)

rootfs:
	@[ -f $(WORK_DIR)/.rootfs-done ] && echo "RootFS already assembled." || ($(SCRIPTS_DIR)/05-assemble-rootfs.sh && touch $(WORK_DIR)/.rootfs-done)

image:
	@$(SCRIPTS_DIR)/06-make-image.sh

burn: image
	@if [ -z "$(DEVICE)" ]; then \
		echo "Usage: make burn DEVICE=/dev/sdX"; \
		lsblk -o NAME,SIZE,TYPE,MOUNTPOINT 2>/dev/null || echo "(lsblk not available)"; \
		exit 1; \
	fi
	@IMAGE=$$(ls -t out/star-talk-netbsd-*.img 2>/dev/null | head -1); \
	if [ -z "$$IMAGE" ]; then echo "No image found."; exit 1; fi; \
	echo "Writing $$IMAGE to $(DEVICE)..."; sleep 3; \
	dd if="$$IMAGE" of="$(DEVICE)" bs=1M conv=fsync status=progress

test-qemu: image
	@$(SCRIPTS_DIR)/07-test-qemu.sh

clean:
	rm -f $(WORK_DIR)/.userland-done $(WORK_DIR)/.packages-done $(WORK_DIR)/.desktop-done $(WORK_DIR)/.rootfs-done
	rm -rf $(WORK_DIR)/rootfs-staging/*
	rm -f $(OUT_DIR)/star-talk-netbsd-*.img
	@echo "Clean done."

clean-all: clean
	rm -rf $(WORK_DIR)/netbsd-obj $(WORK_DIR)/netbsd-tools $(WORK_DIR)/netbsd-dest $(WORK_DIR)/pkgsrc
	rm -f $(OUT_DIR)/netbsd
	@echo "Deep clean done."

help:
	@echo "╔══════════════════════════════════════════════════════════════╗"
	@echo "║  Star-Talk / 星语 — NetBSD Build System                   ║"
	@echo "╠══════════════════════════════════════════════════════════════╣"
	@echo "║  make kernel     SWIMSTAR kernel  ✅ compiled              ║"
	@echo "║  make userland   NetBSD distribution ✅ built              ║"
	@echo "║  make packages   First-boot setup scripts ✅ done          ║"
	@echo "║  make desktop    KDE + splash configs ✅ done              ║"
	@echo "║  make rootfs     Assemble root filesystem ✅ done          ║"
	@echo "║  make image      Bootable disk image ✅ built              ║"
	@echo "║  make test-qemu  Test in QEMU with bootx64.efi             ║"
	@echo "║  make clean      Remove build artifacts                    ║"
	@echo "╚══════════════════════════════════════════════════════════════╝"
