#!/bin/bash

export BL_PROFILE="bruce" # set it according to "config/$BL_PROFILE"
export BL_PROFILECAP=${BL_PROFILE^^}
export BL_SPLASHSCREEN="misc/boot.png"

export BL_USERNAME=bruce
export BL_DEFAULT_NETCFG=default
export BL_DEFAULT_BOOTCFG=default
export BL_TEST_NETCFG=default
export BL_TEST_BOOTCFG=vbox

export BL_P1LABEL="BLBOOT"
export BL_P2LABEL="BLSYSTEM"
export BL_P3LABEL="BLRESCUE"
export BL_P4LABEL="BLHOME"

export BL_P1SIZE="100M"
export BL_P2SIZE="9G"
export BL_P3SIZE="9G"
export BL_P4SIZE="" # use rest of available space

export BL_P2UUID="f5cf619e-d1cb-4b7e-b8b8-f7d0dc3c37c0"
export BL_P3UUID="85c6e7c8-d0bf-422b-ae77-059449a911df"
export BL_P4UUID="a39ce5cb-d7d0-42d1-b433-3b2d8df10d7f"

echo "///SOURCING PROFILE $BL_PROFILE///"
source config/$BL_PROFILE.cfg

export BL_CHROOTDIR="chroot/$BL_PROFILE"

if [[ -d $BL_CHROOTDIR ]]; then
    echo "$BL_CHROOTDIR found ..."
else
    echo "Run ./bootstrap.sh, then rerun $0!"
    return 1;
fi


export BL_MASTERKEYFILE="$BL_CHROOTDIR/usr/share/initramfs-tools/scripts/casper-premount/master.secret"
export BL_USERKEYFILE="$BL_CHROOTDIR/usr/share/initramfs-tools/scripts/casper-premount/user.secret"

if [[ -z $BL_MASTERKEY ]]; then
    BL_MASTERKEY_PREV=$(sudo cat $BL_MASTERKEYFILE)
    echo
    echo "=== Please enter the master key ==="
    echo
    echo "Known to: Issuer only"
    echo "Location: $BL_P2LABEL -- LUKS header -- /usr/share/update-initrd/scripts/casper-premount/master.secret -- initrd image"
    echo "Persistence: Must not change ever!"
    echo "Serves for: booting the system"
    echo "Last used in ISO: $BL_MASTERKEY_PREV"
    read -sp 'MASTERKEY:' BL_MASTERKEY
fi;

if [[ -z $BL_USERKEY ]]; then
    BL_USERKEY_PREV=$(sudo cat $BL_USERKEYFILE)
    echo
    echo "=== Please enter the initial user password ==="
    echo
    echo "Known to: User only"
    echo "Location: $BL_P4LABEL $BL_P3LABEL -- LUKS header -- /etc/shadow"
    echo "Persistence: Can be changed after installation by the user"
    echo "Serves for: mounting /home and thereby providing user-specific settings/data"
    echo "Last used in ISO:$BL_USERKEY_PREV"
    read -sp 'USERKEY: ' BL_USERKEY
    echo ""
fi;

echo "///UTILIZING MASTERKEY=$BL_MASTERKEY -- USERKEY=$BL_USERKEY///"

sudo sh -c "\
  echo -n '///WRITING ';\
  echo -n '"$BL_MASTERKEY"' | tee $BL_MASTERKEYFILE;\
  echo ' TO $BL_MASTERKEYFILE///'; chmod 0600 $BL_MASTERKEYFILE;\
  echo '///BUILDING INITRD///'
  echo -n '///WRITING ';\
  echo -n '"$BL_USERKEY"' | sudo tee $BL_USERKEYFILE;\
  echo ' TO $BL_USERKEYFILE///'; chmod 0600 $BL_USERKEYFILE;\
"

echo "///MOUNTING RAMDRIVE///"

mkdir -p iso
if ! mountpoint iso/ > /dev/null ; then
  sudo mount -t tmpfs -o size=8096m isobuild iso/
fi

export BL_CONFIGDIR="$PWD"
echo "///DONE///"
