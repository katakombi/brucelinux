#!/bin/bash

# FIXME check this value before running!!!
USBDEVICE=/dev/sdb

AUTOMOUNT_SETTING=$(gsettings get org.mate.media-handling automount)
gsettings set org.mate.media-handling automount false

BL_MASTERKEY=$(sudo cat $BL_MASTERKEYFILE)
BL_USERKEY=$(sudo cat $BL_USERKEYFILE)

echo "MASTER:$BL_MASTERKEY USER:$BL_USERKEY"

echo
echo "///RECONNECT USB STICK///"
echo

mkdir -p /tmp/mnt

sudo cryptsetup luksClose luks-$BL_P2UUID
sudo cryptsetup luksClose luks-$BL_P3UUID
sudo umount ${USBDEVICE}*
sudo umount /media/$USER/*

eject ${USBDEVICE}
while ! (lsblk | grep ${USBDEVICE#/dev/}); do
	echo -n "..."
	sleep 1
done

sudo cryptsetup luksClose luks-$BL_P2UUID
sudo cryptsetup luksClose luks-$BL_P3UUID
sudo sudo umount ${USBDEVICE}*
sudo umount /media/$USER/*

echo
echo "///SETUP $BL_P1LABEL///"
echo

sudo mkfs.vfat -F 32 -n $BL_P1LABEL ${USBDEVICE}1
sudo sh -c 'mkdir -p /tmp/mnt && mount '${USBDEVICE}'1 /tmp/mnt && mkdir -p /tmp/mnt/boot'
sudo apt install -y grub-pc
sudo sh -c 'grub-install --force --removable --no-floppy --target=i386-pc --boot-directory=/tmp/mnt/boot '$USBDEVICE
sudo apt install -y grub-efi-amd64
sudo sh -c 'grub-install --force --removable --no-floppy --target=x86_64-efi --boot-directory=/tmp/mnt/boot --efi-directory=/tmp/mnt'

cat <<'EOF' | sudo tee /tmp/mnt/boot/grub/grub.cfg
set timeout=3
set default=0

menuentry "BRUCE Linux" {
 insmod lvm
 insmod luks
# mount system_crypt
 cryptomount -u f5cf619ed1cb4b7eb8b8f7d0dc3c37c0
 set isofile="/iso/bruce.iso"
 loopback loop (crypto0)$isofile
 linux (loop)/casper/vmlinuz boot=casper bootfrom=/dev/mapper/dm-0 username=bruce file=/cdrom/preseed/mint.seed initrd=/casper/initrd.lz iso-scan/filename=$isofile bootcfg=mobile netcfg=default toram noeject noprompt splash --
 initrd (loop)/casper/initrd.lz
}

menuentry "Benutzerprofil zurücksetzen" {
 insmod lvm
 insmod luks
# mount system_crypt
 cryptomount -u f5cf619ed1cb4b7eb8b8f7d0dc3c37c0
 set isofile="/iso/bruce.iso"
 loopback loop (crypto0)$isofile
 linux (loop)/casper/vmlinuz boot=casper bootfrom=/dev/mapper/dm-0 file=/cdrom/preseed/mint.seed initrd=/casper/initrd.lz iso-scan/filename=$isofile factoryreset noeject noprompt splash --
 initrd (loop)/casper/initrd.lz
}
EOF

sudo umount /tmp/mnt

echo
echo "///SETUP $BL_P2LABEL///"
echo

sudo cryptsetup luksClose /dev/mapper/*
sudo umount ${USBDEVICE}*
sudo umount /media/$USER/*

sudo cryptsetup luksClose luks-$BL_P2UUID
BL_SYSTEMKEY=$BL_MASTERKEY
echo -n $BL_SYSTEMKEY | \
	sudo cryptsetup -q --pbkdf-force-iterations=90000 --uuid=$BL_P2UUID --type=luks1 --cipher \
	aes-xts-plain --key-size 512 --hash sha512 -v luksFormat ${USBDEVICE}2
echo -n "${BL_SYSTEMKEY}${BL_MASTERKEY}" | \
	sudo cryptsetup -q --pbkdf-force-iterations=90000 luksAddKey --key-file - --keyfile-size ${#BL_SYSTEMKEY} --key-slot 1 /dev/disk/by-uuid/$BL_P2UUID /dev/stdin

echo -n $BL_MASTERKEY | sudo cryptsetup luksOpen ${USBDEVICE}2 $BL_P2LABEL
sudo mkfs -t ext4 -L $BL_P2LABEL /dev/mapper/$BL_P2LABEL
sudo mkdir -p /tmp/mnt && sudo mount /dev/mapper/$BL_P2LABEL /tmp/mnt
sudo mkdir -p /tmp/mnt/iso

# FIXME die richtige Datei muss irgendwie an Ort und Stelle kopiert werden...
sudo cp bruce.iso /tmp/mnt/iso/bruce.iso

sudo chmod 0700 /tmp/mnt/iso/bruce.iso
sudo umount /tmp/mnt
sudo cryptsetup luksClose $BL_P2LABEL

echo
echo "///SETUP $BL_P3LABEL///"
echo

sudo umount /media/$USER/*
sudo cryptsetup luksClose luks-$BL_P3UUID
echo -n $BL_USERKEY | \
	sudo cryptsetup -q --pbkdf-force-iterations=90000 --uuid=$BL_P3UUID --type=luks1 --cipher aes-xts-plain \
	--key-size 512 --hash sha512 -v luksFormat ${USBDEVICE}3
echo -n $BL_USERKEY | \
	sudo cryptsetup luksOpen ${USBDEVICE}3 $BL_P3LABEL
sudo mkfs -t ext4 -L $BL_P3LABEL /dev/mapper/$BL_P3LABEL
sudo cryptsetup luksClose $BL_P3LABEL

echo
echo "///SETUP $BL_P4LABEL///"
echo

sudo umount /media/$USER/*
sudo cryptsetup luksClose luks-$BL_P4UUID
echo -n $BL_USERKEY | \
	sudo cryptsetup -q --pbkdf-force-iterations=90000 --uuid=$BL_P4UUID --type=luks1 --cipher aes-xts-plain \
	--key-size 512 --hash sha512 -v luksFormat ${USBDEVICE}4
echo -n $BL_USERKEY | \
	sudo cryptsetup luksOpen ${USBDEVICE}4 $BL_P4LABEL
sudo mkfs -t ext4 -L $BL_P4LABEL /dev/mapper/$BL_P4LABEL
sudo mkdir -p /tmp/mnt && sudo mount /dev/mapper/$BL_P4LABEL /tmp/mnt
sudo chown -R 1000.1000 /tmp/mnt
sudo umount /tmp/mnt
sudo cryptsetup luksClose $BL_P4LABEL

sudo rm -rf /tmp/mnt
gsettings set org.mate.media-handling automount $AUTOMOUNT_SETTING
