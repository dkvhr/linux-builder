export KERNEL_VERSION=6.8
export BUSYBOX_VERSION=1.36.1

echo "[+] Downloading kernel..."
wget -c https://mirrors.edge.kernel.org/pub/linux/kernel/v6.x/linux-$KERNEL_VERSION.tar.gz
[ -e linux-$KERNEL_VERSION ] || tar xzf linux-$KERNEL_VERSION.tar.gz

echo "[+] Generating config files..."
make -C linux-$KERNEL_VERSION defconfig

#echo "CONFIG_GDB_SCRIPTS=y" >> linux-$KERNEL_VERSION/.config
#echo "CONFIG_DEBUG_INFO_REDUCED=n" >> linux-$KERNEL_VERSION/.config
#echo "CONFIG_DEBUG_INFO_COMPRESSED_NONE=y" >> linux-$KERNEL_VERSION/.config
#echo "CONFIG_DEBUG_INFO_SPLIT=n" >> linux-$KERNEL_VERSION/.config

sed -i 's/CONFIG_DEBUG_INFO_NONE=y/# CONFIG_DEBUG_INFO_NONE is not set/g' linux-$KERNEL_VERSION/.config
sed -i 's/# CONFIG_DEBUG_INFO_DWARF5 is not set/CONFIG_DEBUG_INFO_DWARF5=y\n# CONFIG_DEBUG_INFO_REDUCED is not set\nCONFIG_DEBUG_INFO_COMPRESSED_NONE=y\n# CONFIG_DEBUG_INFO_COMPRESSED_ZLIB is not set\n# CONFIG_DEBUG_INFO_SPLIT is not set\nCONFIG_GDB_SCRIPTS=y/g' linux-$KERNEL_VERSION/.config

sed -i 'N;s/WARN("missing symbol table");\n\t\treturn -1;/\n\t\treturn 0;\n\t\t\/\/ A missing symbol table is actually possible if its an empty .o file.  This can happen for thunk_64.o./g' linux-$KERNEL_VERSION/tools/objtool/elf.c

sed -i 's/unsigned long __force_order/\/\/ unsigned long __force_order/g' linux-$KERNEL_VERSION/arch/x86/boot/compressed/pgtable_64.c

echo "[+] Building the kernel..."
make -C linux-$KERNEL_VERSION -j$(nproc) bzImage

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

mkdir -p initramfs/{bin,dev,etc,home,mnt,proc,sys,usr,tmp}
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

setsid cttyhack setuidgid 0 sh

exec /bin/sh' > init
chmod +x init

cd ../../linux-$KERNEL_VERSION
make -j$(nproc) modules