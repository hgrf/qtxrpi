#!/bin/bash -e
# Credit: https://kitsunemimi.pw/notes/posts/headless-raspberry-pi-os-virtualization-64-bit-edition.html
pkg=$(echo downloads/linux-aarch64-*.pkg.tar.*)
[ -f "$pkg" ]

mkdir initrd; pushd initrd
mkdir bin dev mnt proc sys
tar -xaf "../$pkg" --strip-components=1 usr/lib/modules
rm -rf lib/modules/*/kernel/{sound,drivers/{net/{wireless,ethernet},media,iio,staging,scsi}}
find lib/modules -name '*.zst' -exec zstd -d --rm {} ';'
find lib/modules -name '*.ko' -exec gzip -9 {} ';'
install -p ../build/busybox/busybox bin/busybox
cat >init <<"SCRIPT"
#!/bin/busybox sh
echo --- initramfs ---
set -x
busybox mount -t proc none /proc
busybox mount -t sysfs none /sys
busybox mount -t devtmpfs none /dev

busybox modprobe virtio-net
busybox modprobe bochs
busybox modprobe btintel
busybox modprobe btusb
busybox modprobe bluetooth
busybox modprobe rfcomm

busybox mount -o rw /dev/vda /mnt || exit 1

busybox umount /proc
busybox umount /sys
busybox umount /dev

exec busybox switch_root /mnt /sbin/init
SCRIPT
chmod +x bin/busybox init
bsdtar --format newc --uid 0 --gid 0 -cf - -- * | gzip -9 >../initrd.gz
popd; rm -r initrd
