download:
	wget https://downloads.raspberrypi.org/raspios_lite_armhf/images/raspios_lite_armhf-2023-02-22/2023-02-21-raspios-bullseye-armhf-lite.img.xz
	wget https://github.com/dhruvvyas90/qemu-rpi-kernel/raw/9fb4fcf463df4341dbb7396df127374214b90841/kernel-qemu-5.10.63-bullseye
	wget https://github.com/dhruvvyas90/qemu-rpi-kernel/raw/9fb4fcf463df4341dbb7396df127374214b90841/versatile-pb-bullseye-5.10.63.dtb

unzip:
	xz -d -k -v 2023-02-21-raspios-bullseye-armhf-lite.img.xz

patch:
	# c.f. https://azeria-labs.com/emulate-raspberry-pi-with-qemu/
	fdisk -l 2023-02-21-raspios-bullseye-armhf-lite.img | grep .img2 | (read _ STARTSECTOR _; OFFSET=`expr $$STARTSECTOR \* 512`; \
		mkdir -p mnt && \
		sudo mount -o loop,offset=$$OFFSET 2023-02-21-raspios-bullseye-armhf-lite.img mnt; \
	)
	sudo sed -i -e 's/^/#/' mnt/etc/ld.so.preload
	sudo umount -l mnt

	fdisk -l 2023-02-21-raspios-bullseye-armhf-lite.img | grep .img1 | (read _ STARTSECTOR _; OFFSET=`expr $$STARTSECTOR \* 512`; \
		mkdir -p mnt && \
		sudo mount -o loop,offset=$$OFFSET 2023-02-21-raspios-bullseye-armhf-lite.img mnt; \
	)
	# password: qtxrpi
	sudo bash -c 'echo "qtxrpi:\$$6\$$ilLSZJZDTN1yzr83\$$TYMW.FYa5gZrQd0x4eSU6l.WbC.qhghMSUzy/esGkSVVdBfmqq4ahJ8OjSkBs8IAcmAYQJdoi8aayJQzKTwgy/" > mnt/userconf'
	sudo touch mnt/ssh
	sudo umount -l mnt

run:
	unset GTK_PATH && qemu-system-arm \
		-M versatilepb \
		-cpu arm1176 \
		-kernel ./kernel-qemu-5.10.63-bullseye \
		-append "root=/dev/sda2 rootfstype=ext4 rw" \
		-hda ./2023-02-21-raspios-bullseye-armhf-lite.img \
		-m 256 \
		-dtb ./versatile-pb-bullseye-5.10.63.dtb \
		-serial stdio \
		-no-reboot \
		-net user,hostfwd=tcp::10022-:22 \
		-net nic

raspi4-kernel:
	mkdir -p downloads
	wget -P downloads \
		http://mirror.archlinuxarm.org/aarch64/core/linux-aarch64-6.2.10-1-aarch64.pkg.tar.xz
	tar -xvf downloads/linux-aarch64*.pkg.tar.* --strip-components=1 boot/Image.gz

raspi4-busybox:
	mkdir -p downloads
	wget -O downloads/busybox-1.36.1.tar.bz2 \
		https://busybox.net/downloads/busybox-1.36.1.tar.bz2
	tar -C downloads -xvf downloads/busybox*.tar.*
	mkdir -p build/busybox
	cd downloads/busybox-1.36.1 && \
		make O=../../build/busybox \
			CROSS_COMPILE=../../cross-pi-gcc-10.2.0-2/bin/arm-linux-gnueabihf- defconfig && \
		sed -i 's/# CONFIG_STATIC is not set/CONFIG_STATIC=y/' ../../build/busybox/.config && \
		make O=../../build/busybox \
			CROSS_COMPILE=../../cross-pi-gcc-10.2.0-2/bin/arm-linux-gnueabihf- -j4

raspi4-initrd:
	./build_initramfs.sh

raspi4-rootfs:
	wget -O downloads/2023-02-21-raspios-bullseye-armhf-lite.img.xz \
		https://downloads.raspberrypi.org/raspios_lite_armhf/images/raspios_lite_armhf-2023-02-22/2023-02-21-raspios-bullseye-armhf-lite.img.xz
	cd downloads && xz -d -k -v 2023-02-21-raspios-bullseye-armhf-lite.img.xz
	./build_rootfs.sh

raspi4:
	unset GTK_PATH && \
	sudo qemu-system-aarch64 -M virt												\
		-machine virtualization=true -machine virt,gic-version=3					\
		-cpu max,pauth-impdef=on -smp 4 -m 4096										\
		-object rng-random,filename=/dev/urandom,id=rng0							\
		-device virtio-rng-pci,rng=rng0												\
		-device virtio-net-pci,netdev=net0											\
		-netdev user,id=net0,hostfwd=tcp::8022-:22									\
		-drive if=virtio,format=qcow2,file=./rootfs.qcow2							\
		-kernel Image.gz															\
		-initrd initrd.gz 															\
		-append "earlycon loglevel=6 root=/dev/vda2 rootwait rw console=tty0"		\
		-device qemu-xhci,id=ehci													\
		-device usb-host,bus=ehci.0,hostbus=3,hostaddr=5							\
		-device VGA,vgamem_mb=64													\
		-device usb-mouse															\
		-device usb-kbd

ssh:
	ssh -p8022 qtxrpi@localhost

sync-qt5:
	rsync -avz -e 'ssh -p 8022' --rsync-path="sudo rsync" qt5.15 qtxrpi@localhost:/usr/local
