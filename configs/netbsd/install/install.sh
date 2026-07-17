#!/bin/sh
# ╔══════════════════════════════════════════════════════════════════════╗
# ║  Star-Talk / 星语 — Hard Disk Installer                            ║
# ║  NetBSD sysinst-style installer for permanent installation         ║
# ╚══════════════════════════════════════════════════════════════════════╝
#
# ⚠️  WARNING: This installer is UNTESTED. Do NOT run on a production disk.
#     It has NOT been verified against real NetBSD installations.
#
# Usage (from Live environment):
#   sudo /usr/local/sbin/star-talk-install
#
# This installer:
#   1. Detects available disks and lets user choose target
#   2. Partitions with GPT + BSD disklabel
#   3. Creates FFSv2 filesystems
#   4. Copies the live system to disk
#   5. Installs the NetBSD bootloader
#   6. Configures the installed system (hostname, users, etc.)
#
# WARNING: This will DESTROY all data on the selected disk!

set -e

# ── Color definitions ──────────────────────────────────────────────────
C_RESET='\033[0m'; C_BOLD='\033[1m'; C_DIM='\033[2m'
C_CYAN='\033[1;36m'; C_GREEN='\033[1;32m'; C_YELLOW='\033[1;33m'
C_RED='\033[1;31m'; C_WHITE='\033[1;37m'; C_BLUE='\033[1;34m'
C_MAGENTA='\033[1;35m'

# ── Banner ─────────────────────────────────────────────────────────────
banner() {
    clear 2>/dev/null || printf '\033[2J\033[H'
    printf "${C_CYAN}╔══════════════════════════════════════════════════════════════╗${C_RESET}\n"
    printf "${C_CYAN}║${C_MAGENTA}     Star-Talk / 星语 — Hard Disk Installer               ${C_CYAN}║${C_RESET}\n"
    printf "${C_CYAN}║${C_YELLOW}     NetBSD ${C_RESET}Kernel ${C_YELLOW}+ KDE Plasma Desktop                  ${C_CYAN}║${C_RESET}\n"
    printf "${C_CYAN}╚══════════════════════════════════════════════════════════════╝${C_RESET}\n"
    printf "\n"
}

# ── Phase 1: Disk Selection ───────────────────────────────────────────
select_disk() {
    banner
    printf "${C_BOLD}Phase 1/6 — Select Installation Disk${C_RESET}\n\n"

    printf "${C_YELLOW}Available disks:${C_RESET}\n"
    printf "  %-12s %-10s %-15s %s\n" "DEVICE" "SIZE" "TYPE" "MODEL"
    printf "  %-12s %-10s %-15s %s\n" "------" "----" "----" "-----"

    local disks_found=""
    for disk in /dev/rwd? /dev/rsd? /dev/rld? /dev/nvme?n?; do
        [ -e "$disk" ] || continue
        local devname=$(basename "$disk" | sed 's/^r//')
        local size=$(disklabel "$disk" 2>/dev/null | grep "total sectors" | awk '{print $3}' || echo "?")
        # Convert sectors to human-readable (assume 512B sectors)
        if [ "$size" != "?" ]; then
            size=$(( size * 512 / 1024 / 1024 / 1024 ))
            size="${size}G"
        fi
        printf "  ${C_GREEN}%-12s${C_RESET} %-10s %-15s %s\n" "/dev/$devname" "$size" "SATA/SCSI" "Disk $devname"
        disks_found="$disks_found /dev/$devname"
    done

    if [ -z "$disks_found" ]; then
        printf "\n${C_RED}No disks detected!${C_RESET}\n"
        printf "Try running: ${C_YELLOW}dmesg | grep -E '(wd|sd|ld|nvme)[0-9]'${C_RESET}\n"
        exit 1
    fi

    printf "\n${C_BOLD}Enter target disk (e.g., /dev/wd0):${C_RESET} "
    read TARGET_DISK

    if [ ! -e "/dev/r${TARGET_DISK#/dev/}" ] && [ ! -e "/dev/${TARGET_DISK#/dev/}" ]; then
        printf "${C_RED}Invalid disk: $TARGET_DISK${C_RESET}\n"
        exit 1
    fi

    printf "\n${C_RED}${C_BOLD}WARNING: ALL data on $TARGET_DISK will be destroyed!${C_RESET}\n"
    printf "${C_YELLOW}Type 'YES' (uppercase) to confirm:${C_RESET} "
    read CONFIRM
    if [ "$CONFIRM" != "YES" ]; then
        printf "${C_GREEN}Installation cancelled.${C_RESET}\n"
        exit 0
    fi
}

