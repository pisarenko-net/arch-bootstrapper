#!/usr/bin/env bash

echo "==> Create GPT partition table on ${DISK}"
/usr/bin/sgdisk -og ${DISK}

echo "==> Destroying magic strings and signatures on ${DISK}"
/usr/bin/dd if=/dev/zero of=${DISK} bs=512 count=2048
/usr/bin/wipefs --all ${DISK}

echo "==> Creating /boot EFI partition on ${DISK}"
/usr/bin/sgdisk -n 1:2048:2098175 -c 1:"EFI boot partition" -t 1:ef00 ${DISK}

echo "==> Creating /root partition on ${DISK}"
ENDSECTOR=`/usr/bin/sgdisk -E ${DISK}`
/usr/bin/sgdisk -n 2:2098176:$ENDSECTOR -c 2:"Linux root partition" -t 2:8300 ${DISK}

echo '==> Creating /boot filesystem (FAT32)'
/usr/bin/mkfs.fat -F32 $BOOT_PARTITION

echo '==> Creating /root filesystem (btrfs)'
/usr/bin/mkfs.btrfs $ROOT_PARTITION

echo "==> Mounting ${ROOT_PARTITION} to ${TARGET_DIR}"
/usr/bin/mount ${ROOT_PARTITION} ${TARGET_DIR}
echo "==> Mounting ${BOOT_PARTITION} to ${TARGET_DIR}/boot"
/usr/bin/mkdir ${TARGET_DIR}/boot
/usr/bin/mount ${BOOT_PARTITION} ${TARGET_DIR}/boot

