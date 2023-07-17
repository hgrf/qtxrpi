## Setting up QEMU for Raspberry Pi 4 target

## Qt5 setup

    # on Raspberry Pi
    echo "$USER ALL=NOPASSWD:$(which rsync)" | sudo tee --append /etc/sudoers
    sudo mkdir /usr/local/qt5.15
    sudo chown -R pi:pi /usr/local/qt5.15

    echo "LC_ALL=en_US.UTF-8" | sudo tee -a /etc/environment
    echo "en_US.UTF-8 UTF-8" | sudo tee -a /etc/locale.gen
    echo "LANG=en_US.UTF-8" | sudo tee -a /etc/locale.conf
    sudo locale-gen en_US.UTF-8

    # on host
    mkdir ~/rpi-qt
    cd ~/rpi-qt

    # for debugger {
    sudo apt install libncurses5 libpython2.7
    # }

Execute:

    cd ~/rpi-qt
    rsync -avz --rsync-path="sudo rsync" qt5.15 pi@192.168.0.14:/usr/local

    # update sysroot on host
    # TODO: does not need to be rsync, can be local copy or symlink
    rsync -avz --rsync-path="sudo rsync" --delete pi@192.168.0.14:/usr/local sysroot/usr

    # On Raspberry Pi
    echo /usr/local/qt5.15/lib | sudo tee /etc/ld.so.conf.d/qt5.15.conf
    sudo ldconfig

### To do

`Makefile`:

- sysroot-relativelinks.py is sufficiently small to simply include it in the Makefile

`sysroot/build.sh`:

- firmware files should not be required, what about python, perl etc?
- sort out duplicates between /lib and /usr/lib (are they symlinks on the target?)

### References

- http://cdn.kernel.org/pub/linux/kernel/people/will/docs/qemu/qemu-arm64-howto.html
- http://sentryytech.blogspot.com/2013/02/faster-compiling-on-emulated-raspberry.html
- http://tvaira.free.fr/projets/activites/activite-qt5-rpi.html
- https://catalog.us-east-1.prod.workshops.aws/workshops/12f31c93-5926-4477-996c-d47f4524905d/en-US/10-getting-started/setup-rpi
- https://code.qt.io/cgit/qtonpi/mt-cross-tools.git/
- https://docs.kernel.org/admin-guide/efi-stub.html
- https://forums.raspberrypi.com/viewtopic.php?t=306511
- https://github.com/abhiTronix/raspberry-pi-cross-compilers/blob/master/QT_build_instructions.md
- https://github.com/multiarch/qemu-user-static
- https://github.com/pftf/RPi4#installation
- https://github.com/UvinduW/Cross-Compiling-Qt-for-Raspberry-Pi-4
- https://hackernoon.com/raspberry-pi-cluster-emulation-with-docker-compose-xo3l3tyw
- https://kitsunemimi.pw/notes/posts/headless-raspberry-pi-os-virtualization-64-bit-edition.html
- https://mechatronicsblog.com/cross-compile-and-deploy-qt-5-12-for-raspberry-pi/
- https://openclassrooms.com/fr/courses/5281406-creez-un-linux-embarque-pour-la-domotique/5464241-emulez-une-raspberry-pi-avec-qemu
- https://pete.akeo.ie/2019/07/installing-debian-arm64-on-raspberry-pi.html
- https://raduzaharia.medium.com/system-emulation-using-qemu-raspberry-pi-4-and-efi-87652ff203b7
- https://raymii.org/s/tutorials/Yocto_boot2qt_for_the_Raspberry_Pi_4_both_Qt_6_and_Qt_5.html
- https://stackoverflow.com/a/45814913
- https://stackoverflow.com/a/69182218
- https://stackoverflow.com/questions/44429394/x11-forwarding-of-a-gui-app-running-in-docker
- https://unix.stackexchange.com/questions/635435/manipulate-filesystem-image-files-without-loopback-devices
- https://wiki.beyondlogic.org/index.php?title=Cross_Compiling_BusyBox_for_ARM
- https://wiki.debian.org/Arm64Qemu
- https://wiki.qt.io/Create_Qt_on_Raspberry_Pi
- https://wiki.qt.io/Raspberry_Pi_Beginners_Guide
- https://www.ics.com/blog/building-qt-5-raspberry-pi#.U0ubso_7sYy
- https://www.interelectronix.com/qt-515-cross-compilation-raspberry-compute-module-4-ubuntu-20-lts.html
- https://www.youtube.com/watch?v=TmtN3Rmx9Rk
