#!/bin/bash

# Prepare for base installation. 

# run and execute from configuration scripts (not to be invoked directly): $ curl -L git.io/prepare_base_system_sergey | sh
# (created with: $ curl -i https://git.io -F "url=https://raw.githubusercontent.com/pisarenko-net/arch-bootstrapper/main/common/layers/050-prepare_base_system.sh" -F "code=prepare_base_system_sergey")

echo "==> Setting local mirror"
/usr/bin/curl -s -L "$MIRRORLIST" |  sed 's/^#Server/Server/' > /etc/pacman.d/mirrorlist

echo '==> Bootstrapping the base installation'
/usr/bin/pacstrap ${TARGET_DIR} base base-devel lvm2 linux linux-firmware btrfs-progs netctl neovim dhcpcd openssh grub-efi-x86_64 efibootmgr net-tools intel-ucode wget git tmux mosh less

echo '==> Generating the filesystem table'
/usr/bin/cat /tmp/fstab >> "${TARGET_DIR}/etc/fstab"

echo '==> Generating the system configuration script'
/usr/bin/install --mode=0755 /dev/null "${TARGET_DIR}${CONFIG_SCRIPT}"

echo '==> Altering default GRUB configuration'
/usr/bin/sed -i 's/GRUB_TIMEOUT=.*/GRUB_TIMEOUT=0/' "${TARGET_DIR}/etc/default/grub"

