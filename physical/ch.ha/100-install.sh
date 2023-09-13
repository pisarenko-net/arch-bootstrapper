#!/bin/bash

# run from bootstrapped machine: $ curl -L t.ly/xama/install_ch_ha | sh

export LUSER="sergey"
export DOMAIN="pisarenko.net"
export FULL_NAME="Sergey Pisarenko"
export README_ENTRY="ch.ha"

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

echo '==> Cleaning up'
$AS /usr/bin/gpg --batch --delete-secret-keys 6E77A188BB74BDE4A259A52DB320A1C85AFACA96
/usr/bin/rm -rf /tmp/scripts-repo
/usr/bin/rm -rf /tmp/apps
/usr/bin/rm -rf /tmp/configs
/usr/bin/rm -rf /tmp/private
/usr/bin/rm -rf /tmp/wallpapers

eval "`/usr/bin/curl -L t.ly/xama/report`"
