#!/bin/bash -e
input=downloads/2023-02-21-raspios-bullseye-armhf-lite.img
[ -f $input ]

mkdir -p mnt
cp --reflink=auto $input source.img
truncate -s 10G source.img
echo ", +" | sfdisk -N 2 source.img
dev=$(sudo losetup -fP --show source.img)
[ -n "$dev" ]
sudo resize2fs ${dev}p2
sudo mount ${dev}p2 ./mnt -o rw
sudo sed '/^PARTUUID/d' -i ./mnt/etc/fstab
#sudo sed '/^root:/ s|\*||' -i ./mnt/etc/shadow
remove_services=rpi-eeprom-update,hciuart,dphys-swapfile
sudo bash -c "rm -f \
        ./mnt/etc/systemd/system/multi-user.target.wants/{$remove_services}.service \
        ./mnt/etc/rc?.d/?01{$remove_services}"
# password: qtxrpi
sudo bash -c 'echo "qtxrpi:\$6\$ilLSZJZDTN1yzr83\$TYMW.FYa5gZrQd0x4eSU6l.WbC.qhghMSUzy/esGkSVVdBfmqq4ahJ8OjSkBs8IAcmAYQJdoi8aayJQzKTwgy/" > mnt/boot/userconf'
sudo touch mnt/boot/ssh
sudo umount ./mnt
sudo chmod a+r ${dev}p2
qemu-img convert -O qcow2 ${dev}p2 rootfs.qcow2
sudo losetup -d $dev
rm source.img; rmdir mnt
