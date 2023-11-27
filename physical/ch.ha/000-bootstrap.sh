#!/bin/bash

# run and execute after dropping into arch installer: $ curl -L t.ly/xama/ch_ha | sh

export DISK='/dev/nvme0n1'

export FQDN='ch.ha.xama'
export LUSER='sergey'
export KEYMAP='us'
export LANGUAGE='en_US.UTF-8'
export TIMEZONE='Europe/Zurich'

export CONFIG_SCRIPT='/usr/local/bin/arch-config.sh'
export EFI_PARTITION="${DISK}p1"
export BOOT_PARTITION="${DISK}p2"
export ROOT_PARTITION="${DISK}p3"
export ROOT_PASSPHRASE=`/usr/bin/openssl rand -base64 32`
export TARGET_DIR='/mnt'
export ENC_KEY_PATH="${TARGET_DIR}/enc.key"
export COUNTRY='CH'
export MIRRORLIST="https://www.archlinux.org/mirrorlist/?country=${COUNTRY}&protocol=http&protocol=https&ip_version=4&use_mirror_status=on"
export IFACE_PROD="eth0"
export IFACE_SERVICE="eth1"

eval "`/usr/bin/curl -L t.ly/xama/partition_drive`"
eval "`/usr/bin/curl -L t.ly/xama/prepare_base_system`"
eval "`/usr/bin/curl -L t.ly/xama/prepare_encryption`"
eval "`/usr/bin/curl -L t.ly/xama/install_base_system`"
eval "`/usr/bin/curl -L t.ly/xama/finalize_base_system`"

echo '==> Enabling production NIC'
/usr/bin/cat <<-EOF > "${IFACE_PROD}/etc/netctl/prod-lan"
Interface=${IFACE_PROD}
Connection=ethernet
IP=dhcp
EOF
echo '==> Enabling service NIC'
/usr/bin/cat <<-EOF > "${TARGET_DIR}/etc/netctl/service-lan"
Interface=${IFACE_SERVICE}
Connection=ethernet
IP=dhcp
EOF
/usr/bin/arch-chroot ${TARGET_DIR} /usr/bin/netctl enable prod-lan
/usr/bin/arch-chroot ${TARGET_DIR} /usr/bin/netctl enable service-lan

echo '==> Prepopulating shell history'
echo 'curl -L t.ly/xama/install_ch_ha | sh' >> "${TARGET_DIR}/root/.bash_history"
echo 'vi private.key' >> "${TARGET_DIR}/root/.bash_history"

echo '==> Install complete!'
/usr/bin/sleep 5
/usr/bin/umount ${TARGET_DIR}
/usr/bin/reboot
