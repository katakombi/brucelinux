#!/bin/bash

. /etc/kernel_parameter_overrides

# backup wifi/lan connections...
mkdir -p /home/$USERNAME/.config/NetworkManager
rsync -ahvp /etc/NetworkManager/system-connections/ /home/$USERNAME/.config/NetworkManager/connections/

# umount /home to save all data
umount /home
