#!/bin/bash

# FIXME check this value before running!!!
USBDEVICE=/dev/sdb

echo
echo "///INITIALIZING USB STICK///"
echo

sudo cryptsetup luksClose luks-$BL_P2UUID
sudo cryptsetup luksClose luks-$BL_P3UUID
sudo umount ${USBDEVICE}*
sudo umount /media/$USER/*
sudo wipefs -a -f "$USBDEVICE"
sync

echo
echo "///CREATING $BL_P1LABEL///"
echo

sudo fdisk $USBDEVICE << FDISK_CMDS
n
p
1

+$BL_P1SIZE
a
t
c
w
FDISK_CMDS

echo
echo "///CREATING $BL_P2LABEL///"
echo

sudo fdisk $USBDEVICE << FDISK_CMDS
n
p
2

+$BL_P2SIZE
t
2
e8
w
FDISK_CMDS

echo
echo "///CREATING $BL_P3LABEL///"
echo

sudo fdisk $USBDEVICE << FDISK_CMDS
n
p
3

+$BL_P3SIZE
t
3
e8
w
FDISK_CMDS

echo
echo "///CREATING $BL_P4LABEL///"
echo

sudo fdisk $USBDEVICE << FDISK_CMDS
n
p
4


t
4
e8
w
FDISK_CMDS

echo
echo "///DONE///"
echo
