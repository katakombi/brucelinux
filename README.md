# Bruce Linux

## Intro

Bruce is a framework to create, maintain and distribute customized Linux builds for a target user group.
Features:

* Immutable base system which does not touch locally installed operating systems
* Password-protected and encrypted
* Bootable on most x64-compatible computers capable of UEFI boot
* Updating mechanism allowing OTA updates via https (e.g. Nextcloud)

## Contents

Distributed scripts to create and maintain customized bootable ISOs for portable and secure usage.
Testing takes place inside a VirtualBox VM.
Creation of a bootable USB stick has to be done on a PC/Laptop with USB3 support.

## Procedure

* run [a bootstrap](BOOTSTRAP.md) of the ISO

* the image can be [maintained](MAINTENANCE.md) like this

* to produce the [USB stick](USBSTICK.md)
