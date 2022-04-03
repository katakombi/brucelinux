# Bruce Linux

## Intro

Bruce is a framework to create, maintain and distribute customized Linux builds for a target user group.
Features:

* Bootable on most x64-compatible computers capable of UEFI boot
* Temporary modifiable system while immutable across reboots
* Can be used without touching locally installed operating systems
* Password-protected and encrypted
* Updating mechanism allowing OTA updates via https (e.g. Nextcloud)

## Contents

* Distributed scripts to create and maintain customized bootable ISOs for portable and secure usage.
* Testing takes place inside a VirtualBox VM.
* Creation of a bootable USB stick has to be done on a PC/Laptop with USB3 support.

## Procedure

```
source ./init.sh
./bootstrap.sh
source ./init.sh
./build.sh
./vboxtest.sh
./create-usbstick.sh
```
