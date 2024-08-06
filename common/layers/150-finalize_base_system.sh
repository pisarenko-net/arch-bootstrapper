#!/bin/bash

# Install base Arch Linux system. Networking configuration is up to each machine definition.

# run and execute from configuration scripts (not to be invoked directly): $ curl -L v-u.cc/finalize_base_system | sh

/usr/bin/rm "${ENC_KEY_PATH}"
/usr/bin/umount ${TARGET_DIR}/hostlvm
/usr/bin/rm -rf ${TARGET_DIR}/hostlvm

/usr/bin/umount ${TARGET_DIR}/boot/efi 
/usr/bin/umount ${TARGET_DIR}/boot
