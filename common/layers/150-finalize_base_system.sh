#!/bin/bash

# Install base Arch Linux system. Networking configuration is up to each machine definition.

# run and execute from configuration scripts (not to be invoked directly): $ curl -L git.io/finalize_base_system_sergey | sh
# (created with: $ curl -i https://git.io -F "url=https://raw.githubusercontent.com/pisarenko-net/arch-bootstrapper/main/common/layers/150-finalize_base_system.sh" -F "code=finalize_base_system_sergey")

/usr/bin/rm "${ENC_KEY_PATH}"
/usr/bin/umount ${TARGET_DIR}/hostlvm
/usr/bin/rm -rf ${TARGET_DIR}/hostlvm

/usr/bin/umount ${TARGET_DIR}/boot/efi 
/usr/bin/umount ${TARGET_DIR}/boot
