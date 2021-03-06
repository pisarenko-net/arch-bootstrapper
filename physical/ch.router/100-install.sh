#!/bin/bash

# run from bootstrapped machine: $ curl -L git.io/install_ch_router_sergey | sh
# (created with: $ curl -i https://git.io -F "url=https://raw.githubusercontent.com/pisarenko-net/arch-bootstrapper/main/physical/ch.router/100-install.sh" -F "code=install_ch_router_sergey")

export LUSER="sergey"
export DOMAIN="pisarenko.net"
export FULL_NAME="Sergey Pisarenko"
export README_ENTRY="ch.router"

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
$AS /usr/bin/cp -R /tmp/scripts-repo/common/apps /tmp/apps
$AS /usr/bin/cp -R /tmp/scripts-repo/common/configs /tmp/configs
$AS /usr/bin/cp -R /tmp/scripts-repo/physical/ch.router/configs/* /tmp/configs/
$AS /usr/bin/cp -R /tmp/scripts-repo/common/private /tmp/private
$AS /usr/bin/cp -R /tmp/scripts-repo/physical/ch.router/private/* /tmp/private/
$AS /usr/bin/rm /tmp/private/*secret

eval "`/usr/bin/curl -L git.io/install_cli_sergey`"

export LAN_IFACE="eth1"
export ARCH_USB_THUMB="/dev/sdc"  # latest arch image is going to be written here monthly
export ARCH_MIRROR="https://pkg.adfinis.com"  # used to fetch latest arch image

echo '==> Enabling better power management'
/usr/bin/pacman -S --noconfirm tlp
/usr/bin/systemctl enable tlp

echo '==> Setting OpenSSH to listen only on the trusted network'
/usr/bin/sed -i 's/#ListenAddress 0.0.0.0/ListenAddress 192.168.10.1/' /etc/ssh/sshd_config

echo '==> Setting up Network 1 VLAN (KOCMOC)'
/usr/bin/cat <<-EOF > "${TARGET_DIR}/etc/netctl/network_1_vlan"
Interface=${LAN_IFACE}.100
Connection=vlan
BindsToInterfaces=${LAN_IFACE}
VLANID=100
IP=static
Address="192.168.100.1/24"
EOF
/usr/bin/netctl enable network_1_vlan
/usr/bin/netctl start network_1_vlan

echo '==> Setting up Network 2 VLAN (CEKCPAKETA)'
/usr/bin/cat <<-EOF > "${TARGET_DIR}/etc/netctl/network_2_vlan"
Interface=${LAN_IFACE}.200
Connection=vlan
BindsToInterfaces=${LAN_IFACE}
VLANID=200
IP=static
Address="192.168.200.1/24"
EOF
/usr/bin/netctl enable network_2_vlan
/usr/bin/netctl start network_2_vlan

echo '==> Setting up Shared VLAN (HAMBCEM)'
/usr/bin/cat <<-EOF > "${TARGET_DIR}/etc/netctl/commonwealth_vlan"
Interface=${LAN_IFACE}.150
Connection=vlan
BindsToInterfaces=${LAN_IFACE}
VLANID=150
IP=static
Address="192.168.150.1/24"
EOF
/usr/bin/netctl enable commonwealth_vlan
/usr/bin/netctl start commonwealth_vlan

echo '==> Setting up Guest VLAN'
/usr/bin/cat <<-EOF > "${TARGET_DIR}/etc/netctl/guest_vlan"
Interface=${LAN_IFACE}.99
Connection=vlan
BindsToInterfaces=${LAN_IFACE}
VLANID=99
IP=static
Address="192.168.99.1/24"
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

echo '==> Installing dyndns'
/usr/bin/pacman -S --noconfirm ddclient
/usr/bin/cp /tmp/private/ddclient.conf /etc/ddclient/
/usr/bin/systemctl enable ddclient
/usr/bin/systemctl start ddclient

echo '==> Installing cron and auto Arch download'
/usr/bin/cp /tmp/apps/download_latest_arch /usr/local/bin/
/usr/bin/chmod +x /usr/local/bin/download_latest_arch
/usr/bin/pacman -S --noconfirm cronie
/usr/bin/systemctl enable cronie
echo "38 16 5 * * /usr/local/bin/download_latest_arch ${ARCH_USB_THUMB} ${ARCH_MIRROR}" | /usr/bin/crontab -

echo '==> Prepopulating shell history'
echo 'cat /var/lib/misc/dnsmasq.leases' >> /root/.bash_history
echo 'vi /etc/dnsmasq.conf' >> /root/.bash_history
echo 'vi /etc/hosts' >> /root/.bash_history
echo 'systemctl restart dnsmasq' >> /root/.bash_history

echo '==> Cleaning up'
$AS /usr/bin/gpg --batch --delete-secret-keys 6E77A188BB74BDE4A259A52DB320A1C85AFACA96
/usr/bin/rm -rf /tmp/scripts-repo
/usr/bin/rm -rf /tmp/configs
/usr/bin/rm -rf /tmp/private

eval "`/usr/bin/curl -L git.io/report_success_sergey`"
