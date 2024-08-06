#!/bin/bash

# run and execute after dropping into arch installer: $ curl -L git.io/bootstrap_ch_router_sergey | sh
# (created with: $ curl -i https://git.io -F "url=https://raw.githubusercontent.com/pisarenko-net/arch-bootstrapper/main/physical/ch.router/000-bootstrap.sh" -F "code=bootstrap_ch_router_sergey")

export DISK='/dev/sda'

export FQDN='ch.router.xama'
export LUSER='sergey'
export KEYMAP='us'
export LANGUAGE='en_US.UTF-8'
export TIMEZONE='Europe/Zurich'

export CONFIG_SCRIPT='/usr/local/bin/arch-config.sh'
export EFI_PARTITION="${DISK}1"
export BOOT_PARTITION="${DISK}2"
export ROOT_PARTITION="${DISK}3"
export ROOT_PASSPHRASE=`/usr/bin/openssl rand -base64 32`
export TARGET_DIR='/mnt'
export ENC_KEY_PATH="${TARGET_DIR}/enc.key"
export COUNTRY='CH'
export MIRRORLIST="https://www.archlinux.org/mirrorlist/?country=${COUNTRY}&protocol=http&protocol=https&ip_version=4&use_mirror_status=on"
export LAN_IFACE="eth1"
export INSTALL_IFACE="eth2"

eval "`/usr/bin/curl -L v-u.cc/partition_drive`"
eval "`/usr/bin/curl -L v-u.cc/prepare_base_system`"
eval "`/usr/bin/curl -L v-u.cc/prepare_encryption`"
eval "`/usr/bin/curl -L v-u.cc/install_base_system`"
eval "`/usr/bin/curl -L v-u.cc/finalize_base_system`"

echo '==> Configuring network using service NIC'
/usr/bin/cat <<-EOF > "${TARGET_DIR}/etc/netctl/install-nic"
Interface=${INSTALL_IFACE}
Connection=ethernet
IP=dhcp
EOF
/usr/bin/arch-chroot ${TARGET_DIR} /usr/bin/netctl enable install-nic

echo '==> Configuring LAN interface'
/usr/bin/cat <<-EOF > "${TARGET_DIR}/etc/netctl/trusted_lan"
Interface=${LAN_IFACE}
Connection=ethernet
IP=static
Address=('10.250.250.1/24')

ForceConnect=yes
SkipNoCarrier=yes
EOF
/usr/bin/arch-chroot ${TARGET_DIR} /usr/bin/netctl enable trusted_lan

echo '==> Prepopulating shell history'
echo 'curl -L v-u.cc/install_ch_router | sh' >> "${TARGET_DIR}/root/.bash_history"
echo 'vi private.key' >> "${TARGET_DIR}/root/.bash_history"

echo '==> Install complete!'
/usr/bin/sleep 5
/usr/bin/umount ${TARGET_DIR}
/usr/bin/reboot
