### Setup

```sh
docker build -t boot2qt .
```

### Build

```sh
mkdir b2qt
docker run --rm -it -v ./b2qt:/b2qt boot2qt
cd b2qt
repo init -u git://code.qt.io/yocto/boot2qt-manifest -m v5.15.2.xml
repo sync
export MACHINE=raspberrypi4 && source ./setup-environment.sh

bitbake b2qt-embedded-qt5-image
```

### Flash

```sh
dd if=b2qt/build-raspberrypi4/tmp/deploy/images/raspberrypi4/b2qt-embedded-qt5-image-raspberrypi4-XXXXXXX.rootfs.rpi-sdimg of=/dev/sdX bs=4M conv=fsync 
```

### Build SDK

```sh
# for docker setup see above
bitbake meta-toolchain-b2qt-embedded-qt5-sdk
```

### Install SDK

```sh
./b2qt/build-raspberrypi4/tmp/deploy/sdk/b2qt-x86_64-meta-toolchain-b2qt-embedded-qt5-sdk-raspberrypi4.sh
 sudo /opt/b2qt/3.0.4/configure-qtcreator.sh --config /opt/b2qt/3.0.4/environment-setup-cortexa7t2hf-neon-vfpv4-poky-linux-gnueabi --qtcreator /usr/ --name qt5-pi4-template

# Set up Qt Version manually, choose in cloned kit
```

where you have to replace `X` by the correct values.

### References

- https://raymii.org/s/tutorials/Yocto_boot2qt_for_the_Raspberry_Pi_4_both_Qt_6_and_Qt_5.html

### TODO

- add `git config --global url."https://".insteadOf git://` to Docker build
- add git patches for Qt5-specific modifications mentioned on raymii.org
