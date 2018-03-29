#!/bin/bash
LOOPNAME=`losetup -f`
FILENAME=lxde_linux.img
TARGETDIR=target_system
dd if=/dev/zero of=$FILENAME  bs=1024 count=3174400
losetup $LOOPNAME  $FILENAME
mkfs -t ext3 -m 1 -v $LOOPNAME
mkdir $TARGETDIR
mount -t ext3 $LOOPNAME $TARGETDIR
multistrap -a armhf -f multistrap.conf -d $TARGETDIR
cp /usr/bin/qemu-arm-static ${TARGETDIR}/usr/bin
export DEBIAN_FRONTEND=noninteractive DEBCONF_NONINTERACTIVE_SEEN=true
LC_ALL=C LANGUAGE=C LANG=C chroot $TARGETDIR dpkg --configure -a
umount $TARGET_DIR
losetup -d $LOOPNAME
