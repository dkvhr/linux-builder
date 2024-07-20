export KERNEL_VERSION=6.9.8
export BUSYBOX_VERSION=1.36.1

echo "[+] Downloading kernel..."
wget -c https://mirrors.edge.kernel.org/pub/linux/kernel/v6.x/linux-$KERNEL_VERSION.tar.gz
[ -e linux-$KERNEL_VERSION ] || tar xzf linux-$KERNEL_VERSION.tar.gz

echo "[+] Generating config files..."
make -C linux-$KERNEL_VERSION defconfig

echo "CONFIG_VIRTIO_BLK_SCSI=y" >> linux-$KERNEL_VERSION/.config
echo "CONFIG_BALLOON_COMPACTION=y" >> linux-$KERNEL_VERSION/.config
echo "CONFIG_PCI_HOST_GENERIC=y" >> linux-$KERNEL_VERSION/.config
echo "CONFIG_GDB_SCRIPTS=y" >> linux-$KERNEL_VERSION/.config
echo "CONFIG_DEBUG_INFO=y" >> linux-$KERNEL_VERSION/.config
echo "CONFIG_DEBUG_INFO_REDUCED=n" >> linux-$KERNEL_VERSION/.config
echo "CONFIG_DEBUG_INFO_COMPRESSED_NONE=y" >> linux-$KERNEL_VERSION/.config
echo "CONFIG_DEBUG_INFO_SPLIT=n" >> linux-$KERNEL_VERSION/.config
echo "CONFIG_DEBUG_INFO_BTF=y" >> linux-$KERNEL_VERSION/.config
echo "CONFIG_FRAME_POINTER=y" >> linux-$KERNEL_VERSION/.config
echo "# CONFIG_TC is not set" >> linux-$KERNEL_VERSION/.config

sed -i 's/# CONFIG_9P_FS_POSIX_ACL is not set/CONFIG_9P_FS_POSIX_ACL=y/g' linux-$KERNEL_VERSION/.config
sed -i 's/# CONFIG_9P_FS_SECURITY is not set/CONFIG_9P_FS_SECURITY=y/g' linux-$KERNEL_VERSION/.config
sed -i 's/# CONFIG_HW_RANDOM_VIRTIO is not set/CONFIG_HW_RANDOM_VIRTIO=y/g' linux-$KERNEL_VERSION/.config
sed -i 's/# CONFIG_VIRTIO_BALLOON is not set/CONFIG_VIRTIO_BALLOON=y/g' linux-$KERNEL_VERSION/.config
sed -i 's/# CONFIG_CRYPTO_DEV_VIRTIO is not set/CONFIG_CRYPTO_DEV_VIRTIO=y/g' linux-$KERNEL_VERSION/.config
sed -i 's/CONFIG_DEBUG_INFO_NONE=y/CONFIG_DEBUG_INFO_NONE=n/g' linux-$KERNEL_VERSION/.config
sed -i 's/# CONFIG_DEBUG_INFO_DWARF5 is not set/CONFIG_DEBUG_INFO_DWARF5=y/g' linux-$KERNEL_VERSION/.config

sed -i 'N;s/WARN("missing symbol table");\n\t\treturn -1;/\n\t\treturn 0;\n\t\t\/\/ A missing symbol table is actually possible if its an empty .o file.  This can happen for thunk_64.o./g' linux-$KERNEL_VERSION/tools/objtool/elf.c

sed -i 's/unsigned long __force_order/\/\/ unsigned long __force_order/g' linux-$KERNEL_VERSION/arch/x86/boot/compressed/pgtable_64.c

make -C linux-$KERNEL_VERSION olddefconfig

echo "[+] Building the kernel..."
make -C linux-$KERNEL_VERSION -j$(nproc) bzImage

echo "[+] Downloading busybox..."
wget -c https://busybox.net/downloads/busybox-$BUSYBOX_VERSION.tar.bz2
[ -e busybox-$BUSYBOX_VERSION ] || tar xjf busybox-$BUSYBOX_VERSION.tar.bz2

echo "[+] Building busybox..."
cd busybox-$BUSYBOX_VERSION
make defconfig
sed -i 's/# CONFIG_STATIC is not set/CONFIG_STATIC=y/g' .config
make -j$(nproc)
make CONFIG_PREFIX=./../busybox_rootfs install

mkdir -p initramfs/{bin,dev,etc,home,mnt,proc,sys,usr,tmp}
cd initramfs/dev
sudo mknod sda b 8 0
sudo mknod console c 5 1

cd ../
cp -r ../../../busybox_rootfs/* .

echo '#!/bin/sh

mount -t proc none /proc
mount -t sysfs none /sys

/bin/mount -t devtmpfs devtmpfs /dev
chown 1337:1337 /tmp

setsid cttyhack setuidgid 1337 sh

exec /bin/sh' > init
chmod +x init
find . -print0 | cpio --null -ov --format=newc > initramfs.cpio
gzip ./initramfs.cpio

