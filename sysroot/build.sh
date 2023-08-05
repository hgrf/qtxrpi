#!/bin/bash -ex
cd /sysroot
rm -rf lib usr/lib usr/include
mkdir -p lib usr/lib usr/include
rsync -avh /lib ./
rsync -avh /usr/lib usr/
rsync -avh /usr/include usr/
