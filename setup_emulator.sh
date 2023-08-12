#!/bin/bash -ex

cp /mnt/entrypoint.sh /usr/bin/

apt update
apt install -y ssh xorg libqt5gui5 libqt5bluetooth5 libgles2-mesa
rm -rf /var/lib/apt/lists/*
mkdir -p /usr/local
echo /usr/local/qt5.15/lib | tee /etc/ld.so.conf.d/qt5.15.conf
ldconfig
ssh-keygen -A -v

echo "pi:qtxrpi" | chpasswd
