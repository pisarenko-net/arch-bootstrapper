#!/bin/bash

# Partition system drive for Arch Linux installation on a physical host with encryption.

# run and execute from configuration scripts (not to be invoked directly): $ curl -L t.ly/xama/partition_drive | sh

echo "==> Create GPT partition table on ${DISK}"
/usr/bin/sgdisk -og ${DISK}

echo "==> Destroying magic strings and signatures on ${DISK}"
/usr/bin/dd if=/dev/zero of=${DISK} bs=512 count=2048
/usr/bin/wipefs --all ${DISK}

echo "==> Creating EFI System partition on ${DISK}"
/usr/bin/sgdisk -n 1:2048:1050623 -c 1:"EFI System partition" -t 1:ef00 ${DISK}

echo "==> Creating boot partition on ${DISK}"
/usr/bin/sgdisk -n 2:1050624:1460223 -c 2:"Boot partition" -t 2:8300 ${DISK}

echo "==> Creating /root partition on ${DISK}"
ENDSECTOR=`/usr/bin/sgdisk -E ${DISK}`
/usr/bin/sgdisk -n 3:1460224:$ENDSECTOR -c 3:"Root partition" -t 3:8E00 ${DISK}

echo '==> Creating EFI filesystem (FAT32)'
/usr/bin/mkfs.fat -F32 $EFI_PARTITION

echo '==> Creating /boot filesystem (ext2)'
/usr/bin/mkfs.ext2 -F ${BOOT_PARTITION}

echo '==> Creating encrypted /root filesystem (btrfs)'
echo ${ROOT_PASSPHRASE} > enc.key
/usr/bin/cryptsetup -q luksFormat $ROOT_PARTITION --key-file=enc.key
/usr/bin/cryptsetup open $ROOT_PARTITION cryptlvm --key-file=enc.key
/usr/bin/pvcreate /dev/mapper/cryptlvm
/usr/bin/vgcreate vg0 /dev/mapper/cryptlvm
/usr/bin/lvcreate -l 100%FREE vg0 -n root
/usr/bin/mkfs.btrfs /dev/mapper/vg0-root

echo "==> Mounting /root to ${TARGET_DIR}"
/usr/bin/mount /dev/mapper/vg0-root ${TARGET_DIR}
genfstab -U ${TARGET_DIR} > /tmp/fstab
echo "==> Mounting /boot to ${TARGET_DIR}/boot"
/usr/bin/mkdir ${TARGET_DIR}/boot
/usr/bin/mount ${BOOT_PARTITION} ${TARGET_DIR}/boot
echo "==> Mounting EFI partition"
/usr/bin/mkdir ${TARGET_DIR}/boot/efi
/usr/bin/mount $EFI_PARTITION ${TARGET_DIR}/boot/efi
