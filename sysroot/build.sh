#!/bin/bash -ex
apt update
apt install -y \
    guestfish \
    linux-image-5.19.0-46-generic
cd /sysroot
rm -rf lib usr/lib usr/include
mkdir -p lib
mkdir -p usr/lib
mkdir -p usr/include
guestfish -a ../rootfs.qcow2 -m /dev/sda <<EOF
tgz-out /lib - | tar -C lib -zxvf -
tgz-out /usr/lib - | tar -C usr/lib -zxvf -
tgz-out /usr/include - | tar -C usr/include -zxvf -
EOF