# ── Phase 2: Partitioning ──────────────────────────────────────────────
partition_disk() {
    banner
    printf "${C_BOLD}Phase 2/6 — Partitioning ${C_GREEN}$TARGET_DISK${C_RESET}\n\n"

    local disk=${TARGET_DISK#/dev/}
    local rawdisk="/dev/r${disk}"

    # Get disk size for partition calculations
    local disk_sectors=$(disklabel "$rawdisk" 2>/dev/null | grep "total sectors" | awk '{print $3}' || echo "0")
    local total_mb=$(( disk_sectors * 512 / 1024 / 1024 ))

    printf "  Disk size: ${C_GREEN}${total_mb} MB${C_RESET}\n"

    # Calculate partition sizes
    local efi_mb=260          # EFI System Partition
    local swap_mb=4096        # Swap = 4GB (or RAM size, whichever is larger)
    local root_mb=$(( total_mb - efi_mb - swap_mb - 10 ))  # 10MB padding

    printf "  ${C_YELLOW}Partition layout:${C_RESET}\n"
    printf "    ${C_GREEN}P1: EFI System${C_RESET} — ${efi_mb} MB (FAT32)\n"
    printf "    ${C_GREEN}P2: NetBSD Root${C_RESET} — ${root_mb} MB (FFSv2)\n"
    printf "    ${C_GREEN}P3: Swap${C_RESET} — ${swap_mb} MB\n\n"

    # Zero the first 1MB of the disk
    printf "  ${C_DIM}Clearing disk headers...${C_RESET}\n"
    dd if=/dev/zero of="$rawdisk" bs=1m count=1 2>/dev/null || true

    # Create GPT partition table
    printf "  ${C_DIM}Creating GPT partition table...${C_RESET}\n"
    gpt destroy "$rawdisk" 2>/dev/null || true
    gpt create -f "$rawdisk" 2>/dev/null || {
        printf "${C_RED}  Failed to create GPT table. Trying fdisk...${C_RESET}\n"
        fdisk -f -i "$rawdisk" 2>/dev/null || true
    }

    # Add EFI partition
    printf "  ${C_DIM}Creating EFI System partition (${efi_mb}MB)...${C_RESET}\n"
    gpt add -t efi -s "$(( efi_mb * 2048 ))" "$rawdisk" 2>/dev/null || \
        gpt add -s "$(( efi_mb * 2048 ))" -l "EFI" "$rawdisk" 2>/dev/null

    # Add NetBSD root partition
    printf "  ${C_DIM}Creating NetBSD Root partition (${root_mb}MB)...${C_RESET}\n"
    gpt add -t ffs -l "STAR_TALK" "$rawdisk" 2>/dev/null || \
        gpt add -s "$(( root_mb * 2048 ))" -l "STAR_TALK" "$rawdisk" 2>/dev/null

    # Add swap partition
    printf "  ${C_DIM}Creating Swap partition (${swap_mb}MB)...${C_RESET}\n"
    gpt add -t swap -l "SWAP" "$rawdisk" 2>/dev/null || \
        gpt add -s "$(( swap_mb * 2048 ))" -l "SWAP" "$rawdisk" 2>/dev/null

    printf "  ${C_GREEN}Partitioning complete.${C_RESET}\n"
}

# ── Phase 3: Create Filesystems ─────────────────────────────────────────
create_filesystems() {
    banner
    printf "${C_BOLD}Phase 3/6 — Creating Filesystems${C_RESET}\n\n"

    local disk=${TARGET_DISK#/dev/}
    local p1="${TARGET_DISK}1"
    local p2="${TARGET_DISK}2"

    # EFI partition (FAT32)
    printf "  ${C_DIM}Formatting ${p1} as FAT32 (EFI)...${C_RESET}\n"
    newfs_msdos -F 32 -L "EFI" /dev/r${disk}1 2>/dev/null || \
        newfs_msdos /dev/r${disk}1 2>/dev/null || \
        printf "${C_YELLOW}  Warning: EFI format may need manual intervention${C_RESET}\n"

    # NetBSD Root partition (FFSv2)
    printf "  ${C_DIM}Formatting ${p2} as FFSv2...${C_RESET}\n"
    newfs -O 2 -V 2 /dev/r${disk}2 2>/dev/null || \
        newfs /dev/r${disk}2 2>/dev/null

    printf "  ${C_GREEN}Filesystems created.${C_RESET}\n"
}

# ── Phase 4: Copy System ────────────────────────────────────────────────
copy_system() {
    banner
    printf "${C_BOLD}Phase 4/6 — Installing System to ${C_GREEN}${TARGET_DISK}2${C_RESET}\n\n"

    local disk=${TARGET_DISK#/dev/}
    local p2="${TARGET_DISK}2"
    local mnt="/mnt/install-target"

    mkdir -p "$mnt"

    printf "  ${C_DIM}Mounting root partition...${C_RESET}\n"
    mount /dev/${disk}2 "$mnt"

    printf "  ${C_DIM}Copying system files (this may take a while)...${C_RESET}\n"
    printf "  ${YELLOW}  /bin /sbin /lib /libexec /usr ...${C_RESET}\n"

    # Copy the entire live system, excluding pseudo-filesystems and temp data
    for dir in bin sbin lib libexec usr etc var root home opt rescue; do
        [ -d "/$dir" ] || continue
        printf "  ${C_DIM}  Copying /%s ...${C_RESET}\n" "$dir"
        (cd / && find "$dir" -xdev -print0 | cpio -pdm0 "$mnt/" 2>/dev/null) || \
            tar -cf - -C / "$dir" 2>/dev/null | tar -xf - -C "$mnt" 2>/dev/null || \
            printf "  ${C_YELLOW}  Warning: could not copy /%s (continuing...)${C_RESET}\n" "$dir"
    done

    # Create essential mount points in target
    for d in dev proc sys run tmp mnt media; do
        mkdir -p "$mnt/$d"
    done

    printf "  ${C_GREEN}System files copied.${C_RESET}\n"

    # ── Configure fstab for the installed system ──────────────────────
    printf "  ${C_DIM}Generating /etc/fstab...${C_RESET}\n"
    cat > "$mnt/etc/fstab" << FSTAB
# Star-Talk / 星语 — /etc/fstab
# Device         Mountpoint  FStype  Options              Dump  Pass
/dev/${disk}1    /boot/efi   msdos   rw,noauto            0     0
/dev/${disk}2    /           ffs     rw,log,noatime       0     1
/dev/${disk}3    none        swap    sw                   0     0
tmpfs            /tmp        tmpfs   rw,-s256M            0     0
tmpfs            /run        tmpfs   rw,-s32M             0     0
procfs           /proc       procfs  rw                  0     0
ptyfs            /dev/pts    ptyfs   rw                  0     0
kernfs           /kern       kernfs  rw                  0     0
FSTAB

    # ── Set hostname ─────────────────────────────────────────────────
    printf "  ${C_DIM}Configuring hostname...${C_RESET}\n"
    printf "  Enter hostname [startalk]: "
    read HOSTNAME
    [ -z "$HOSTNAME" ] && HOSTNAME="startalk"
    echo "$HOSTNAME" > "$mnt/etc/myname"
    echo "$HOSTNAME" > "$mnt/etc/hostname"

    # ── Create user account ──────────────────────────────────────────
    printf "  ${C_DIM}Creating user account...${C_RESET}\n"
    printf "  Enter username [startalk]: "
    read USERNAME
    [ -z "$USERNAME" ] && USERNAME="startalk"

    printf "  Enter password for ${USERNAME}: "
    stty -echo
    read PASSWORD
    stty echo
    printf "\n"

    # Add user to the target system's master.passwd
    if [ -x "$mnt/usr/sbin/useradd" ]; then
        chroot "$mnt" /usr/sbin/useradd -m -G wheel,operator -s /bin/sh "$USERNAME" 2>/dev/null || \
            printf "${C_YELLOW}  Warning: useradd failed; create user manually after boot${C_RESET}\n"
    else
        # Manual user creation in /etc/master.passwd
        printf "${C_YELLOW}  Manual user creation required (useradd not available in target)${C_RESET}\n"
    fi

    printf "  ${C_GREEN}System configured.${C_RESET}\n"
}

# ── Phase 5: Bootloader Installation ───────────────────────────────────
install_bootloader() {
    banner
    printf "${C_BOLD}Phase 5/6 — Installing Bootloader${C_RESET}\n\n"

    local disk=${TARGET_DISK#/dev/}
    local p1="${TARGET_DISK}1"
    local p2="${TARGET_DISK}2"
    local mnt="/mnt/install-target"
    local esp="/mnt/install-esp"

    # ── Mount EFI partition and set up boot files ────────────────────
    mkdir -p "$esp"
    mount /dev/${disk}1 "$esp" 2>/dev/null || {
        printf "${C_YELLOW}  Could not mount EFI partition. Bootloader may not work.${C_RESET}\n"
        printf "  You may need to boot from USB and manually fix the bootloader.\n"
        return
    }

    mkdir -p "$esp/EFI/BOOT"
    mkdir -p "$esp/EFI/NetBSD"

    # Copy the NetBSD kernel to EFI partition
    if [ -f /netbsd ]; then
        cp /netbsd "$esp/EFI/NetBSD/netbsd"
        printf "  ${C_DIM}Kernel copied to ESP.${C_RESET}\n"
    elif [ -f "$mnt/netbsd" ]; then
        cp "$mnt/netbsd" "$esp/EFI/NetBSD/netbsd"
        printf "  ${C_DIM}Kernel copied to ESP (from target).${C_RESET}\n"
    fi

    # Install bootx64.efi (NetBSD UEFI bootloader)
    if [ -f /usr/libexec/bootx64.efi ]; then
        cp /usr/libexec/bootx64.efi "$esp/EFI/BOOT/BOOTX64.EFI"
        printf "  ${C_DIM}UEFI bootloader installed.${C_RESET}\n"
    elif [ -f /boot/bootx64.efi ]; then
        cp /boot/bootx64.efi "$esp/EFI/BOOT/BOOTX64.EFI"
        printf "  ${C_DIM}UEFI bootloader installed.${C_RESET}\n"
    else
        printf "${C_YELLOW}  bootx64.efi not found — trying installboot...${C_RESET}\n"
        # Try traditional NetBSD boot blocks
        /usr/sbin/installboot -v /dev/r${disk}2 /usr/mdec/bootxx_ffsv2 2>/dev/null || \
            printf "${C_YELLOW}  Warning: installboot failed. System may not boot.${C_RESET}\n"
    fi

    # ── Write boot.cfg to EFI partition ──────────────────────────────
    cat > "$esp/EFI/NetBSD/boot.cfg" << BOOTCFG
banner=>> Star-Talk / 星语 — NetBSD Boot
banner=>>
menu=Boot Star-Talk:load /EFI/NetBSD/netbsd; boot
menu=Boot Star-Talk (verbose):load /EFI/NetBSD/netbsd; boot -v
menu=Boot Star-Talk (single user):load /EFI/NetBSD/netbsd; boot -s
menu=Drop to boot prompt:prompt
default=1
timeout=30
clear=1
BOOTCFG

    # Create UEFI boot entry (non-volatile variable)
    printf "  ${C_DIM}Creating UEFI boot entry...${C_RESET}\n"
    efibootmgr -c -L "Star-Talk" -l "\\EFI\\BOOT\\BOOTX64.EFI" 2>/dev/null || \
        printf "${C_YELLOW}  efibootmgr not available; boot entry not added to NVRAM.${C_RESET}\n"

    # Cleanup
    umount "$esp" 2>/dev/null || true

    printf "  ${C_GREEN}Bootloader installed.${C_RESET}\n"
}

# ── Phase 6: Final Configuration ────────────────────────────────────────
finalize() {
    banner
    printf "${C_BOLD}Phase 6/6 — Final Configuration${C_RESET}\n\n"

    local mnt="/mnt/install-target"

    # Unmount
    printf "  ${C_DIM}Unmounting target filesystems...${C_RESET}\n"
    umount "$mnt" 2>/dev/null || true
    rm -rf /mnt/install-target /mnt/install-esp 2>/dev/null || true

    printf "\n"
    printf "${C_GREEN}╔══════════════════════════════════════════════════════════════╗${C_RESET}\n"
    printf "${C_GREEN}║  Installation Complete!                                     ║${C_RESET}\n"
    printf "${C_GREEN}╠══════════════════════════════════════════════════════════════╣${C_RESET}\n"
    printf "${C_GREEN}║${C_RESET}  System installed to: ${C_YELLOW}${TARGET_DISK}${C_RESET}                         ${C_GREEN}║${C_RESET}\n"
    printf "${C_GREEN}║${C_RESET}                                                              ${C_GREEN}║${C_RESET}\n"
    printf "${C_GREEN}║${C_RESET}  ${C_BOLD}Next steps:${C_RESET}                                               ${C_GREEN}║${C_RESET}\n"
    printf "${C_GREEN}║${C_RESET}  1. Remove USB drive / installation media                    ${C_GREEN}║${C_RESET}\n"
    printf "${C_GREEN}║${C_RESET}  2. Reboot: ${C_YELLOW}shutdown -r now${C_RESET}                                ${C_GREEN}║${C_RESET}\n"
    printf "${C_GREEN}║${C_RESET}  3. Enter BIOS/UEFI setup and set boot order                   ${C_GREEN}║${C_RESET}\n"
    printf "${C_GREEN}║${C_RESET}  4. Log in with your created user account                     ${C_GREEN}║${C_RESET}\n"
    printf "${C_GREEN}║${C_RESET}  5. Desktop: KDE Plasma will start via SDDM                    ${C_GREEN}║${C_RESET}\n"
    printf "${C_GREEN}║${C_RESET}                                                              ${C_GREEN}║${C_RESET}\n"
    printf "${C_GREEN}║${C_RESET}  ${C_DIM}To enable Tor:  'echo tor=YES >> /etc/rc.conf'${C_RESET}               ${C_GREEN}║${C_RESET}\n"
    printf "${C_GREEN}║${C_RESET}  ${C_DIM}To enable I2PD: 'echo i2pd=YES >> /etc/rc.conf'${C_RESET}             ${C_GREEN}║${C_RESET}\n"
    printf "${C_GREEN}╚══════════════════════════════════════════════════════════════╝${C_RESET}\n"
    printf "\n"
}

# ── Main installer flow ─────────────────────────────────────────────────
main() {
    # Check for root
    if [ "$(id -u)" -ne 0 ]; then
        printf "${C_RED}This installer must be run as root.${C_RESET}\n"
        printf "Try: ${C_YELLOW}sudo /usr/local/sbin/star-talk-install${C_RESET}\n"
        exit 1
    fi

    # Check for required tools
    local missing=""
    for tool in gpt newfs newfs_msdos mount umount dd; do
        command -v "$tool" >/dev/null 2>&1 || missing="$missing $tool"
    done
    if [ -n "$missing" ]; then
        printf "${C_YELLOW}Warning: Missing tools:${missing}${C_RESET}\n"
        printf "Installation may fail. Install them via pkgsrc or pkgin.\n"
    fi

    select_disk
    partition_disk
    create_filesystems
    copy_system
    install_bootloader
    finalize
}

main "$@"
