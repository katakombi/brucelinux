#!/bin/bash
#
# this is the bootstrap script for bruce linux
#

msg() {
    echo -e "\e[1;31m$@\033[0m"
}

msg ///dumping original packages///
dpkg-query --show --showformat='${Installed-Size}\t${Package}\n' | sort -rh > /packages.lst.orig

msg ///installing brave browser///
apt -y install apt-transport-https curl
curl -fsSLo /usr/share/keyrings/brave-browser-archive-keyring.gpg https://brave-browser-apt-release.s3.brave.com/brave-browser-archive-keyring.gpg
echo "deb [signed-by=/usr/share/keyrings/brave-browser-archive-keyring.gpg arch=amd64] https://brave-browser-apt-release.s3.brave.com/ stable main" | sudo tee /etc/apt/sources.list.d/brave-browser-release.list

msg ///remove/install packages///
apt -y update
apt purge -y hexchat* thunderbird* libreoffice* warpinator rhythmbox celluloid ubiquity-ubuntu-artwork ubiquity-slideshow-mint ubiquity-frontend-gtk ubiquity default-jre openjdk-11-jre default-jre-headless openjdk-11-jre-headless hypnotix firefox firefox-locale-en
apt -y install keepassxc screen vim yad xdotool numlockx chromium imagemagick-6.q16 virtualbox-guest-utils virtualbox-guest-x11 virtualbox-guest-dkms qtqr brave-browser

msg ///updating system packages///
apt full-upgrade -y

msg ///autoremove some packages///
apt autoremove -y

msg ///install latest 5.11 kernel///
KPKG=$(apt-cache search linux generic image|grep -v unsigned|grep 5.11|sort|tail -n 1|awk '{print $1}')
apt -y install $KPKG ${KPKG/-image-/-headers-}

msg ///purge remaining kernel headers///
apt autoremove -y

msg ///purge all other kernels///
for k in $(dpkg --get-selections|grep linux-image-5|grep -v $KPKG|awk '{print $1}'); do
    apt purge -y $k ${k/-image-/-headers-}
done
apt purge -y linux-image-unsigned*

msg ///purge remaining kernel headers///
apt autoremove -y

msg ///clean package cache///
apt clean

msg ///enable numlock///
sed -i.bak 's/NUMLOCK=auto/NUMLOCK=on/' /etc/default/numlockx

msg ///update package list///
dpkg-query --show --showformat='${Installed-Size}\t${Package}\n' | sort -rh > /packages.lst

msg ///timezone and locales cfg///
dpkg-reconfigure tzdata # select Europe/Berlin
dpkg-reconfigure locales # mark de_DE.UTF-8 and en_US.UTF8; select de_DE.UTF-8 as default
