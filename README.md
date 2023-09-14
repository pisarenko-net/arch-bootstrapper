# arch-bootstrapper
Automated Arch Linux provisioning for VMs and physical machines at Sergey's places.

Self-contained collection of setup scripts and configurations to build and deploy computers and network appliances from a bootable Arch thumb drive to a completely configured functioning state. The goal is to have disposable hardware that can be replaced with minimal effort and reasonable automation. Instead of doing backups and maintenance each machine is rebuilt from scratch on a whim. Everything is driven by software, nothing is installed manually.

There are two stages in this setup process:

  1. **Bootstrap** - a machine is completely wiped and a fresh copy of Arch is installed. Once the bootstrap completes the machine is bootable and reachable through SSH (certification-based authentication only). Bootstrap is started from the Arch installer.
  2. **Install** - machine is fully configured for its intended purpose. Install is initiated from the machine's terminal or through SSH once it successfully boots after the bootstrap.

Each device has its own folder with configuration files. Some configuration files are encrypted. The script will ask for a passphrase to unlock the files if that's the case.

Common scripts are placed in common/layers folder. For example, the bootstrap is identical for every machine except for configuration variables. Similarly, cli-layer and x-layer install and configure tools I use on every Linux box.

## Physical machines

### ch.router

ch.router Last Installed **2022-12-03**

Bootstrap (from Arch installer):
```
$ curl -L git.io/bootstrap_ch_router_sergey | sh
```

Install (requires: config decryption key in `private.key`, root):
```
# curl -L git.io/install_ch_router_sergey | sh
```

### ch.nuc

ch.nuc Last Installed **2021-05-01**

Bootstrap (from Arch installer):
```
$ curl -L git.io/bootstrap_ch_nuc_sergey | sh
```

Install (requires: config decryption key in `private.key`, root):
```
# curl -L git.io/install_ch_nuc_sergey | sh
```

### ch.ha (Home Assistant / Smart Home)

ch.ha Last Installed **2023-09-14**

Bootstrap (from Arch installer):
```
$ curl -L t.ly/xama/ch.ha | sh
```

Install (requires: config decryption key in `private.key`, root):
```
# curl -L t.ly/xama/install_ch_ha | sh
```

### ch.cddev (CD Player dev environment)

Custom built CD Player appliance powered by Odyssey X86 board. This is the development image, used for building and debugging custom PCBs (e.g. Arduino IDE) and software.

ch.cddev Last Installed **2022-04-04**

Bootstrap (from Arch installer):
```
$ curl -L git.io/bootstrap_ch_cddev_sergey | sh
```

Install (requires: config decryption key in `private.key`, root):
```
# curl -L git.io/install_ch_cddev_sergey | sh
```

## VMs

The "vagrant/packer" directory contains scripts and configuration files necessary to produce base ArchLinux image. The "vagrant/vms" directory contains scripts and Vagrant configuration files to produce complete preconfigured and usable VMs.

### Configure

Base image configuration is specified in `packer/arch-base.json`. Useful settings:

  1. URL to the Arch installation ISO
  2. URL to fetch mirrors
  3. Maximum size of the VM disk

The base image is used as a foundation for every VM. This image is based on a minimal Arch Linux. Setup scripts are shared between the VMs and physical machines.

VMs are defined in `vms/xxx/Vagrantfile`. Use `private` folder to bundle secrets, such as SSH keys or license files. See the `Vagrantfile` and corresponding setup scripts for more information.

### Usage

1. Build the base ArchLinux VirtualBox image using [Packer](packer.io):
```
$ packer build -force arch-base.json
$ vagrant box add output/arch_vagrant_base.box --name arch-base-YYYY-MM-DD --force  ## force is needed only when replacing
```
2. Edit and provision a particular [Vagrant](https://www.vagrantup.com/) configuration

### Extras

There are two useful apps under `common/apps` related to VMs:
  - **vm_refresh_packer**: updates Arch version and rebuilds the base image
  - **vm_rebuild_install** *<vm_name>*: builds and installs a particular VM image for automatic start on boot

### VirtualBox

Get rid of VirtualBox menu and status bar:
```
VBoxManage setextradata global GUI/Customizations noMenuBar,noStatusBar
```

To re-enable menu and status bar:
```
VBoxManage setextradata global GUI/Customizations MenuBar,StatusBar
```
