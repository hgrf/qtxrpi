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
