#!/bin/bash

# Install base Arch Linux system. Networking configuration is up to each machine definition.

# run and execute from specific configuration scripts: $ curl -L git.io/apfel_bootstrap | sh
# (created with: $ curl -i https://git.io -F "url=https://raw.githubusercontent.com/pisarenko-net/arch-bootstrap-scripts/master/common/bootstrap.sh" -F "code=apfel_bootstrap")

echo '==> Generating system configuration script'
/usr/bin/cat <<-EOF >> "${TARGET_DIR}${CONFIG_SCRIPT}"
#
# GRUB bootloader installation
/usr/bin/grub-install --target=x86_64-efi --efi-directory=/boot/efi --bootloader-id=ArchLinux
/usr/bin/grub-mkconfig -o /boot/grub/grub.cfg
/usr/bin/sed -i '/echo/d' /boot/grub/grub.cfg
#
echo '${FQDN}' > /etc/hostname
/usr/bin/ln -sf /usr/share/zoneinfo/${TIMEZONE} /etc/localtime
echo 'KEYMAP=${KEYMAP}' > /etc/vconsole.conf
echo 'LANG=en_US.UTF-8' > /etc/locale.conf
/usr/bin/sed -i 's/#${LANGUAGE}/${LANGUAGE}/' /etc/locale.gen
/usr/bin/locale-gen
echo "root:${ROOT_PASSWORD}" | /usr/bin/chpasswd
# https://wiki.archlinux.org/index.php/Network_Configuration#Device_names
/usr/bin/ln -s /dev/null /etc/udev/rules.d/80-net-setup-link.rules
/usr/bin/systemctl enable sshd.service
/usr/bin/useradd --password ${PASSWORD} --create-home --user-group ${USER}
echo '${USER} ALL=(ALL) NOPASSWD: ALL' >> /etc/sudoers.d/10_${USER}
/usr/bin/chmod 0440 /etc/sudoers.d/10_${USER}
/usr/bin/install --directory --owner=${USER} --group=${USER} --mode=0700 /home/${USER}/.ssh
/usr/bin/curl --output /home/${USER}/.ssh/authorized_keys --location https://raw.githubusercontent.com/pisarenko-net/arch-bootstrap-scripts/master/master-key.pub
/usr/bin/chown ${USER}:${USER} /home/${USER}/.ssh/authorized_keys
/usr/bin/chmod 0600 /home/${USER}/.ssh/authorized_keys
/usr/bin/sed -i 's/#PasswordAuthentication yes/PasswordAuthentication no/' /etc/ssh/sshd_config
/usr/bin/ln -s /usr/bin/nvim /usr/bin/vi
/usr/bin/ln -s /usr/bin/nvim /usr/bin/vim
#
/usr/bin/hwclock --systohc --utc
# Clean the pacman cache.
/usr/bin/yes | /usr/bin/pacman -Scc
EOF

echo '==> Entering chroot and configuring system'
/usr/bin/arch-chroot ${TARGET_DIR} ${CONFIG_SCRIPT}
/usr/bin/rm "${TARGET_DIR}${CONFIG_SCRIPT}"
/usr/bin/rm "${ENC_KEY_PATH}"

/usr/bin/umount ${TARGET_DIR}/hostlvm
/usr/bin/rm -rf ${TARGET_DIR}/hostlvm

/usr/bin/umount ${TARGET_DIR}/boot/efi
/usr/bin/umount ${TARGET_DIR}/boot
