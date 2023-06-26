## Setting up QEMU for Raspberry Pi 4 target

### References

- https://kitsunemimi.pw/notes/posts/headless-raspberry-pi-os-virtualization-64-bit-edition.html

sudo apt install qemu-system

## Qt5 setup

See also:
- https://wiki.qt.io/Raspberry_Pi_Beginners_Guide
- http://tvaira.free.fr/projets/activites/activite-qt5-rpi.html
- https://github.com/abhiTronix/raspberry-pi-cross-compilers/blob/master/QT_build_instructions.md
- https://github.com/UvinduW/Cross-Compiling-Qt-for-Raspberry-Pi-4
- https://www.interelectronix.com/qt-515-cross-compilation-raspberry-compute-module-4-ubuntu-20-lts.html

    # on Raspberry Pi
    echo "$USER ALL=NOPASSWD:$(which rsync)" | sudo tee --append /etc/sudoers
    sudo mkdir /usr/local/qt5.15
    sudo chown -R pi:pi /usr/local/qt5.15

    sudo nano /etc/apt/sources.list
    # uncomment: deb-src http://raspbian.raspberrypi.org/raspbian/ <stretch|buster|bullseye> main contrib non-free rpi

    echo "LC_ALL=en_US.UTF-8" | sudo tee -a /etc/environment
    echo "en_US.UTF-8 UTF-8" | sudo tee -a /etc/locale.gen
    echo "LANG=en_US.UTF-8" | sudo tee -a /etc/locale.conf
    sudo locale-gen en_US.UTF-8

    sudo apt update
    sudo apt install build-essential cmake unzip pkg-config gfortran
    sudo apt build-dep qt5-qmake libqt5gui5 libqt5webengine-data libqt5webkit5 libudev-dev libinput-dev libts-dev libxcb-xinerama0-dev libxcb-xinerama0 gdbserver
    sudo apt install libxcb-randr0-dev libxcb-xtest0-dev libxcb-shape0-dev libxcb-xkb-dev
    sudo apt install libbluetooth-dev

    # on host
    mkdir ~/rpi-qt
    cd ~/rpi-qt

    # for debugger {
    sudo apt install libncurses5 libpython2.7
    # }

    mkdir sysroot
    rsync -avz --rsync-path="sudo rsync" --delete pi@192.168.0.14:/lib sysroot
    rsync -avz --rsync-path="sudo rsync" --delete pi@192.168.0.14:/usr/include sysroot/usr
    rsync -avz --rsync-path="sudo rsync" --delete pi@192.168.0.14:/usr/lib sysroot/usr
    rsync -avz --rsync-path="sudo rsync" --delete pi@192.168.0.14:/opt/vc sysroot/opt

    wget https://raw.githubusercontent.com/abhiTronix/rpi_rootfs/master/scripts/sysroot-relativelinks.py
    chmod +x sysroot-relativelinks.py
    ./sysroot-relativelinks.py sysroot
    
    cd sysroot
    rm -rf usr/include/openssl
    rm -rf usr/include/sys
    ln -s arm-linux-gnueabihf/asm -t usr/include
    ln -s arm-linux-gnueabihf/gnu -t usr/include
    ln -s arm-linux-gnueabihf/bits -t usr/include
    ln -s arm-linux-gnueabihf/sys -t usr/include
    # {
    ln -s arm-linux-gnueabihf/openssl -t usr/include
    # } or maybe not delete openssl above and {
        ln -s ../arm-linux-gnueabihf/openssl/opensslconf.h -t usr/include/openssl
    # }
    ln -s arm-linux-gnueabihf/crtn.o usr/lib/crtn.o
    ln -s arm-linux-gnueabihf/crt1.o usr/lib/crt1.o
    ln -s arm-linux-gnueabihf/crti.o usr/lib/crti.o
    cd ..
    
Download toolchain from https://sourceforge.net/projects/raspberry-pi-cross-compilers/files/Raspberry%20Pi%20GCC%20Cross-Compiler%20Toolchains/Bullseye/GCC%2010.2.0/Raspberry%20Pi%203A%2B%2C%203B%2B%2C%204/cross-gcc-10.2.0-pi_3%2B.tar.gz

    tar -C ./ -xvf cross-gcc-10.2.0-pi_3+.tar.gz
    
    cd ~ 
    wget https://download.qt.io/archive/qt/5.15/5.15.3/single/qt-everywhere-opensource-src-5.15.3.tar.xz
    mkdir qt5 && tar -C qt5 --strip 1 -xvf qt-everywhere-opensource-src-5.15.3.tar.xz
    cp -R qt5/qtbase/mkspecs/linux-arm-gnueabi-g++ qt5/qtbase/mkspecs/linux-arm-gnueabihf-g++
    sed -i -e 's/arm-linux-gnueabi-/arm-linux-gnueabihf-/g' \
        qt5/qtbase/mkspecs/linux-arm-gnueabihf-g++/qmake.conf

Patch qt5/qtbase/src/corelib/global/qglobal.h to `#include <limits>` (in ifdef cplusplus)
    
Add following block to sysroot/usr/include/EGL/eglplatform.h:
    
    typedef uint32_t DISPMANX_ELEMENT_HANDLE_T;
    typedef struct {
        DISPMANX_ELEMENT_HANDLE_T element;
        int width;   /* This is necessary because dispmanx elements are not queriable. */
        int height;
    } EGL_DISPMANX_WINDOW_T;

(See also: https://forum.qt.io/topic/88588/qtbase-compilation-error-with-device-linux-rasp-pi3-g-qeglfskmsgbmwindow-cpp/9)

Force pointer casts in qt5/qtbase/src/plugins/platforms/eglfs/deviceintegration/eglfs_brcm/qeglfsbrcmintegration.cpp.

Execute:

    mkdir build && cd build
    CROSS_COMPILER_LOCATION=$HOME/rpi-qt/cross-pi-gcc-*
    ../qt5/configure -v -opengl es2 -eglfs \
        -device linux-rasp-pi4-v3d-g++ \
        -device-option CROSS_COMPILE=$(echo $CROSS_COMPILER_LOCATION)/bin/arm-linux-gnueabihf- \
        -sysroot ~/rpi-qt/sysroot/ \
        -opensource -confirm-license -release -nomake tests -nomake examples -no-compile-examples \
        -skip qtwayland -skip qtwebengine -skip qtlocation -skip qtscript \
        -prefix /usr/local/qt5.15 \
        -extprefix ~/rpi-qt/qt5.15 \
        -make libs -pkg-config -recheck \
        -no-use-gold-linker \
        -L$HOME/rpi-qt/sysroot/usr/lib/arm-linux-gnueabihf \
        -I$HOME/rpi-qt/sysroot/usr/include/arm-linux-gnueabihf

    make -j4
    make install

    cd ~/rpi-qt
    rsync -avz --rsync-path="sudo rsync" qt5.15 pi@192.168.0.14:/usr/local

    # update sysroot on host
    # TODO: does not need to be rsync, can be local copy or symlink
    rsync -avz --rsync-path="sudo rsync" --delete pi@192.168.0.14:/usr/local sysroot/usr

    # On Raspberry Pi
    echo /usr/local/qt5.15/lib | sudo tee /etc/ld.so.conf.d/qt5.15.conf
    sudo ldconfig