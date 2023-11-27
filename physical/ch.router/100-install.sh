#!/bin/bash

# run from bootstrapped machine: $ curl -L t.ly/xama/install_ch_router | sh

export LUSER="sergey"
export DOMAIN="pisarenko.net"
export FULL_NAME="Sergey Pisarenko"
export README_ENTRY="ch.router"
export WAN_IFACE="eth0"
export LAN_IFACE="eth1"
export ARCH_USB_THUMB="/dev/sdb"  # latest arch image is going to be written here monthly
export ARCH_MIRROR="https://pkg.adfinis.com"  # used to fetch latest arch image

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
$AS /usr/bin/cp -R /tmp/scripts-repo/common/apps /tmp/apps
$AS /usr/bin/cp -R /tmp/scripts-repo/common/configs /tmp/configs
$AS /usr/bin/cp -R /tmp/scripts-repo/physical/ch.router/configs/* /tmp/configs/
$AS /usr/bin/cp -R /tmp/scripts-repo/common/private /tmp/private
$AS /usr/bin/cp -R /tmp/scripts-repo/physical/ch.router/private/* /tmp/private/
$AS /usr/bin/rm /tmp/private/*secret

eval "`/usr/bin/curl -L t.ly/xama/install_cli`"

echo '==> Enabling better power management'
/usr/bin/pacman -S --noconfirm tlp
/usr/bin/systemctl enable tlp

echo '==> Installing cron and auto Arch download'
/usr/bin/cp /tmp/apps/download_latest_arch /usr/local/bin/
/usr/bin/chmod +x /usr/local/bin/download_latest_arch
/usr/bin/pacman -S --noconfirm cronie
/usr/bin/systemctl enable cronie
echo "38 16 5 * * /usr/local/bin/download_latest_arch ${ARCH_USB_THUMB} ${ARCH_MIRROR}" | /usr/bin/crontab -

echo '==> Setting OpenSSH to listen only on the trusted network'
/usr/bin/sed -i 's/#ListenAddress 0.0.0.0/ListenAddress 192.168.10.1/' /etc/ssh/sshd_config

echo '==> Setup dnsmasq (DHCP + DNS)'
/usr/bin/pacman -S --noconfirm dnsmasq
/usr/bin/cp /tmp/private/dnsmasq.conf /etc/
/usr/bin/cp /tmp/private/hosts /etc/
/usr/bin/systemctl enable dnsmasq

echo '==> Configuring networks'
echo 'resolv_conf_local_only=NO' >> /etc/resolvconf.conf
/usr/bin/pacman -S --noconfirm ifplugd socat
/usr/bin/cat <<-EOF > "/etc/netctl/wan"
Interface=${WAN_IFACE}
Connection=ethernet
IP=dhcp
IP6=stateless
DNS=('127.0.0.1' '8.8.8.8' '8.8.4.4')
EOF

echo '==> Setting up Network 1 VLAN (KOCMOC)'
/usr/bin/cat <<-EOF > "/etc/netctl/network_1_vlan"
Interface=${LAN_IFACE}.100
Connection=vlan
BindsToInterfaces=${LAN_IFACE}
VLANID=100
IP=static
Address="192.168.100.1/24"
ForceConnect=yes
SkipNoCarrier=yes
EOF

echo '==> Setting up Network 2 VLAN (CEKCPAKETA)'
/usr/bin/cat <<-EOF > "/etc/netctl/network_2_vlan"
Interface=${LAN_IFACE}.200
Connection=vlan
BindsToInterfaces=${LAN_IFACE}
VLANID=200
IP=static
Address="192.168.200.1/24"
ForceConnect=yes
SkipNoCarrier=yes
EOF

echo '==> Setting up Shared VLAN (HAMBCEM)'
/usr/bin/cat <<-EOF > "/etc/netctl/commonwealth_vlan"
Interface=${LAN_IFACE}.150
Connection=vlan
BindsToInterfaces=${LAN_IFACE}
VLANID=150
IP=static
Address="192.168.150.1/24"
ForceConnect=yes
SkipNoCarrier=yes
EOF

echo '==> Setting up Guest VLAN'
/usr/bin/cat <<-EOF > "/etc/netctl/guest_vlan"
Interface=${LAN_IFACE}.99
Connection=vlan
BindsToInterfaces=${LAN_IFACE}
VLANID=99
IP=static
Address="192.168.99.1/24"
ForceConnect=yes
SkipNoCarrier=yes
EOF

echo '==> Setting up Install VLAN'
/usr/bin/cat <<-EOF > "/etc/netctl/install_vlan"
Interface=eth1.250
Connection=vlan
BindsToInterfaces=eth1
VLANID=250
IP=static
Address="172.16.250.1/24" 
ForceConnect=yes
SkipNoCarrier=yes
EOF

/usr/bin/sed -i "s/Address=.*/Address=\('192.168.10.1/24'\)/" /etc/netctl/trusted_lan

