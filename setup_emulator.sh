#!/bin/bash -x
docker run --name qtxrpi -p 127.0.0.1:8022:8022/tcp ghcr.io/hgrf/qemu-rpi4:latest /run_qemu_nographic.sh &
QEMU_PID=$!

OPTS="-o StrictHostKeyChecking=no -p8022"
TARGET="qtxrpi@127.0.0.1"
CONN="$OPTS $TARGET"
PASS="qtxrpi"
sshpass -p $PASS ssh $CONN true
while test $? -gt 0; do
    sleep 5
    echo "Trying again..."
    sshpass -p $PASS ssh $CONN true
done

# install Qt5.15 in qemu-rpi virtual machine#
sshpass -p $PASS ssh $CONN \
    "sudo apt update && \
    sudo apt install -y xorg libqt5gui5 libqt5bluetooth5 && \
    sudo mkdir -p /usr/local && \
    echo /usr/local/qt5.15/lib | sudo tee /etc/ld.so.conf.d/qt5.15.conf && \
    sudo ldconfig"
sshpass -p $PASS rsync -avz -e "ssh $OPTS" --rsync-path="sudo rsync" $1 $TARGET:/usr/local/

# set up autologin
sshpass -p $PASS ssh $CONN \
    "sudo systemctl --quiet set-default multi-user.target && \
    sudo bash -c 'cat > /etc/systemd/system/getty@tty1.service.d/autologin.conf << EOF
[Service]
ExecStart=
ExecStart=-/sbin/agetty --autologin qtxrpi --noclear %I \$TERM
EOF
'"

# set up startx on login
sshpass -p $PASS ssh $CONN \
    "sudo bash -c 'cat > /home/qtxrpi/.profile << EOF
if ! DISPLAY=:0 timeout 1s xset q &>/dev/null; then
    startx
else
    echo \"X is already running :-)\"
fi
EOF
'"

if [ $? -gt 0 ]; then
    echo "Failed to install dependencies"
    sshpass -p $PASS ssh $CONN "sudo shutdown now"
    wait $QEMU_PID
    exit 1
fi

# shut down the virtual machine and wait for it to finish
sshpass -p $PASS ssh $CONN "sudo shutdown now"
wait $QEMU_PID

docker stop qtxrpi
docker commit qtxrpi ghcr.io/hgrf/qtxrpi:latest
