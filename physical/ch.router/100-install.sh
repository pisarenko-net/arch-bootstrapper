#!/bin/bash

# run from bootstrapped machine: $ curl -L git.io/install_ch_router_sergey | sh
# (created with: $ curl -i https://git.io -F "url=https://raw.githubusercontent.com/pisarenko-net/arch-bootstrapper/main/physical/ch.router/100-install.sh" -F "code=install_ch_router_sergey")

export LUSER="sergey"
export DOMAIN="pisarenko.net"
export FULL_NAME="Sergey Pisarenko"

export AS="/usr/bin/sudo -u ${LUSER}"

export LAN_IFACE="eth1"
export INCOMING_DRIVE="/dev/sdb"

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
$AS /usr/bin/cp -R /tmp/scripts-repo/physical/ch.router/configs/* /tmp/configs/
$AS /usr/bin/cp -R /tmp/scripts-repo/common/private /tmp/private
$AS /usr/bin/cp -R /tmp/scripts-repo/physical/ch.router/private/* /tmp/private/
$AS /usr/bin/rm /tmp/private/*secret

eval "`/usr/bin/curl -L git.io/install_cli_sergey`"

echo '==> Enabling better power management'
/usr/bin/pacman -S --noconfirm tlp
/usr/bin/systemctl enable tlp

echo '==> Setting OpenSSH to listen only on the trusted network'
/usr/bin/sed -i 's/#ListenAddress 0.0.0.0/ListenAddress 192.168.10.1/' /etc/ssh/sshd_config

echo '==> Setting up untrusted/IoT VLAN'
/usr/bin/cat <<-EOF > "${TARGET_DIR}/etc/netctl/untrusted_vlan"
Interface=${LAN_IFACE}.30
Connection=vlan
BindsToInterfaces=${LAN_IFACE}
VLANID=30
IP=static
Address="192.168.30.1/24"
EOF
/usr/bin/netctl enable untrusted_vlan
/usr/bin/netctl start untrusted_vlan

echo '==> Setting up semi-trusted VLAN'
/usr/bin/cat <<-EOF > "${TARGET_DIR}/etc/netctl/semi_trusted_vlan"
Interface=${LAN_IFACE}.20
Connection=vlan
BindsToInterfaces=${LAN_IFACE}
VLANID=20
IP=static
Address="192.168.20.1/24"
EOF
/usr/bin/netctl enable semi_trusted_vlan
/usr/bin/netctl start semi_trusted_vlan

echo '==> Setting up guest VLAN'
/usr/bin/cat <<-EOF > "${TARGET_DIR}/etc/netctl/guest_vlan"
Interface=${LAN_IFACE}.40
Connection=vlan
BindsToInterfaces=${LAN_IFACE}
VLANID=40
IP=static
Address="192.168.40.1/24"
EOF
/usr/bin/netctl enable guest_vlan
/usr/bin/netctl start guest_vlan

echo '==> Setup dnsmasq (DHCP + DNS)'
/usr/bin/pacman -S --noconfirm dnsmasq
/usr/bin/cp /tmp/private/dnsmasq.conf /etc/
/usr/bin/cp /tmp/private/hosts /etc/
/usr/bin/systemctl enable dnsmasq
/usr/bin/systemctl start dnsmasq
/usr/bin/sed -i "s/DNS=.*/DNS=\('127.0.0.1'\)/" /etc/netctl/wan

echo '==> Setting up iptables'
/usr/bin/cp /tmp/private/sysctl_ip_forward /etc/sysctl.d/30-ip_forward.conf
/usr/bin/sysctl net.ipv4.ip_forward=1
/usr/bin/pacman -S --noconfirm iptables
/usr/bin/systemctl enable iptables
/usr/bin/systemctl start iptables
/usr/bin/iptables-restore < /tmp/private/iptables-rules
/usr/bin/iptables-save > /etc/iptables/iptables.rules

echo '==> Setting up multicast relay'
/usr/bin/cp /tmp/configs/multicast-relay.py /usr/local/bin/
/usr/bin/pacman -S --noconfirm python python-netifaces
/usr/bin/cat <<-EOF > "${TARGET_DIR}/etc/systemd/system/multicast-relay.service"
[Unit]
Description=Multicast relay service
After=netctl@semi_trusted_vlan.service netctl@untrusted_vlan.service

[Service]
Type=forking
User=root
WorkingDirectory=/tmp
ExecStart=/usr/bin/python /usr/local/bin/multicast-relay.py --interfaces ${LAN_IFACE}.20 ${LAN_IFACE}.30
Restart=on-failure

[Install]
WantedBy=multi-user.target
EOF
/usr/bin/systemctl enable multicast-relay
/usr/bin/systemctl start multicast-relay

echo '==> Installing dyndns'
/usr/bin/pacman -S --noconfirm ddclient
/usr/bin/cp /tmp/private/ddclient.conf /etc/ddclient/
/usr/bin/systemctl enable ddclient
/usr/bin/systemctl start ddclient

echo "==> Configuring rslsync drive (incoming/music syncs)"
/usr/bin/pacman -S --noconfirm gdisk
/usr/bin/sgdisk -og ${INCOMING_DRIVE}
ENDSECTOR=`/usr/bin/sgdisk -E ${INCOMING_DRIVE}`
/usr/bin/sgdisk -n 1:2048:${ENDSECTOR} -c 1:"Incoming drive" -t 1:8300 ${INCOMING_DRIVE}
/usr/bin/mkfs.btrfs -f ${INCOMING_DRIVE}1
UUID=`/usr/bin/blkid -s UUID -o value ${INCOMING_DRIVE}1`
echo "# ${INCOMING_DRIVE}1" >> /etc/fstab
echo "UUID=${UUID}       /mnt/mirror   btrfs           rw,relatime,ssd,space_cache,subvolid=5,subvol=/ 0 2" >> /etc/fstab
/usr/bin/pacman -R --noconfirm gptfdisk
/usr/bin/mkdir /mnt/mirror
/usr/bin/mount /mnt/mirror
cd /home/${LUSER}
$AS /usr/bin/git clone https://aur.archlinux.org/rslsync.git
cd rslsync
$AS /usr/bin/makepkg -si --noconfirm
cd ..
$AS /usr/bin/rm -rf rslsync
/usr/bin/cp /tmp/private/rslsync.conf /etc/
/usr/bin/chown rslsync:rslsync /mnt/mirror
/usr/bin/systemctl enable rslsync
/usr/bin/systemctl start rslsync

echo "==> Configuring Samba for incoming drive access"
/usr/bin/pacman -S --noconfirm samba
/usr/bin/cp /tmp/private/smb.conf /etc/samba/
/usr/bin/systemctl enable smb
/usr/bin/systemctl enable nmb
/usr/bin/systemctl start smb
/usr/bin/systemctl start nmb

echo '==> Updating Last install date in the repo'
cd /tmp/scripts-repo
TODAY=`date +%Y-%m-%d`
$AS sed -i "s/ch.router Last Installed.*/ch.router Last Installed **${TODAY}**/" README.md
$AS /usr/bin/git add .
$AS /usr/bin/git commit -m "succesful ch.router install"
$AS /usr/bin/git push

eecho '==> Cleaning up'
$AS /usr/bin/gpg --batch --delete-secret-keys 6E77A188BB74BDE4A259A52DB320A1C85AFACA96
/usr/bin/rm -rf /tmp/scripts-repo
/usr/bin/rm -rf /tmp/configs
/usr/bin/rm -rf /tmp/private
