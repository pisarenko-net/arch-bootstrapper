#!/bin/bash

# Prepare for main installation.

# run and execute from configuration scripts (not to be invoked directly): $ curl -L git.io/install_base_system_sergey | sh
# (created with: $ curl -i https://git.io -F "url=https://raw.githubusercontent.com/pisarenko-net/arch-bootstrapper/main/common/layers/200-prepare_main_install.sh" -F "code=prepare_main_install_sergey")

# install git-secret
cd /home/${LUSER}
/usr/bin/sudo -u ${LUSER} /usr/bin/git clone https://aur.archlinux.org/git-secret.git
cd git-secret
/usr/bin/sudo -u ${LUSER} /usr/bin/makepkg -si --noconfirm
cd ..
/usr/bin/sudo -u ${LUSER} /usr/bin/rm -rf git-secret
