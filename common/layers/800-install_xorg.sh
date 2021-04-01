#!/bin/bash

# Install graphical environment and basic tools to be available on each machine.

# run from bootstrapped machine: $ curl -L git.io/install_xorg_sergey | sh
# (created with: $ curl -i https://git.io -F "url=https://raw.githubusercontent.com/pisarenko-net/arch-bootstrapper/main/common/layers/800-install_xorg.sh" -F "code=install_xorg_sergey")

# install desktop environment
echo '==> Installing desktop environment'
/usr/bin/pacman -S --noconfirm xorg-server xorg-xinit lxdm xfce4

# configure desktop manager
echo '==> Enabling desktop manager'
/usr/bin/sed -i "s/# autologin=dgod/autologin=${USER}/" /etc/lxdm/lxdm.conf
/usr/bin/sed -i 's/# session=\/usr\/bin\/startlxde/session=\/usr\/bin\/startxfce4/' /etc/lxdm/lxdm.conf
/usr/bin/systemctl enable lxdm.service

# install fonts
echo '==> Installing fonts'
/usr/bin/pacman -S --noconfirm noto-fonts ttf-roboto ttf-dejavu adobe-source-code-pro-fonts ttf-ubuntu-font-family

# install tools
echo '==> Installing useful tools'
/usr/bin/pacman -S --noconfirm terminator meld parcellite thunar-archive-plugin gvfs tk
$AS /bin/dconf load /org/gnome/meld/ < /tmp/configs/meld

# install pinta
echo '==> Installing pinta (AUR)'
cd /home/${USER}
$AS /usr/bin/git clone https://aur.archlinux.org/pinta.git
cd pinta
$AS /usr/bin/makepkg -si --noconfirm
cd ..
$AS /usr/bin/rm -rf pinta

# install albert
echo '==> Installing albert (AUR)'
cd /home/${USER}
$AS /usr/bin/git clone https://aur.archlinux.org/albert-lite.git
cd albert-lite
$AS /usr/bin/makepkg -si --noconfirm
cd ..
$AS /usr/bin/rm -rf albert-lite

# install sublime
echo '==> Installing sublime (AUR)'
$AS /usr/bin/git clone https://aur.archlinux.org/sublime-text-dev.git
cd sublime-text-dev
$AS /usr/bin/makepkg -si --noconfirm
cd ..
$AS /usr/bin/rm -rf sublime-text-dev
/usr/bin/echo 'alias subl="/bin/subl3"' >> /home/${USER}/.zshrc
/usr/bin/echo 'alias mc="EDITOR=/bin/subl3 /bin/mc"' >> /home/${USER}/.zshrc
$AS /usr/bin/cp -r /tmp/configs/sublime-text-3 .config/
$AS /usr/bin/mkdir -p .config/sublime-text-3/Local/
$AS /usr/bin/cp /tmp/private/License.sublime_license .config/sublime-text-3/Local/

# install web browser
echo '==> Installing brave-bin (AUR)'
cd /home/${USER}
$AS /usr/bin/git clone https://aur.archlinux.org/brave-bin.git
cd brave-bin
$AS /usr/bin/makepkg -si --noconfirm
cd ..
$AS /usr/bin/rm -rf brave-bin

# customize XFCE
echo '==> Customizing XFCE'
$AS /usr/bin/cp -r /tmp/configs/xfce4 .config/
$AS /usr/bin/cp -r /tmp/configs/terminator .config/
$AS /usr/bin/cp -r /tmp/configs/albert .config/
$AS /usr/bin/cp -r /tmp/configs/autostart .config/
/usr/bin/chown -R sergey:users .config
$AS /usr/bin/mkdir /home/sergey/Pictures
$AS /usr/bin/cp /tmp/wallpapers/* /home/sergey/Pictures
