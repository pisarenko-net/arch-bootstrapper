#!/bin/bash

# run and execute after dropping into arch installer: $ curl -L v-u.cc/ch_ha | sh

if [ -e '/dev/nvme0n1' ]; then
	export DISK='/dev/nvme0n1'
	export EFI_PARTITION="${DISK}p1"
	export BOOT_PARTITION="${DISK}p2"
	export ROOT_PARTITION="${DISK}p3"
else
	export DISK='/dev/sda'
	export EFI_PARTITION="${DISK}1"
	export BOOT_PARTITION="${DISK}2"
	export ROOT_PARTITION="${DISK}3"
fi

export FQDN='ch.ha.xama'
export LUSER='sergey'
export KEYMAP='us'
export LANGUAGE='en_US.UTF-8'
export TIMEZONE='Europe/Zurich'

export CONFIG_SCRIPT='/usr/local/bin/arch-config.sh'
export ROOT_PASSPHRASE=`/usr/bin/openssl rand -base64 32`
export TARGET_DIR='/mnt'
export ENC_KEY_PATH="${TARGET_DIR}/enc.key"
export COUNTRY='CH'
export MIRRORLIST="https://www.archlinux.org/mirrorlist/?country=${COUNTRY}&protocol=http&protocol=https&ip_version=4&use_mirror_status=on"
export IFACE_SERVICE="service"
export IFACE_PROD="main"

eval "`/usr/bin/curl -L v-u.cc/partition_drive`"
eval "`/usr/bin/curl -L v-u.cc/prepare_base_system`"
eval "`/usr/bin/curl -L v-u.cc/prepare_encryption`"
eval "`/usr/bin/curl -L v-u.cc/install_base_system`"
eval "`/usr/bin/curl -L v-u.cc/finalize_base_system`"

echo '==> Setting persistent network iface names'
/usr/bin/cat <<-EOF > "${TARGET_DIR}/etc/udev/rules.d/10-network-iface-names.rules"
SUBSYSTEM=="net", ACTION=="add", ATTR{address}=="34:29:8f:60:06:47", NAME="main"
SUBSYSTEM=="net", ACTION=="add", ATTR{address}=="98:fc:84:13:0c:42", NAME="main"
SUBSYSTEM=="net", ACTION=="add", ATTR{address}=="94:c6:91:a7:a1:34", NAME="service"
SUBSYSTEM=="net", ACTION=="add", ATTR{address}=="00:e0:4c:2f:5c:ab", NAME="service"
EOF

echo '==> Enabling production NIC'
/usr/bin/cat <<-EOF > "${TARGET_DIR}/etc/netctl/prod-lan"
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
echo 'curl -L v-u.cc/install_ch_ha | sh' >> "${TARGET_DIR}/root/.bash_history"
echo 'vi private.key' >> "${TARGET_DIR}/root/.bash_history"

echo '==> Install complete!'
/usr/bin/sleep 5
/usr/bin/umount ${TARGET_DIR}
/usr/bin/reboot
