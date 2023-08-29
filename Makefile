QTXRPI_PATH := /opt/qtxrpi

.PHONY: docker
docker:
	docker run --name qtxrpi -t --privileged \
		-v ${PWD}:/opt/qemu-rpi/sysroot/mnt \
		ghcr.io/hgrf/qemu-rpi-user:v0.1.3 \
		chroot-helper.sh -ex /mnt/setup.sh
	docker commit qtxrpi qtxrpi
	docker rm qtxrpi

.PHONY: sysroot
sysroot:
	mkdir -p $(QTXRPI_PATH)/sysroot
	if [ ! -f "$(QTXRPI_PATH)/sysroot/build.sh" ]; then cp sysroot/build.sh $(QTXRPI_PATH)/sysroot/build.sh; fi
	docker run --rm --privileged -v $(QTXRPI_PATH)/sysroot:/opt/qemu-rpi/sysroot/sysroot qtxrpi chroot-helper.sh /sysroot/build.sh
	sudo chown -R ${USER} $(QTXRPI_PATH)/sysroot
	ls -la $(QTXRPI_PATH)/sysroot
	wget -O $(QTXRPI_PATH)/sysroot/sysroot-relativelinks.py https://raw.githubusercontent.com/abhiTronix/rpi_rootfs/master/scripts/sysroot-relativelinks.py
	chmod +x $(QTXRPI_PATH)/sysroot/sysroot-relativelinks.py
	$(QTXRPI_PATH)/sysroot/sysroot-relativelinks.py $(QTXRPI_PATH)/sysroot
	cd $(QTXRPI_PATH)/sysroot && \
    	rm -rf usr/include/sys && \
    	ln -s aarch64-linux-gnu/asm -t usr/include && \
    	ln -s aarch64-linux-gnu/gnu -t usr/include && \
    	ln -s aarch64-linux-gnu/bits -t usr/include && \
    	ln -s aarch64-linux-gnu/sys -t usr/include && \
		ln -s ../aarch64-linux-gnu/openssl/opensslconf.h -t usr/include/openssl && \
		ln -s aarch64-linux-gnu/crtn.o usr/lib/crtn.o && \
    	ln -s aarch64-linux-gnu/crt1.o usr/lib/crt1.o && \
    	ln -s aarch64-linux-gnu/crti.o usr/lib/crti.o

toolchain:
	mkdir -p $(QTXRPI_PATH)
	wget -O cross-gcc-10.2.0-pi_64.tar.gz \
		https://sourceforge.net/projects/raspberry-pi-cross-compilers/files/Bonus%20Raspberry%20Pi%20GCC%2064-Bit%20Toolchains/Raspberry%20Pi%20GCC%2064-Bit%20Cross-Compiler%20Toolchains/Bullseye/GCC%2010.2.0/cross-gcc-10.2.0-pi_64.tar.gz
	tar -C $(QTXRPI_PATH) -xvf cross-gcc-10.2.0-pi_64.tar.gz
	rm cross-gcc-10.2.0-pi_64.tar.gz

download-qt5:
	wget -O qt-everywhere-opensource-src-5.15.3.tar.xz \
		https://download.qt.io/archive/qt/5.15/5.15.3/single/qt-everywhere-opensource-src-5.15.3.tar.xz
	mkdir qt5
	tar -C qt5 --strip 1 -xvf qt-everywhere-opensource-src-5.15.3.tar.xz
	rm qt-everywhere-opensource-src-5.15.3.tar.xz

# c.f. https://forum.qt.io/topic/88588/qtbase-compilation-error-with-device-linux-rasp-pi3-g-qeglfskmsgbmwindow-cpp/9
define EGL_PLATFORM_PATCH
typedef uint32_t DISPMANX_ELEMENT_HANDLE_T;
typedef struct {
	DISPMANX_ELEMENT_HANDLE_T element;
	int width;
	int height;
} EGL_DISPMANX_WINDOW_T;

#endif /* __eglplatform_h */
endef

