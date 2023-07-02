FROM ghcr.io/hgrf/qemu-rpi4:latest

COPY ./setup.sh /setup.sh
RUN /setup.sh
