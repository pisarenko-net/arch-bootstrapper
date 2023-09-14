#!/bin/bash

# Install base CLI layer: tools and configs to be present on each machine.

# run and execute from bootstrapped script (not to be invoked directly): $ curl -L t.ly/xama/install_cli | sh

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
        $AS /usr/bin/cp /tmp/private/id_rsa /home/${LUSER}/.ssh
        $AS /usr/bin/cp /tmp/private/id_rsa.pub /home/${LUSER}/.ssh
        $AS /usr/bin/chmod 400 /home/${LUSER}/.ssh/id_rsa
else
        $AS /usr/bin/ssh-keygen -t rsa -f /home/${LUSER}/.ssh/id_rsa -q -P ""
fi

$AS /usr/bin/touch /home/${LUSER}/.ssh/known_hosts
echo "github.com ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIOMqqnkVzrm0SdG6UOoqKLsabgH5C9okWi0dh2l9GKJl" >> /home/${LUSER}/.ssh/known_hosts
echo "github.com ssh-rsa AAAAB3NzaC1yc2EAAAADAQABAAABgQCj7ndNxQowgcQnjshcLrqPEiiphnt+VTTvDP6mHBL9j1aNUkY4Ue1gvwnGLVlOhGeYrnZaMgRK6+PKCUXaDbC7qtbW8gIkhL7aGCsOr/C56SJMy/BCZfxd1nWzAOxSDPgVsmerOBYfNqltV9/hWCqBywINIR+5dIg6JTJ72pcEpEjcYgXkE2YEFXV1JHnsKgbLWNlhScqb2UmyRkQyytRLtL+38TGxkxCflmO+5Z8CSSNY7GidjMIZ7Q4zMjA2n1nGrlTDkzwDCsw+wqFPGQA179cnfGWOWRVruj16z6XyvxvjJwbz0wQZ75XK5tKSb7FNyeIEs4TT4jk+S4dhPeAUC5y+bDYirYgM4GC7uEnztnZyaVWQ7B381AK4Qdrwt51ZqExKbQpTUNn+EjqoTwvqNj4kqx5QUCI0ThS/YkOxJCXmPUWZbhjpCg56i+2aB6CmK2JGhn57K5mj0MNdBXA4/WnwH6XoPWJzK5Nyu2zB3nAZp+S5hpQs+p1vN1/wsjk=" >> /home/${LUSER}/.ssh/known_hosts
echo "ithub.com ecdsa-sha2-nistp256 AAAAE2VjZHNhLXNoYTItbmlzdHAyNTYAAAAIbmlzdHAyNTYAAABBBEmKSENjQEezOmxkZMy7opKgwFB9nkt5YRrYMjNuG5N87uRgg6CLrbo5wAdT/y6v0mKV0U2w0WZ2YB/++Tpockg=" >> /home/${LUSER}/.ssh/known_hosts

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
