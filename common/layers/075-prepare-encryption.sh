#!/bin/bash

# Prepare the base installation for encrypted root partition.

# run and execute from configuration scripts (not to be invoked directly): $ curl -L git.io/prepare_encryption_sergey | sh
# (created with: $ curl -i https://git.io -F "url=https://raw.githubusercontent.com/pisarenko-net/arch-bootstrapper/main/common/layers/075-prepare-encryption.sh" -F "code=prepare_encryption_sergey")

echo '==> Altering default GRUB configuration (for encryption)'
/usr/bin/sed -i "s/GRUB_CMDLINE_LINUX_DEFAULT=.*/GRUB_CMDLINE_LINUX_DEFAULT=\"quiet noacpi acpi=off rd.udev.log-priority=3 cryptdevice=UUID=$(blkid ${ROOT_PARTITION} -s UUID -o value):cryptlvm\"/" "${TARGET_DIR}/etc/default/grub"

echo '==> LVM work-around'
/usr/bin/mkdir ${TARGET_DIR}/hostlvm
/usr/bin/mount --bind /run/lvm ${TARGET_DIR}/hostlvm

echo '==> Generating system configuration script (for encryption)'
echo ${ROOT_PASSPHRASE} > ${ENC_KEY_PATH}
/usr/bin/cat <<-EOF >> "${TARGET_DIR}${CONFIG_SCRIPT}"
/usr/bin/ln -s /hostlvm /run/lvm
/usr/bin/sed -i 's/HOOKS=.*/HOOKS=(base udev autodetect modconf block keymap encrypt lvm2 filesystems keyboard fsck)/' /etc/mkinitcpio.conf
# keyless boot
/usr/bin/dd bs=512 count=8 if=/dev/urandom of=/crypto_keyfile.bin
/usr/bin/chmod 000 /crypto_keyfile.bin
/usr/bin/cryptsetup luksAddKey ${ROOT_PARTITION} /crypto_keyfile.bin --key-file=/enc.key
/usr/bin/sed -i 's\^FILES=.*\FILES="/crypto_keyfile.bin"\g' /etc/mkinitcpio.conf
#
/usr/bin/mkinitcpio -p linux
/usr/bin/chmod 600 /boot/initramfs-linux*

#    
# GRUB bootloader installation    
/usr/bin/grub-install --target=x86_64-efi --efi-directory=/boot/efi --bootloader-id=ArchLinux    
/usr/bin/grub-mkconfig -o /boot/grub/grub.cfg    
/usr/bin/sed -i '/echo/d' /boot/grub/grub.cfg
EOF

