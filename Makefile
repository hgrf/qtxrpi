.PHONY: docker
docker:
	docker build -t qtxrpi .

.PHONY: sysroot
sysroot:
	docker run --rm -v ${PWD}/sysroot:/sysroot ghcr.io/hgrf/qtxrpi /sysroot/build.sh
	#tar -czvf sysroot0.tar.gz sysroot
	wget -O sysroot/sysroot-relativelinks.py https://raw.githubusercontent.com/abhiTronix/rpi_rootfs/master/scripts/sysroot-relativelinks.py
	chmod +x sysroot/sysroot-relativelinks.py
	sysroot/sysroot-relativelinks.py sysroot
	cd sysroot && \
    	rm -rf usr/include/sys && \
    	ln -s arm-linux-gnueabihf/asm -t usr/include && \
    	ln -s arm-linux-gnueabihf/gnu -t usr/include && \
    	ln -s arm-linux-gnueabihf/bits -t usr/include && \
    	ln -s arm-linux-gnueabihf/sys -t usr/include && \
		ln -s ../arm-linux-gnueabihf/openssl/opensslconf.h -t usr/include/openssl && \
		ln -s arm-linux-gnueabihf/crtn.o usr/lib/crtn.o && \
    	ln -s arm-linux-gnueabihf/crt1.o usr/lib/crt1.o && \
    	ln -s arm-linux-gnueabihf/crti.o usr/lib/crti.o

toolchain:
	wget -O cross-gcc-10.2.0-pi_3+.tar.gz \
		https://sourceforge.net/projects/raspberry-pi-cross-compilers/files/Raspberry%20Pi%20GCC%20Cross-Compiler%20Toolchains/Bullseye/GCC%2010.2.0/Raspberry%20Pi%203A%2B%2C%203B%2B%2C%204/cross-gcc-10.2.0-pi_3%2B.tar.gz
	tar -xvf cross-gcc-10.2.0-pi_3+.tar.gz
	rm cross-gcc-10.2.0-pi_3+.tar.gz

download-qt5:
	wget -O qt-everywhere-opensource-src-5.15.3.tar.xz \
		https://download.qt.io/archive/qt/5.15/5.15.3/single/qt-everywhere-opensource-src-5.15.3.tar.xz
	mkdir qt5
	tar -C qt5 --strip 1 -xvf qt-everywhere-opensource-src-5.15.3.tar.xz
	rm qt-everywhere-opensource-src-5.15.3.tar.xz

patch-qt5:
	cp -R qt5/qtbase/mkspecs/linux-arm-gnueabi-g++ qt5/qtbase/mkspecs/linux-arm-gnueabihf-g++
	sed -i -e 's/arm-linux-gnueabi-/arm-linux-gnueabihf-/g' \
		qt5/qtbase/mkspecs/linux-arm-gnueabihf-g++/qmake.conf
	sed -i '44 a#include <limits>' qt5/qtbase/src/corelib/global/qglobal.h

configure-qt5:
	rm -rf build && mkdir build && \
		cd build && \
		../qt5/configure -v -opengl es2 -eglfs \
			-device linux-rasp-pi4-v3d-g++ \
			-device-option CROSS_COMPILE=${PWD}/cross-pi-gcc-10.2.0-2/bin/arm-linux-gnueabihf- \
			-sysroot ${PWD}/sysroot \
			-opensource -confirm-license -release -nomake tests -nomake examples -no-compile-examples \
			-skip qtwayland -skip qtwebengine -skip qtlocation -skip qtscript \
			-prefix /usr/local/qt5.15 \
			-extprefix ${PWD}/qt5.15 \
			-make libs -pkg-config -recheck \
			-no-use-gold-linker \
			-L${PWD}/sysroot/usr/lib/arm-linux-gnueabihf \
			-I${PWD}/sysroot/usr/include/arm-linux-gnueabihf
