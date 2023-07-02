#!/bin/bash
/run_qemu_nographic.sh &
QEMU_PID=$!

CONN="-o StrictHostKeyChecking=no -p8022 qtxrpi@127.0.0.1"
PASS="qtxrpi"
sshpass -p $PASS ssh $CONN true
while test $? -gt 0; do
    sleep 5
    echo "Trying again..."
    sshpass -p $PASS ssh $CONN true
done

# install dependencies in qemu-rpi virtual machine
sshpass -p $PASS ssh $CONN \
    "sudo apt update && \
    sudo apt install -y build-essential cmake unzip pkg-config gfortran && \
    sudo apt build-dep qt5-qmake libqt5gui5 libqt5webengine-data libqt5webkit5 libudev-dev libinput-dev libts-dev libxcb-xinerama0-dev libxcb-xinerama0 gdbserver && \
    sudo apt install -y libxcb-randr0-dev libxcb-xtest0-dev libxcb-shape0-dev libxcb-xkb-dev && \
    sudo apt install -y libbluetooth-dev && \
    sudo rm -rf /var/lib/apt/lists/*"

if [ $? -gt 0 ]; then
    echo "Failed to install dependencies"
    sshpass -p $PASS ssh $CONN "sudo shutdown now"
    wait $QEMU_PID
    exit 1
fi

# shut down the virtual machine and wait for it to finish
sshpass -p $PASS ssh $CONN "sudo shutdown now"
wait $QEMU_PID
