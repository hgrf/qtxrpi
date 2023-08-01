QTXRPI_PATH := /opt/qtxrpi

.PHONY: docker
docker:
	docker build -t qtxrpi .

.PHONY: sysroot
sysroot:
	mkdir -p $(QTXRPI_PATH)/sysroot
	if [ ! -f "$(QTXRPI_PATH)/sysroot/build.sh" ]; then cp sysroot/build.sh $(QTXRPI_PATH)/sysroot/build.sh; fi
	docker run --rm -v $(QTXRPI_PATH)/sysroot:/sysroot qtxrpi /sysroot/build.sh
	sudo chown -R ${USER} $(QTXRPI_PATH)/sysroot
	ls -la $(QTXRPI_PATH)/sysroot
	wget -O $(QTXRPI_PATH)/sysroot/sysroot-relativelinks.py https://raw.githubusercontent.com/abhiTronix/rpi_rootfs/master/scripts/sysroot-relativelinks.py
	chmod +x $(QTXRPI_PATH)/sysroot/sysroot-relativelinks.py
	$(QTXRPI_PATH)/sysroot/sysroot-relativelinks.py $(QTXRPI_PATH)/sysroot
	cd $(QTXRPI_PATH)/sysroot && \
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
	mkdir -p $(QTXRPI_PATH)
	wget -O cross-gcc-10.2.0-pi_3+.tar.gz \
		https://sourceforge.net/projects/raspberry-pi-cross-compilers/files/Raspberry%20Pi%20GCC%20Cross-Compiler%20Toolchains/Bullseye/GCC%2010.2.0/Raspberry%20Pi%203A%2B%2C%203B%2B%2C%204/cross-gcc-10.2.0-pi_3%2B.tar.gz
	tar -C $(QTXRPI_PATH) -xvf cross-gcc-10.2.0-pi_3+.tar.gz
	rm cross-gcc-10.2.0-pi_3+.tar.gz

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
	cp -R qt5/qtbase/mkspecs/linux-arm-gnueabi-g++ qt5/qtbase/mkspecs/linux-arm-gnueabihf-g++
	sed -i -e 's/arm-linux-gnueabi-/arm-linux-gnueabihf-/g' \
		qt5/qtbase/mkspecs/linux-arm-gnueabihf-g++/qmake.conf
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
			-device-option CROSS_COMPILE=$(QTXRPI_PATH)/cross-pi-gcc-10.2.0-2/bin/arm-linux-gnueabihf- \
			-sysroot $(QTXRPI_PATH)/sysroot \
			-opensource -confirm-license -release -nomake tests -nomake examples -no-compile-examples \
			-skip qtwayland -skip qtwebengine -skip qtlocation -skip qtscript \
			-prefix /usr/local/qt5.15 \
			-extprefix $(QTXRPI_PATH)/qt5.15 \
			-make libs -pkg-config -recheck \
			-no-use-gold-linker \
			-L$(QTXRPI_PATH)/sysroot/usr/lib/arm-linux-gnueabihf \
			-I$(QTXRPI_PATH)/sysroot/usr/include/arm-linux-gnueabihf

build-qt5:
	cd build && make -j4
	cd build && make install

archive:
	tar cvzf qt5.15.tar.gz $(QTXRPI_PATH)/qt5.15
	tar cvzf sysroot.tar.gz $(QTXRPI_PATH)/sysroot

emulator:
	sudo ./setup_emulator.sh $(QTXRPI_PATH)/qt5.15

run-emulator:
	sudo docker run \
		--rm -it \
		-p 127.0.0.1:8022:8022/tcp \
		-e DISPLAY \
		-v /tmp/.X11-unix:/tmp/.X11-unix \
		ghcr.io/hgrf/qtxrpi:latest \
		/run_qemu.sh
		
install:
	make toolchain
	# TODO: store version externally
	wget -O - "https://github.com/hgrf/qtxrpi/releases/download/v5.15.3-1/sysroot.tar.gz" | tar -C / -xz
	wget -O - "https://github.com/hgrf/qtxrpi/releases/download/v5.15.3-1/qt5.15.tar.gz" | tar -C / -xz
