# Bruce Linux

## Intro

Bruce is a framework to create, maintain and distribute customized Linux builds for a target user group.
Features:

* bootable on most x64-compatible computers capable of UEFI boot
* temporary modifiable system while immutable across reboots
* can be used without touching locally installed operating systems
* password-protected and encrypted
* updating mechanism allowing OTA updates via https (e.g. Nextcloud)

## Contents

* distributed scripts to create and maintain customized bootable ISOs for portable and secure usage.
* testing takes place inside a VirtualBox VM.
* creation of a bootable USB stick has to be done on a PC/Laptop with USB3 support.

## Procedure

```
source ./init.sh
./bootstrap.sh
source ./init.sh
./build.sh
./vboxtest.sh
./create-usbstick.sh
```
