#!/bin/bash

# FIXME see whether this script requires devel.cfg
if [[ "$CHROOTDIR" == "" ]]; then
	CHDIR=chroot
else
	CHDIR=$CHROOTDIR
fi

if [ ! -d $CHDIR ]; then
	echo "chroot directory $CHDIR nonexistent! Bootstrap first!"
	exit 1
fi

if [ -f $CHDIR/.chroot ]; then
	echo "another chroot running...terminate it first!"
	exit 1;
else
	sudo touch $CHDIR/.chroot
fi

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

echo CHROOT
sudo chroot $CHDIR

echo Updating packages.lst
sudo chroot $CHDIR su -c "dpkg-query --show --showformat='\${Installed-Size}\t\${Package}\n' | sort -rh > /packages.lst"
sudo chroot $CHDIR su -c "cat /packages.lst | awk '{if ((\$1>0)&&NF==2) sum+=\$1}END{printf(i\"Total package size in kB: %i\n\", sum/1024)}'"

echo Cleaning up
sudo rm -rf $CHDIR/tmp/* $CHDIR/root/.bash_history
sudo umount $CHDIR/dev/pts
sudo umount $CHDIR/dev
sudo umount $CHDIR/proc
sudo rm $CHDIR/.chroot
