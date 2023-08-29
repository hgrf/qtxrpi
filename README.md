## Cross-compilation with Qt5 for Raspberry Pi

### Download and setup

```
sudo make install

# test the emulator with
sudo make run-emulator
```

For debugging to work, make sure that `libpython2.7` is installed. For now,
the "Start debugging of startup project" button in QtCreator does not work
properly. This is because QtCreator wants to start `gdbserver --multi`, but
inside the Docker we use QEMU user mode emulation, i.e. the GDB server has
to be started manually as follows within the emulator:

```sh
qemu-aarch64-static -g 10000 <YOUR_EXECUTABLE>
```

where 10000 is the port where QEMU will set up the GDB server. You can then
use `Debug->Start Debugging->Attach to Running Debug Server` in QtCreator to
connect to the application.

### Setting up the target Raspberry Pi

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

On host, execute:

    cd ~/rpi-qt
    rsync -avz --rsync-path="sudo rsync" qt5.15 pi@192.168.0.14:/usr/local

    # update sysroot on host
    # TODO: does not need to be rsync, can be local copy or symlink
    # rsync -avz --rsync-path="sudo rsync" --delete pi@192.168.0.14:/usr/local sysroot/usr

On Raspberry Pi, execute:

    echo /usr/local/qt5.15/lib | sudo tee /etc/ld.so.conf.d/qt5.15.conf
    sudo ldconfig

### To do

`Makefile`:

- sysroot-relativelinks.py is sufficiently small to simply include it in the Makefile

`sysroot/build.sh`:

- firmware files should not be required, what about python, perl etc?
- sort out duplicates between /lib and /usr/lib (are they symlinks on the target?)

### References

- http://tvaira.free.fr/projets/activites/activite-qt5-rpi.html
- https://code.qt.io/cgit/qtonpi/mt-cross-tools.git/
- https://github.com/abhiTronix/raspberry-pi-cross-compilers/blob/master/QT_build_instructions.md
- https://github.com/UvinduW/Cross-Compiling-Qt-for-Raspberry-Pi-4
- https://mechatronicsblog.com/cross-compile-and-deploy-qt-5-12-for-raspberry-pi/
- https://unix.stackexchange.com/questions/635435/manipulate-filesystem-image-files-without-loopback-devices
- https://wiki.qt.io/Create_Qt_on_Raspberry_Pi
- https://wiki.qt.io/Raspberry_Pi_Beginners_Guide
- https://www.ics.com/blog/building-qt-5-raspberry-pi#.U0ubso_7sYy
- https://www.interelectronix.com/qt-515-cross-compilation-raspberry-compute-module-4-ubuntu-20-lts.html
- https://www.youtube.com/watch?v=TmtN3Rmx9Rk
- https://embeddeduse.com/2021/03/29/how-to-set-up-qtcreator-for-cross-compilation-with-cmake-in-5-minutes/
- https://code.qt.io/cgit/yocto/meta-boot2qt.git/tree/meta-boot2qt/files/configure-qtcreator.sh
