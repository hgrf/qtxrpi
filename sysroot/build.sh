#!/bin/bash -ex
apt update
apt install -y rsync
rm -rf /var/lib/apt/lists/*
cd /sysroot
rm -rf lib usr/lib usr/include
mkdir -p lib
mkdir -p usr/lib
mkdir -p usr/include
rsync -avh /lib lib
rsync -avh /usr/lib usr/lib
rsync -avh /usr/include usr/include