export EGL_PLATFORM_PATCH
patch-qt5:
	sed -i -e 's/-mfpu=crypto-neon-fp-armv8//g' qt5/qtbase/mkspecs/devices/linux-rasp-pi4-v3d-g++/qmake.conf
	sed -i '33d' qt5/qtbase/mkspecs/devices/linux-rasp-pi4-v3d-g++/qmake.conf
	sed -i -e 's/linux_arm_device_post.conf/linux_device_post.conf/g' qt5/qtbase/mkspecs/devices/linux-rasp-pi4-v3d-g++/qmake.conf
	sed -i '44 a#include <limits>' qt5/qtbase/src/corelib/global/qglobal.h
	sed -i '182d' $(QTXRPI_PATH)/sysroot/usr/include/EGL/eglplatform.h
	echo "$$EGL_PLATFORM_PATCH" >> $(QTXRPI_PATH)/sysroot/usr/include/EGL/eglplatform.h
	sed -i -e 's/return eglWindow/return \(EGLNativeWindowType\)eglWindow/g' \
		qt5/qtbase/src/plugins/platforms/eglfs/deviceintegration/eglfs_brcm/qeglfsbrcmintegration.cpp
	sed -i -e 's/static_cast<EGL_DISPMANX_WINDOW_T/reinterpret_cast<EGL_DISPMANX_WINDOW_T/g' \
		qt5/qtbase/src/plugins/platforms/eglfs/deviceintegration/eglfs_brcm/qeglfsbrcmintegration.cpp

configure-qt5:
	rm -rf build && mkdir build && \
		cd build && \
		QTXRPI_PATH=/opt/qtxrpi ../qt5/configure -v -opengl es2 -eglfs \
			-device linux-rasp-pi4-v3d-g++ \
			-device-option CROSS_COMPILE=$(QTXRPI_PATH)/cross-pi-gcc-10.2.0-64/bin/aarch64-linux-gnu- \
			-sysroot $(QTXRPI_PATH)/sysroot \
			-opensource -confirm-license -release -nomake tests -nomake examples -no-compile-examples \
			-skip qtwayland -skip qtwebengine -skip qtlocation -skip qtscript \
			-prefix /usr/local/qt5.15 \
			-extprefix $(QTXRPI_PATH)/qt5.15 \
			-make libs -pkg-config -recheck \
			-no-use-gold-linker \
			-L$(QTXRPI_PATH)/sysroot/usr/lib/aarch64-linux-gnu \
			-I$(QTXRPI_PATH)/sysroot/usr/include/aarch64-linux-gnu

build-qt5:
	cd build && make -j4
	cd build && make install

archive:
	tar cvzf qt5.15.tar.gz $(QTXRPI_PATH)/qt5.15
	tar cvzf sysroot.tar.gz $(QTXRPI_PATH)/sysroot

emulator:
	docker run --privileged \
		--name qtxrpi \
		-v ${PWD}:/opt/qemu-rpi/sysroot/mnt \
		ghcr.io/hgrf/qemu-rpi-user:v0.1.4 \
		chroot-helper.sh -ex /mnt/setup_emulator.sh
	docker commit qtxrpi ghcr.io/hgrf/qtxrpi:latest
	docker rm qtxrpi

run-emulator:
	xhost +
	docker run --rm -itd --privileged \
		-p 127.0.0.1:8022:22/tcp \
		-p 127.0.0.1:10000:10000/tcp \
		-e DISPLAY \
		-v $(QTXRPI_PATH)/qt5.15:/opt/qemu-rpi/sysroot/usr/local/qt5.15 \
		-v /tmp/.X11-unix:/opt/qemu-rpi/sysroot/tmp/.X11-unix \
		ghcr.io/hgrf/qtxrpi:latest \
		chroot-helper.sh \
		entrypoint.sh
		
install:
	make toolchain
	# TODO: store version externally
	wget -O - "https://github.com/hgrf/qtxrpi/releases/download/v5.15.3-3/sysroot.tar.gz" | tar -C / -xz
	wget -O - "https://github.com/hgrf/qtxrpi/releases/download/v5.15.3-3/qt5.15.tar.gz" | tar -C / -xz
	mkdir -p $(QTXRPI_PATH)/sysroot/usr/local
	ln -s $(QTXRPI_PATH)/qt5.15 $(QTXRPI_PATH)/sysroot/usr/local/qt5.15
	docker pull ghcr.io/hgrf/qtxrpi:v5.15.3-3
