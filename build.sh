#!/bin/bash

if [[ "$BL_CONFIGDIR" == "" ]]; then
        echo "Run 'source devel.cfg' first!"
        exit 1
fi

echo ///CLEANING UP BIND MOUNTS///
sudo umount $BL_CHROOTDIR/dev/pts 2> /dev/null
sudo umount $BL_CHROOTDIR/dev 2> /dev/null
sudo umount $BL_CHROOTDIR/proc 2> /dev/null

echo ///UPDATING PACKAGE LIST///
sudo chroot $BL_CHROOTDIR sh -c "dpkg-query --show --showformat='\${Installed-Size}\t\${Package}\n' | sort -rh > /packages.lst"

echo ///CLONING KERNEL///
sudo sh -c 'cat '$BL_CHROOTDIR'/boot/vmlinuz > extract-cd/casper/vmlinuz'
sudo sh -c 'cat '$BL_CHROOTDIR'/boot/initrd.img > extract-cd/casper/initrd.lz'

echo ///CREATING BOOT MENU///
D=$(date +"%Y-%m-%d")
V=$(./generate-versionname.sh "$(date)")

echo "$D: building $V"

sudo cp config/$BL_PROFILE/boot.png extract-cd/isolinux/boot.png

cat << EOF | sudo tee extract-cd/isolinux/isolinux.cfg
default vesamenu.c32
timeout 33

menu background boot.png
menu title $BL_PROFILECAP Linux\n$V - n$D

menu color screen       37;40      #80ffffff #00000000 std
MENU COLOR border       30;44   #40ffffff #a0000000 std
MENU COLOR title        1;36;44 #ffffffff #a0000000 std
MENU COLOR sel          7;37;40 #e0ffffff #20ffffff all
MENU COLOR unsel        37;44   #50ffffff #a0000000 std
MENU COLOR help         37;40   #c0ffffff #a0000000 std
MENU COLOR timeout_msg  37;40   #80ffffff #00000000 std
MENU COLOR timeout      1;37;40 #c0ffffff #00000000 std
MENU COLOR msg07        37;40   #90ffffff #a0000000 std
MENU COLOR tabmsg       31;40   #ffDEDEDE #00000000 std
MENU WIDTH 78
MENU MARGIN 15
MENU ROWS 7
MENU VSHIFT 10
MENU TABMSGROW 12
MENU CMDLINEROW 12
MENU HELPMSGROW 16
MENU HELPMSGENDROW 29

label live
  menu label $BL_PROFILECAP Linux
  kernel /casper/vmlinuz
  append file=/cdrom/preseed/linuxmint.seed boot=casper initrd=/casper/initrd.lz bootcfg=$BL_TEST_BOOTCFG netcfg=$BL_TEST_NETCFG username=$BL_TEST_USERNAME quiet splash --
menu default
label factoryreset 
  menu label Factory reset
  kernel /casper/vmlinuz
  append file=/cdrom/preseed/linuxmint.seed boot=casper initrd=/casper/initrd.lz factoryreset quiet splash --
EOF

echo ///MERGING BASE SYSTEM WITH CONFIGURATION///

time sudo rsync --exclude-from=excludes -rahlp --delete $BL_CHROOTDIR/ iso/ 

sudo mkdir -p iso/etc/info
echo "$V" | sudo tee iso/etc/info/version
echo "$D" | sudo tee iso/etc/info/date

sudo rsync -ravhlp config/$BL_PROFILE/etc/ iso/etc
sudo sed -i 's|BL_USERKEYFILE|'${BL_USERKEYFILE#$CHROOTDIR}'|' iso/etc/rc.local
sudo sed -i 's/BL_P4LABEL/'$BL_P4LABEL'/' iso/etc/rc.local
sudo sed -i 's/BL_P4UUID/'$P4UUID'/' iso/etc/crypttab
sudo sed -i 's/BL_P4LABEL/'$P4LABEL'/' iso/etc/crypttab

#sudo rsync -ravhlp config/$BL_PROFILE/usr/local/* iso/usr/local/
#sudo chown -R root.root iso/usr/local/
#sudo chmod -R 755 iso/usr/local/

# TODO make this independent of $PROFILE and adjust groups
#USERGROUPS="disk,audio,video,users,dip,plugdev,scanner,davfs2,adm,sudo"
USERGROUPS="disk,audio,video,users,dip,plugdev,scanner"
sudo chroot iso/ useradd -U -M -s /bin/bash -G $USERGROUPS $BL_DEFAULT_USER

echo ///PATCHING INITRD///

sudo sed -i '/^. \/scripts\/lupin-helpers.*/a . \/scripts\/brucelinux' iso/usr/share/initramfs-tools/scripts/casper-premount/20iso_scan
sudo rsync -rahlp config.global/initrd/hooks/brucelinux iso/usr/share/initramfs-tools/hooks/brucelinux
sudo rsync -rahlp config.global/initrd/scripts/brucelinux iso/usr/share/initramfs-tools/scripts/brucelinux
sudo sed -i 's|ENV_P4LABEL|'$P4LABEL'|' iso/usr/share/initramfs-tools/scripts/brucelinux
sudo sed -i 's|ENV_P4UUID|'$P4UUID'|' iso/usr/share/initramfs-tools/scripts/brucelinux

sudo sh -c "
  mount -t proc none iso/proc
  mount -o bind /dev iso/dev
  mount -o bind /dev/pts iso/dev/pts
  chroot iso sh -c 'update-initramfs -u'
  umount iso/dev/pts
  umount iso/dev
  umount iso/proc
"
sudo sh -c 'cat iso/boot/vmlinuz > extract-cd/casper/vmlinuz'
sudo sh -c 'cat iso/boot/initrd.img > extract-cd/casper/initrd.lz'

echo ///MERGING USER PROFILE///

#rsync -rahp --delete $SOURCE/$PROFILE/home.tgz skel/$PROFILE/home.tgz
#sudo sh -c 'cp skel/'$PROFILE'/home.tgz iso/etc/skel'
#cd iso/etc/skel/ && sudo sh -c 'tar -xzpf home.tgz && rm -f home.tgz' && cd ../../../
#sudo chown -R root.root iso/etc/skel

echo ///BUILDING ISO FOR $V///

#time sudo mksquashfs iso extract-cd/casper/filesystem.squashfs # fast
#time sudo mksquashfs iso extract-cd/casper/filesystem.squashfs -comp zstd -Xcompression-level 22 # medium fast and ok
#time sudo mksquashfs iso extract-cd/casper/filesystem.squashfs -b 1048576 -comp xz -Xdict-size 100% # extremely slow but 1.7G vs 2.1G
time sudo mksquashfs iso extract-cd/casper/filesystem.squashfs -comp zstd -b 256K -Xcompression-level 22 # faster decompression

sudo rm -rf extract-cd/MD5SUM 

cd extract-cd && find -type f -print0 | sudo xargs -0 md5sum | grep -v isolinux/boot.cat | sudo tee MD5SUM && cd ..
sudo mkisofs -r -V "$V_$D" -cache-inodes -J -l -b isolinux/isolinux.bin -c isolinux/boot.cat -no-emul-boot -boot-load-size 4 -boot-info-table -o $BL_PROFILE.iso extract-cd && sudo chmod 777 $BL_PROFILE.iso

echo ///DONE///
