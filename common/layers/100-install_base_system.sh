#!/bin/bash

# Install base Arch Linux system. Networking configuration is up to each machine definition.

# run and execute from configuration scripts (not to be invoked directly): $ curl -L git.io/install_base_system_sergey | sh
# (created with: $ curl -i https://git.io -F "url=https://raw.githubusercontent.com/pisarenko-net/arch-bootstrapper/main/common/layers/100-install_base_system.sh" -F "code=install_base_system_sergey")

PASSWORD=$(/usr/bin/openssl passwd -crypt 'test')
ROOT_PASSWORD=`/usr/bin/openssl rand -base64 32`

echo '==> Generating system configuration script'
/usr/bin/cat <<-EOF >> "${TARGET_DIR}${CONFIG_SCRIPT}"
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
/usr/bin/useradd --password ${PASSWORD} --create-home --user-group ${LUSER}
echo '${LUSER} ALL=(ALL) NOPASSWD: ALL' >> /etc/sudoers.d/10_${LUSER}
/usr/bin/chmod 0440 /etc/sudoers.d/10_${LUSER}
/usr/bin/install --directory --owner=${LUSER} --group=${LUSER} --mode=0700 /home/${LUSER}/.ssh
/usr/bin/curl --output /home/${LUSER}/.ssh/authorized_keys --location https://raw.githubusercontent.com/pisarenko-net/arch-bootstrapper/main/master-key.pub
/usr/bin/chown ${LUSER}:${LUSER} /home/${LUSER}/.ssh/authorized_keys
/usr/bin/chmod 0600 /home/${LUSER}/.ssh/authorized_keys
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
