#!/bin/bash

# Prepare for main installation.

# run and execute from specific configuration scripts: $ curl -L git.io/apfel_stage1 | sh
# (created with: $ curl -i https://git.io -F "url=https://raw.githubusercontent.com/pisarenko-net/arch-bootstrap-scripts/master/common/stage1.sh" -F "code=apfel_stage1")

# install git-secret
cd /home/${USER}
/usr/bin/sudo -u ${USER} /usr/bin/git clone https://aur.archlinux.org/git-secret.git
cd git-secret
/usr/bin/sudo -u ${USER} /usr/bin/makepkg -si --noconfirm
cd ..
/usr/bin/sudo -u ${USER} /usr/bin/rm -rf git-secret