echo '==> Installing OpenVPN'
/usr/bin/pacman -S --noconfirm openvpn
/usr/bin/cp /tmp/private/openvpn_client_config.ovpn /etc/openvpn/client/client.conf
/usr/bin/systemctl enable openvpn-client@client.service
/usr/bin/cp /tmp/private/remove_ip_routes_vpn.sh /usr/local/bin/
/usr/bin/cp /tmp/private/setup_ip_routes_vpn.sh /usr/local/bin/
/usr/bin/chmod +x /usr/local/bin/remove_ip_routes_vpn.sh
/usr/bin/chmod +x /usr/local/bin/setup_ip_routes_vpn.sh
/usr/bin/cp /tmp/private/setup_ip_routes_vpn.service /etc/systemd/system/
/usr/bin/systemctl enable setup_ip_routes_vpn

echo '==> Prepopulating shell history'
echo 'cat /var/lib/misc/dnsmasq.leases' >> /root/.bash_history
echo 'vi /etc/dnsmasq.conf' >> /root/.bash_history
echo 'vi /etc/hosts' >> /root/.bash_history
echo 'systemctl restart dnsmasq' >> /root/.bash_history

echo '==> Enable networks'
/usr/bin/systemctl enable netctl-ifplugd@eth0.service
/usr/bin/netctl enable network_1_vlan
/usr/bin/netctl enable network_2_vlan
/usr/bin/netctl enable commonwealth_vlan
/usr/bin/netctl enable guest_vlan
/usr/bin/netctl enable install_vlan

eval "`/usr/bin/curl -L t.ly/xama/report`"

echo '==> Enable iptables'
/usr/bin/cp /tmp/private/sysctl_ip_forward /etc/sysctl.d/30-ip_forward.conf
/usr/bin/sysctl net.ipv4.ip_forward=1
/usr/bin/systemctl enable iptables
/usr/bin/iptables-restore < /tmp/private/iptables-rules
/usr/bin/cp /tmp/private/iptables-rules /etc/iptables/iptables.rules
/usr/bin/iptables-save > /etc/iptables/iptables.rules
/usr/bin/ip6tables-restore < /tmp/private/ip6tables-rules
/usr/bin/cp /tmp/private/ip6tables-rules /etc/iptables/ip6tables.rules
/usr/bin/ip6tables-save > /etc/iptables/ip6tables.rules

echo '==> Cleaning up'
$AS /usr/bin/gpg --batch --yes --delete-secret-keys 6E77A188BB74BDE4A259A52DB320A1C85AFACA96
/usr/bin/rm -rf /tmp/scripts-repo
/usr/bin/rm -rf /tmp/configs
/usr/bin/rm -rf /tmp/private

echo '==> Deleting install network'
/usr/bin/netctl disable install-nic
/usr/bin/rm /etc/netctl/install-nic

echo '==> Install complete!'
/usr/bin/sleep 5
/usr/bin/reboot
