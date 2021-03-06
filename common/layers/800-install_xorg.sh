#!/bin/bash

# Install graphical environment and basic tools to be available on each machine.

# run and execute from bootstrapped script (not to be invoked directly): $ curl -L git.io/install_xorg_sergey | sh
# (created with: $ curl -i https://git.io -F "url=https://raw.githubusercontent.com/pisarenko-net/arch-bootstrapper/main/common/layers/800-install_xorg.sh" -F "code=install_xorg_sergey")

# install desktop environment
echo '==> Installing desktop environment'
/usr/bin/pacman -S --noconfirm xorg-server xorg-xinit lxdm xfce4

# configure desktop manager
echo '==> Enabling desktop manager'
/usr/bin/sed -i "s/# autologin=dgod/autologin=${LUSER}/" /etc/lxdm/lxdm.conf
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
cd /home/${LUSER}
$AS /usr/bin/git clone https://aur.archlinux.org/pinta.git
cd pinta
$AS /usr/bin/makepkg -si --noconfirm
cd ..
$AS /usr/bin/rm -rf pinta

# install sublime
echo '==> Installing sublime (AUR)'
$AS /usr/bin/git clone https://aur.archlinux.org/sublime-text-dev.git
cd sublime-text-dev
$AS /usr/bin/makepkg -si --noconfirm
cd ..
$AS /usr/bin/rm -rf sublime-text-dev
/usr/bin/echo 'alias subl="/bin/subl3"' >> /home/${LUSER}/.zshrc
/usr/bin/echo 'alias mc="EDITOR=/bin/subl3 /bin/mc"' >> /home/${LUSER}/.zshrc
$AS /usr/bin/cp -r /tmp/configs/sublime-text-3 .config/
$AS /usr/bin/mkdir -p .config/sublime-text-3/Local/
if [ -f /tmp/private/License.sublime_license ]; then
    $AS /usr/bin/cp /tmp/private/License.sublime_license .config/sublime-text-3/Local/
fi

# install web browser
echo '==> Installing brave-bin (AUR)'
cd /home/${LUSER}
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
/usr/bin/chown -R ${LUSER}:users .config
$AS /usr/bin/mkdir /home/${LUSER}/Pictures

# install wallpapers
if [ -d /tmp/wallpapers ]; then
    $AS /usr/bin/cp /tmp/wallpapers/* /home/${LUSER}/Pictures/
    for f in /home/${LUSER}/Pictures/*.safe;
    do
        filename=${f::-5}
        destination=`basename ${filename} | base64 -d`
        base64 -d ${f} > /home/${LUSER}/Pictures/${destination}
    done;
    /usr/bin/rm -f /home/${LUSER}/Pictures/*.safe
fi
