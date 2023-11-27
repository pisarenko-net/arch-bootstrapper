#!/bin/bash

# run from bootstrapped machine: $ curl -L t.ly/xama/install_ch_ha | sh

export LUSER="sergey"
export DOMAIN="pisarenko.net"
export FULL_NAME="Sergey Pisarenko"
export README_ENTRY="ch.ha"
export HA_OS_URL="https://github.com/home-assistant/operating-system/releases/download/11.3/haos_ova-11.3.vdi.zip"
export HA_NIC_MAC="722BAC12F8D6"
export IFACE="eth0"
export ARCH_USB_THUMB="/dev/sda"  # latest arch image is going to be written here monthly
export ARCH_MIRROR="https://pkg.adfinis.com"  # used to fetch latest arch image

export AS="/usr/bin/sudo -u ${LUSER}"

if [ ! -f private.key ]; then
    echo "Download the GPG private key and save it to private.key first" exit 1
fi

echo "==> Importing GPG key for decrypting private configuration files"
cat private.key | $AS /usr/bin/gpg --import

eval "`/usr/bin/curl -L t.ly/xama/prepare_main_install`"

echo "==> Downloading configuration files and unlocking private configuration files"
$AS /usr/bin/git clone https://github.com/pisarenko-net/arch-bootstrapper.git /tmp/scripts-repo
cd /tmp/scripts-repo
$AS /usr/bin/git secret reveal
$AS /usr/bin/cp -R /tmp/scripts-repo/common/configs /tmp/configs
$AS /usr/bin/cp -R /tmp/scripts-repo/common/apps /tmp/apps
$AS /usr/bin/cp -R /tmp/scripts-repo/physical/ch.ha/configs/* /tmp/configs/
$AS /usr/bin/cp -R /tmp/scripts-repo/common/private /tmp/private
$AS /usr/bin/cp -R /tmp/scripts-repo/physical/ch.ha/private/* /tmp/private/
$AS /usr/bin/rm /tmp/private/*secret

echo '==> Switching network from service NIC to production NIC'
/usr/bin/cat <<-EOF > "/etc/netctl/ethernet-dhcp"
Interface=${IFACE}
Connection=ethernet
IP=dhcp
EOF

eval "`/usr/bin/curl -L t.ly/xama/install_cli`"

echo '==> Installing cron and auto Arch download'
/usr/bin/cp /tmp/apps/download_latest_arch /usr/local/bin/
/usr/bin/chmod +x /usr/local/bin/download_latest_arch
/usr/bin/pacman -S --noconfirm cronie
/usr/bin/systemctl enable cronie
echo "38 16 5 * * /usr/local/bin/download_latest_arch ${ARCH_USB_THUMB} ${ARCH_MIRROR}" | /usr/bin/crontab -

echo '==> Installing VirtualBox, vagrant, packer and scripts'
/usr/bin/pacman -S --noconfirm virtualbox
cd /home/${LUSER}
/usr/bin/usermod -a -G virtualbox ${LUSER}

echo '==> Installing VirtualBox extensions'
cd /home/${LUSER}
$AS /usr/bin/git clone https://aur.archlinux.org/virtualbox-ext-oracle.git
cd virtualbox-ext-oracle
$AS /usr/bin/makepkg -si --noconfirm
cd ..
$AS /usr/bin/rm -rf virtualbox-ext-oracle
modprobe vboxdrv
modprobe vboxnetadp
modprobe vboxnetflt

echo '==> Downloading HomeAssistant image'
/usr/bin/pacman -S --noconfirm unzip
cd /home/${LUSER}
$AS /usr/bin/wget ${HA_OS_URL} -O haos.zip
$AS /usr/bin/unzip haos.zip

echo '==> Creating HomeAssistant Virtualbox VM'
$AS /usr/bin/VBoxManage createvm --name HA-1 --ostype Linux_64 --register
$AS /usr/bin/VBoxManage storagectl HA-1 --name "SATA Controller" --add sata --bootable on
$AS /usr/bin/VBoxManage storageattach HA-1 --storagectl "SATA Controller" --port 0 --device 0 --type hdd --medium *vdi
$AS /usr/bin/VBoxManage modifyvm HA-1 --boot1 disk --boot2 none --boot3 none --boot4 none
$AS /usr/bin/VBoxManage modifyvm HA-1 --firmware efi
$AS /usr/bin/VBoxManage modifyvm HA-1 --memory 12288 --cpus 8
$AS /usr/bin/VBoxManage modifyvm HA-1 --usbehci on
$AS /usr/bin/VBoxManage modifyvm HA-1 --usbxhci on
$AS /usr/bin/VBoxManage usbfilter add 0 --target HA-1 --name zigbee --vendorid 10c4
$AS /usr/bin/VBoxManage modifyvm HA-1 --macaddress1 ${HA_NIC_MAC}
$AS /usr/bin/VBoxManage modifyvm HA-1 --nic1 bridged --bridgeadapter1 eth0
$AS /usr/bin/VBoxManage modifyvm HA-1 --vrde on --vrdeproperty "VNCPassword=test"

echo '==> Enabling HA VM'
/usr/bin/cat <<-EOF >> "/etc/systemd/system/vboxvmservice@.service"
[Unit]
Description=VBox Virtual Machine %i Service
Requires=systemd-modules-load.service
After=systemd-modules-load.service

[Service]
User=${LUSER}
Group=vboxusers
ExecStart=/usr/bin/VBoxManage startvm %i --type headless
ExecStop=/usr/bin/VBoxManage controlvm %i acpipowerbutton
RemainAfterExit=yes

[Install]
WantedBy=multi-user.target
EOF
/usr/bin/systemctl enable vboxvmservice@HA-1
/usr/bin/systemctl start vboxvmservice@HA-1

echo '==> Cleaning up'
$AS /usr/bin/gpg --batch --yes --delete-secret-keys 6E77A188BB74BDE4A259A52DB320A1C85AFACA96
/usr/bin/rm -rf /tmp/scripts-repo
/usr/bin/rm -rf /tmp/apps
/usr/bin/rm -rf /tmp/configs
/usr/bin/rm -rf /tmp/private

eval "`/usr/bin/curl -L t.ly/xama/report`"

echo '==> Install complete!'
/usr/bin/sleep 10
/usr/bin/reboot
