#!/bin/bash

# Prepare for main installation.

# run and execute from configuration scripts (not to be invoked directly): $ curl -L v-u.cc/prepare_main_install | sh

# install git-secret
cd /home/${LUSER}
/usr/bin/sudo -u ${LUSER} /usr/bin/git clone https://aur.archlinux.org/git-secret.git
cd git-secret
/usr/bin/sudo -u ${LUSER} /usr/bin/makepkg -si --noconfirm
cd ..
/usr/bin/sudo -u ${LUSER} /usr/bin/rm -rf git-secret
