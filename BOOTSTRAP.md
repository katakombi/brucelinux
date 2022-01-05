# Bootstrapping a customized bootable Linux ISO

## Intro

This setup will work on a linux mint, ubuntu or debian machine. First fetch docs & code.

If SSH key installed:
```
git clone git@github.com:katakombi/brucelinux.git
```

Install some requirements:
```
sudo apt-get install squashfs-tools genisoimage 
```

## Bootstrapping

We derive our customized ISO from an official Linux Mint release.
This bootstrapping procedure has to be repeated from scratch after every major LTS distro release (typically every second year).

```
sudo rm -rf chroot extract-cd
mkdir -p {extract-cd,mnt}
wget -nc http://mirror.bauhuette.fh-aachen.de/linuxmint-cd/testing/linuxmint-20.3-mate-64bit-beta.iso -O linuxmint-base.iso

if sha256sum linuxmint-base.iso | grep e065a4ad36d7e6d31ba0a3ae43836ae8e4232f5b80107da81c50746192e7de2c ; then
  echo "ISO verified successfully!"
else
  echo "Please check ISO - it is unverified and might be wrong!"
fi

sudo mount -o loop linuxmint-base.iso mnt
sudo rsync --exclude=/casper/filesystem.squashfs -a mnt/ extract-cd
time sudo unsquashfs mnt/casper/filesystem.squashfs
sudo umount mnt
sudo mv squashfs-root chroot
```

### Chroot
```
cat << EOF > bashrc
echo "Ready to modify the ISO..."
export HOME=/root
export LC_ALL=C
export PS1="\[\e[5;31;1m\]brucelinux\[\e[0m\] $PS1"
EOF

sudo mv bashrc chroot/root/.bashrc
sudo cp /etc/resolv.conf chroot/etc/

./chroot.sh
```
Your project is ready for modifications, make whatever changes you want like adding or removing software

#### Remove/Install/Upgrade packages
```
apt update

dpkg-query --show --showformat='${Installed-Size}\t${Package}\n' | sort -rh > /packages.lst.orig

apt -y install apt-transport-https curl
curl -fsSLo /usr/share/keyrings/brave-browser-archive-keyring.gpg https://brave-browser-apt-release.s3.brave.com/brave-browser-archive-keyring.gpg
echo "deb [signed-by=/usr/share/keyrings/brave-browser-archive-keyring.gpg arch=amd64] https://brave-browser-apt-release.s3.brave.com/ stable main"|sudo tee /etc/apt/sources.list.d/brave-browser-release.list

apt purge hexchat* thunderbird* libreoffice* warpinator rhythmbox celluloid ubiquity-ubuntu-artwork ubiquity-slideshow-mint ubiquity-frontend-gtk ubiquity default-jre openjdk-11-jre default-jre-headless openjdk-11-jre-headless

apt -y install anydesk screen vim yad xdotool numlockx chromium imagemagick-6.q16 virtualbox-guest-utils virtualbox-guest-x11 virtualbox-guest-dkms qtqr brave-browser

# TODO download/install Zoiper ...

# updating system packages
apt upgrade 

# remove all but most recent kernel...
dpkg --get-selections|grep linux-image
apt remove ...
apt autoremove
apt clean

# update package list and compare
dpkg-query --show --showformat='${Installed-Size}\t${Package}\n' | sort -rh > /packages.lst

vimdiff /packages.lst /packages.lst.orig

```
#### Setup system
FIXME rc.local scripts...
```
# enable numlock
sed -i.bak 's/NUMLOCK=auto/NUMLOCK=on/' /etc/default/numlockx

systemctl enable ufw # TODO enable in /etc/rc.local!

dpkg-reconfigure tzdata # select Europe/Berlin
dpkg-reconfigure locales # mark de_DE.UTF-8 and en_US.UTF8; select de_DE.UTF-8 as default

cat << EOF > /etc/systemd/system/rc-local.service
[Unit]
 Description=/etc/rc.local Compatibility
 ConditionPathExists=/etc/rc.local
 
[Service]
 Type=forking
 ExecStart=/etc/rc.local start
 TimeoutSec=0
 StandardOutput=tty
 RemainAfterExit=yes
 SysVStartPriority=99
 
[Install]
 WantedBy=multi-user.target
EOF

cat << EOF > /etc/systemd/system/run-before-shutdown.service
[Unit]
Description=Run my custom task at shutdown
DefaultDependencies=no
Before=shutdown.target

[Service]
Type=oneshot
ExecStart=/etc/on-shutdown.sh
TimeoutStartSec=0

[Install]
WantedBy=shutdown.target
EOF

cat << EOF > /etc/systemd/system/run-before-reboot.service
[Unit]
Description=Run my custom task at reboot
DefaultDependencies=no
Before=shutdown.target

[Service]
Type=oneshot
ExecStart=/etc/on-reboot.sh
TimeoutStartSec=0

[Install]
WantedBy=reboot.target
EOF

systemctl enable rc-local
systemctl enable run-before-shutdown.service 
systemctl enable run-before-reboot.service

# these files will be copied in-place right before the ISO build
# /etc/{crypttab,rc.local,on-shutdown.sh,on-reboot.sh,info/*}
```

Now exit the chroot!

```
exit
```

## Result

Now you have a base chroot to build a bootable ISO for use on a laptop, PC or VM.
