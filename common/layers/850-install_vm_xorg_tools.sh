#!/bin/bash

# Enable Virtualbox integrations
/usr/bin/pacman -S --noconfirm virtualbox-guest-utils
/usr/bin/systemctl enable vboxservice.service
