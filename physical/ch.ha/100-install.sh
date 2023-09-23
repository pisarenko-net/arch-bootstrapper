#!/bin/bash

# run from bootstrapped machine: $ curl -L t.ly/xama/install_ch_ha | sh

export LUSER="sergey"
export DOMAIN="pisarenko.net"
export FULL_NAME="Sergey Pisarenko"
export README_ENTRY="ch.ha"
export HA_OS_URL="https://github.com/home-assistant/operating-system/releases/download/10.5/haos_ova-10.5.vdi.zip"
export HA_NIC_MAC="72:2B:AC:12:F8:D6"

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

eval "`/usr/bin/curl -L t.ly/xama/install_cli`"

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
#$AS /usr/bin/VBoxManage modifyvm HA-1 --vrde on --vrdeproperty "VNCPassword=test"

echo '==> Enabling HA VM'


echo '==> Cleaning up'
$AS /usr/bin/gpg --batch --delete-secret-keys 6E77A188BB74BDE4A259A52DB320A1C85AFACA96
/usr/bin/rm -rf /tmp/scripts-repo
/usr/bin/rm -rf /tmp/apps
/usr/bin/rm -rf /tmp/configs
/usr/bin/rm -rf /tmp/private
/usr/bin/rm -rf /tmp/wallpapers

eval "`/usr/bin/curl -L t.ly/xama/report`"
