#!/usr/bin/bash

# This is a script made for building only busybox. It may be useful if
# You don't want to recompile the Linux kernel again (as `build.sh` modifies
# the .config file and it ends up recompiling everything again)

export KERNEL_VERSION=5.10.101
export BUSYBOX_VERSION=1.36.1

echo "[+] Downloading busybox..."
wget -c https://busybox.net/downloads/busybox-$BUSYBOX_VERSION.tar.bz2
[ -e busybox-$BUSYBOX_VERSION ] || tar xjf busybox-$BUSYBOX_VERSION.tar.bz2

echo "[+] Building busybox..."
make -C busybox-$BUSYBOX_VERSION defconfig
#make defconfig
sed -i 's/# CONFIG_STATIC is not set/CONFIG_STATIC=y/g' busybox-$BUSYBOX_VERSION/.config
sed -i 's/CONFIG_TC=y/CONFIG_TC=n/g' busybox-$BUSYBOX_VERSION/.config
cd busybox-$BUSYBOX_VERSION
make -j$(nproc)
make CONFIG_PREFIX=./../busybox_rootfs install
echo "[+] Build OK..."

mkdir -p initramfs/{bin,dev,etc,mnt,proc,sys,usr,tmp}
mkdir -p initramfs/home/user

cat << EOF > initramfs/etc/passwd
root:x:0:0:root:/root:/bin/sh
user:x:1000:1000:User:/home/user:/bin/sh
EOF

cat << EOF > initramfs/etc/group
root:x:0:
user:x:1000:
EOF

cd initramfs/dev
sudo mknod sda b 8 0
sudo mknod console c 5 1

echo "[+] Copying from busybox_rootfs to busybox-$BUSYBOX_VERSION..."
cd ../../../
cp -r busybox_rootfs/* busybox-$BUSYBOX_VERSION/initramfs/

echo "[+] Creating init file on initramfs..."
cd busybox-$BUSYBOX_VERSION/initramfs
echo '#!/bin/sh

mount -t proc none /proc
mount -t sysfs none /sys

/bin/mount -t devtmpfs devtmpfs /dev
chown 0:0 /tmp
chmod 1777 /tmp

exec setsid cttyhack setuidgid 1000 /bin/sh' > init
chmod +x init

chmod 4755 ./bin/su

cd ../../linux-$KERNEL_VERSION
echo "[+] Making modules..."
make -j$(nproc) modules
