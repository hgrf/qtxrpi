FROM ghcr.io/hgrf/qemu-rpi-user:v0.1.1

COPY ./setup.sh /opt/qemu-rpi/sysroot/setup.sh
RUN /usr/sbin/chroot /opt/qemu-rpi/sysroot /usr/bin/qemu-aarch64-static /usr/bin/bash /setup.sh
