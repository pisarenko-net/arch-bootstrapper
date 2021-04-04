#!/bin/bash

# Install base CLI layer: tools and configs to be present on each machine.

# run and execute from bootstrapped script (not to be invoked directly): $ curl -L git.io/install_cli_sergey | sh
# (created with: $ curl -i https://git.io -F "url=https://raw.githubusercontent.com/pisarenko-net/arch-bootstrapper/main/common/layers/500-install_cli.sh" -F "code=install_cli_sergey")

echo "==> Enable time sync"
/usr/bin/timedatectl set-ntp true

echo "==> Refreshing pacman"
/usr/bin/pacman -Syu --noconfirm

echo "==> Installing tools"
/usr/bin/pacman -S --noconfirm htop tcpdump parted netcat hwinfo zsh mc zip unrar linux-headers lsof dnsutils

echo "==> Setting default text editor"
/usr/bin/ln -sf /usr/bin/nvim /usr/bin/vi
/usr/bin/echo 'EDITOR=nvim' >> /etc/environment
/usr/bin/echo 'VISUAL=nvim' >> /etc/environment

echo "==> Enable passwordless sudo for wheel group"
/usr/bin/sed -i 's/# %wheel ALL=(ALL) NOPASSWD: ALL/%wheel ALL=(ALL) NOPASSWD: ALL/' /etc/sudoers

echo "==> Update user ${LUSER}"
/usr/bin/groupadd -r autologin
/usr/bin/usermod -G wheel,storage,power,autologin -s /bin/zsh ${LUSER}
cd /home/${LUSER}

echo "==> Set git configuration"
$AS /usr/bin/git config --global user.email "${LUSER}@${DOMAIN}"
$AS /usr/bin/git config --global user.name "${FULL_NAME}"

echo "==> Configure/customize shell"
$AS /usr/bin/rm .bash*
$AS /usr/bin/mkdir /home/${LUSER}/.cache
$AS /usr/bin/git clone https://aur.archlinux.org/oh-my-zsh-git.git
cd oh-my-zsh-git
$AS /usr/bin/makepkg -si --noconfirm
$AS /usr/bin/cp /usr/share/oh-my-zsh/zshrc /home/${LUSER}/.zshrc
cd ..
/usr/bin/rm -rf oh-my-zsh-git
/usr/bin/touch /home/${LUSER}/.zsh{rc,env}
/usr/bin/chown ${LUSER}:users /home/${LUSER}/.zsh{rc,env}
/usr/bin/echo 'unsetopt share_history' >> /home/${LUSER}/.zshenv
/usr/bin/echo 'export HISTFILE="$HOME/.zsh_history"' >> /home/${LUSER}/.zshenv
/usr/bin/echo 'export HISTSIZE=10000000' >> /home/${LUSER}/.zshenv
/usr/bin/echo 'export SAVEHIST=10000000' >> /home/${LUSER}/.zshenv

echo '==> Configuring SSH keys'
if [ -f /tmp/private/id_rsa ]; then
        $AS /usr/bin/mkdir /home/${LUSER}/.ssh
        $AS /usr/bin/cp /tmp/private/id_rsa /home/${LUSER}/.ssh
        $AS /usr/bin/cp /tmp/private/id_rsa.pub /home/${LUSER}/.ssh
        $AS /usr/bin/chmod 400 /home/${LUSER}/.ssh/id_rsa
else
        $AS /usr/bin/ssh-keygen -t rsa -f /home/${LUSER}/.ssh/id_rsa -q -P ""
fi

$AS /usr/bin/touch /home/${LUSER}/.ssh/known_hosts
echo "github.com,192.30.253.113 ssh-rsa AAAAB3NzaC1yc2EAAAABIwAAAQEAq2A7hRGmdnm9tUDbO9IDSwBK6TbQa+PXYPCPy6rbTrTtw7PHkccKrpp0yVhp5HdEIcKr6pLlVDBfOLX9QUsyCOV0wzfjIJNlGEYsdlLJizHhbn2mUjvSAHQqZETYP81eFzLQNnPHt4EVVUh7VfDESU84KezmD5QlWpXLmvU31/yMf+Se8xhHTvKSCZIFImWwoG6mbUoWf9nzpIoaSjB+weqqUUmpaaasXVal72J+UX2B+2RPW3RcT0eOzQgqlJL3RKrTJvdsjE3JEAvGq3lGHSZXy28G3skua2SmVi/w4yCE6gbODqnTWlg7+wC604ydGXA8VJiS5ap43JXiUFFAaQ==" >> /home/${LUSER}/.ssh/known_hosts

echo '==> Setting up custom settings'
cd /home/${LUSER}
$AS /usr/bin/mkdir .config
$AS /usr/bin/cp -r /tmp/configs/mc .config/
$AS /usr/bin/mkdir .config/nvim
$AS /usr/bin/cp -r /tmp/configs/nvim .config/nvim/init.vim

echo '==> Setting up MOTD'
/usr/bin/cp /tmp/configs/motd /etc/motd

echo '==> Resetting default password'
RANDOM_PASSWORD=`/usr/bin/openssl rand -base64 32`
echo "${LUSER}:${RANDOM_PASSWORD}" | /usr/bin/chpasswd
