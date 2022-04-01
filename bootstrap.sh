#!/bin/bash

if [[ "$BL_CONFIGDIR" == "" ]]; then
        echo "Run './init.sh' first!"
        exit 1
fi

cd $BL_CONFIGDIR

if [[ -d $BL_CHROOTDIR ]]; then
	echo "Chroot $BL_CHROOTDIR exists already, refusing to bootstrap. Delete it manually to bootstrap from scratch!"
	exit 2
fi

echo "Bootstrapping chroot $BL_CHROOTDIR from Linux Mint ISO..."

sudo rm -rf $BL_CHROOTDIR extract-cd squashfs-root
mkdir -p {extract-cd,mnt,chroot}
wget -nc http://mirror.bauhuette.fh-aachen.de/linuxmint-cd/stable/linuxmint-20.3-mate-64bit.iso -O linuxmint-base.iso

if sha256sum linuxmint-base.iso | grep 27de0b1e6d743d0efc2c193ec88d56a49941ce3e7d58b03730a4bb1895c25be5; then
  echo "ISO verified successfully!"
else
  echo "Please check ISO - it is unverified and might be comprimised!"
fi

sudo mount -o loop linuxmint-base.iso mnt
sudo rsync --exclude=/casper/filesystem.squashfs -a mnt/ extract-cd
time sudo unsquashfs mnt/casper/filesystem.squashfs
sudo umount mnt
sudo mv squashfs-root $BL_CHROOTDIR

echo "Done!"
