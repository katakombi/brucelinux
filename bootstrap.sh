#!/bin/bash

if [[ -d $BL_CHROOTDIR ]]; then
	echo "Chroot $BL_CHROOTDIR exists already, refusing to bootstrap. Delete it manually to bootstrap from scratch!"
	exit 2
else
	source ./init.sh
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

echo "Running the customization script..."

CHDIR=$BL_CHROOTDIR

echo Bind mounting
sudo mount -t proc none $CHDIR/proc
sudo mount -o bind /dev $CHDIR/dev
sudo mount -o bind /dev/pts $CHDIR/dev/pts

cat << EOF | sudo tee $CHDIR/root/.bashrc > /dev/null
echo "Ready to modify the ISO..."
export HOME=/root
export LC_ALL=C
export PS1="\[\e[5;31;1m\]brucelinux\[\e[0m\] $PS1"
EOF

sudo cp /etc/resolv.conf $CHDIR/etc/resolv.conf
sudo cp config/${BL_PROFILE}.sh $BL_CHROOTDIR/tmp

echo CHROOT $CHDIR bash -c /tmp/${BL_PROFILE}.sh 
sudo chroot $CHDIR bash -c /tmp/${BL_PROFILE}.sh 


echo Updating packages.lst
sudo chroot $CHDIR su -c "dpkg-query --show --showformat='\${Installed-Size}\t\${Package}\n' | sort -rh > /packages.lst"
sudo chroot $CHDIR su -c "cat /packages.lst | awk '{if ((\$1>0)&&NF==2) sum+=\$1}END{printf(i\"Total package size in kB: %i\n\", sum/1024)}'"

echo Cleaning up
sudo rm -rf $CHDIR/tmp/* $CHDIR/root/.bash_history
sudo umount $CHDIR/dev/pts
sudo umount $CHDIR/dev
sudo umount $CHDIR/proc

echo "Done!"
