#!/usr/bin/env bash

PASSWORD=$(/usr/bin/openssl passwd -crypt 'vagrant')

echo '==> Modifying GRUB config'
/usr/bin/sed -i 's/GRUB_CMDLINE_LINUX_DEFAULT=".*"/GRUB_CMDLINE_LINUX_DEFAULT="quiet video=1360x768"/' "${TARGET_DIR}/etc/default/grub"

cat <<-EOF >> "${TARGET_DIR}${CONFIG_SCRIPT}"

# Vagrant-specific configuration
/usr/bin/useradd --password ${PASSWORD} --comment 'Vagrant User' --create-home --user-group vagrant
echo 'Defaults env_keep += "SSH_AUTH_SOCK"' > /etc/sudoers.d/10_vagrant
echo 'vagrant ALL=(ALL) NOPASSWD: ALL' >> /etc/sudoers.d/10_vagrant
/usr/bin/chmod 0440 /etc/sudoers.d/10_vagrant
/usr/bin/install --directory --owner=vagrant --group=vagrant --mode=0700 /home/vagrant/.ssh
/usr/bin/curl --output /home/vagrant/.ssh/authorized_keys --location https://raw.github.com/mitchellh/vagrant/master/keys/vagrant.pub
/usr/bin/chown vagrant:vagrant /home/vagrant/.ssh/authorized_keys
/usr/bin/chmod 0600 /home/vagrant/.ssh/authorized_keys

EOF
