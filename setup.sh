#!/bin/bash -ex

echo deb-src http://raspbian.raspberrypi.org/raspbian/ bullseye main contrib non-free rpi >> /etc/apt/sources.list
apt-key adv --keyserver keyserver.ubuntu.com --recv-keys 9165938D90FDDD2E
apt update
apt install -y build-essential cmake unzip pkg-config gfortran
apt build-dep -y qt5-qmake libqt5gui5 libqt5webengine-data libqt5webkit5 libudev-dev libinput-dev libts-dev libxcb-xinerama0-dev libxcb-xinerama0
apt install -y libxcb-randr0-dev libxcb-xtest0-dev libxcb-shape0-dev libxcb-xkb-dev
apt install -y libbluetooth-dev
apt install -y rsync
rm -rf /var/lib/apt/lists/*
