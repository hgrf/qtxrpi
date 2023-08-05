#!/bin/bash -ex
cd /sysroot
rm -rf lib usr/lib usr/include
mkdir -p lib usr/lib usr/include
rsync -avh /lib lib
rsync -avh /usr/lib usr/lib
rsync -avh /usr/include usr/include
