#!/bin/bash

# run from bootstrapped machine: $ curl -L git.io/install_ch_cddev_sergey | sh
# (created with: $ curl -i https://git.io -F "url=https://raw.githubusercontent.com/pisarenko-net/arch-bootstrapper/main/physical/ch.cddev/100-install.sh" -F "code=install_ch_cddev_sergey")

export LUSER="sergey"
export DOMAIN="pisarenko.net"
export FULL_NAME="Sergey Pisarenko"
export README_ENTRY="ch.cddev"

export AS="/usr/bin/sudo -u ${LUSER}"

if [ ! -f private.key ]; then
    echo "Download the GPG private key and save it to private.key first" exit 1
fi

echo "==> Importing GPG key for decrypting private configuration files"
cat private.key | $AS /usr/bin/gpg --import

eval "`/usr/bin/curl -L git.io/prepare_main_install_sergey`"

echo "==> Downloading configuration files and unlocking private configuration files"
$AS /usr/bin/git clone https://github.com/pisarenko-net/arch-bootstrapper.git /tmp/scripts-repo
cd /tmp/scripts-repo
$AS /usr/bin/git secret reveal
$AS /usr/bin/cp -R /tmp/scripts-repo/common/configs /tmp/configs
$AS /usr/bin/cp -R /tmp/scripts-repo/common/apps /tmp/apps
$AS /usr/bin/cp -R /tmp/scripts-repo/physical/ch.cddev/configs/* /tmp/configs/
$AS /usr/bin/cp -R /tmp/scripts-repo/common/private /tmp/private
$AS /usr/bin/cp -R /tmp/scripts-repo/physical/ch.cddev/private/* /tmp/private/
$AS /usr/bin/rm /tmp/private/*secret

eval "`/usr/bin/curl -L git.io/install_cli_sergey`"
eval "`/usr/bin/curl -L git.io/install_xorg_sergey`"

echo '==> Installing X driver and enhancements'
/usr/bin/pacman -S --noconfirm xf86-video-intel compton
$AS /usr/bin/xfconf-query -c xfwm4 -p /general/use_compositing -s false
$AS /usr/bin/cp -R /tmp/configs/compton.desktop /home/${LUSER}/.config/autostart/

echo '==> Enabling better power management'
/usr/bin/pacman -S --noconfirm tlp
/usr/bin/systemctl enable tlp

echo '==> Install CIFS tools'
/usr/bin/pacman -S --noconfirm cifs-utils

echo '==> Installing extra dev tools'
/usr/bin/pacman -S --noconfirm fuse2 libfuse boost

echo '==> Installing media tools'
/usr/bin/pacman -S --noconfirm ffmpeg audacity alsa-utils alsa-firmware cdparanoia lirc

echo '==> Installing Arduino tools'
/usr/bin/pacman -S --noconfirm arduino jdk8-openjdk arduino-avr-core

/usr/bin/mkdir /vm_shared
/usr/bin/chown ${LUSER} /vm_shared

echo '==> Cleaning up'
$AS /usr/bin/gpg --batch --delete-secret-keys 6E77A188BB74BDE4A259A52DB320A1C85AFACA96
/usr/bin/rm -rf /tmp/scripts-repo
/usr/bin/rm -rf /tmp/apps
/usr/bin/rm -rf /tmp/configs
/usr/bin/rm -rf /tmp/private

eval "`/usr/bin/curl -L git.io/report_success_sergey`"
