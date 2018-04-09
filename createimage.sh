#!/bin/bash

#
# This script creates a Lubuntu 16.0.4 image using multistrap
# the packages it will install are listed in the multistrap.conf file
#

# ask losetup to find us the next available loopback device
LOOPNAME=`losetup -f`
FILENAME=lxde_linux.img
TARGETDIR=target_system

# create a 3.1G blank image
dd if=/dev/zero of=$FILENAME  bs=1024 count=3174400
# loop back the image
losetup $LOOPNAME  $FILENAME
# format the image as ext3
mkfs -t ext3 -m 1 -v $LOOPNAME
# create our mountpoint
mkdir $TARGETDIR
# mount the image to our mountpoint
mount -t ext3 $LOOPNAME $TARGETDIR
# run multistrap and fill the image with the packages with armhf architecture
multistrap -a armhf -f multistrap.conf -d $TARGETDIR
# we need qemu to be able to run within our chroot -- once we chroot the binaries are arm not intel
cp /usr/bin/qemu-arm-static ${TARGETDIR}/usr/bin
 
export DEBIAN_FRONTEND=noninteractive DEBCONF_NONINTERACTIVE_SEEN=true
sudo chroot $TARGETDIR mkdir -p /usr/share/man/man1
sudo chroot $TARGETDIR /var/lib/dpkg/info/dash.preinst
LC_ALL=C LANGUAGE=C LANG=C chroot $TARGETDIR dpkg --configure -a
sudo chroot $TARGETDIR mount proc -t proc /proc
LC_ALL=C LANGUAGE=C LANG=C chroot $TARGETDIR dpkg --configure -a
chroot $TARGETDIR locale-gen "en_US.UTF-8"
chroot $TARGETDIR update-locale LC_ALL=en_US.UTF-8 LANG=en_US.UTF-8
rsync -rl extras/ $TARGETDIR
chroot $TARGETDIR useradd mister -m  -G sudo -s /bin/bash
chroot $TARGETDIR chpasswd << 'END'
mister:mister
END
chroot $TARGETDIR chpasswd << 'END'
root:1
END
chroot $TARGETDIR apt-get update
# there is a bug with new versions of firefox on arm
# before latest 17x ubuntu - https://bugs.launchpad.net/ubuntu/+source/firefox/+bug/1711337
chroot $TARGETDIR apt-mark hold firefox
chroot $TARGETDIR apt-get upgrade -y
chroot $TARGETDIR umount /proc
umount $TARGETDIR
losetup -d $LOOPNAME
