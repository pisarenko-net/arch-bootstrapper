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

eval "`/usr/bin/curl -L git.io/partition_drive_sergey`"
eval "`/usr/bin/curl -L git.io/prepare_base_system_sergey`"
eval "`/usr/bin/curl -L git.io/prepare_encryption_sergey`"
eval "`/usr/bin/curl -L git.io/install_base_system_sergey`"
eval "`/usr/bin/curl -L git.io/finalize_base_system_sergey`"

export WAN_IFACE="eth0"
export LAN_IFACE="eth1"

echo '==> Configuring networks'
/usr/bin/cat <<-EOF > "${TARGET_DIR}/etc/netctl/wan"
Interface=${WAN_IFACE}
Connection=ethernet
IP=dhcp
IP6=stateless
DNS=('8.8.8.8' '8.8.4.4')
EOF
/usr/bin/cat <<-EOF > "${TARGET_DIR}/etc/netctl/trusted_lan"
Interface=${LAN_IFACE}
Connection=ethernet
IP=static
Address=('192.168.10.1/24')

ForceConnect=yes
SkipNoCarrier=yes
EOF
/usr/bin/arch-chroot ${TARGET_DIR} /usr/bin/netctl enable trusted_lan
/usr/bin/arch-chroot ${TARGET_DIR} /usr/bin/pacman -S --noconfirm ifplugd 6tunnel
/usr/bin/arch-chroot ${TARGET_DIR} /usr/bin/systemctl enable netctl-ifplugd@eth0.service

echo '==> Prepopulating shell history'
echo 'curl -L git.io/install_ch_router_sergey | sh' >> "${TARGET_DIR}/root/.bash_history"
echo 'vi private.key' >> "${TARGET_DIR}/root/.bash_history"

echo '==> Install complete!'
/usr/bin/sleep 5
/usr/bin/umount ${TARGET_DIR}
/usr/bin/reboot
