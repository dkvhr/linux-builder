#!/usr/bin/bash

export KERNEL_VERSION=5.16.11

echo "[+] Downloading kernel..."
wget -c https://mirrors.edge.kernel.org/pub/linux/kernel/v5.x/linux-$KERNEL_VERSION.tar.gz
[ -e linux-$KERNEL_VERSION ] || tar xzvf linux-$KERNEL_VERSION.tar.gz

echo "[+] Generating config files..."
make -C linux-$KERNEL_VERSION defconfig

#echo "CONFIG_GDB_SCRIPTS=y" >> linux-$KERNEL_VERSION/.config
#echo "CONFIG_DEBUG_INFO_REDUCED=n" >> linux-$KERNEL_VERSION/.config
#echo "CONFIG_DEBUG_INFO_COMPRESSED_NONE=y" >> linux-$KERNEL_VERSION/.config
#echo "CONFIG_DEBUG_INFO_SPLIT=n" >> linux-$KERNEL_VERSION/.config

#sed -i 's/CONFIG_DEBUG_INFO_NONE=y/# CONFIG_DEBUG_INFO_NONE is not set/g' linux-$KERNEL_VERSION/.config
sed -i 's/# CONFIG_DEBUG_INFO_DWARF5 is not set/CONFIG_DEBUG_INFO_DWARF5=y\n# CONFIG_DEBUG_INFO_REDUCED is not set\nCONFIG_DEBUG_INFO_COMPRESSED_NONE=y\n# C
ONFIG_DEBUG_INFO_COMPRESSED_ZLIB is not set\n# CONFIG_DEBUG_INFO_SPLIT is not set\nCONFIG_GDB_SCRIPTS=y/g' linux-$KERNEL_VERSION/.config

sed -i 'N;s/WARN("missing symbol table");\n\t\treturn -1;/\n\t\treturn 0;\n\t\t\/\/ A missing symbol table is actually possible if its an empty .o file.  Th
is can happen for thunk_64.o./g' linux-$KERNEL_VERSION/tools/objtool/elf.c

sed -i 's/unsigned long __force_order/\/\/ unsigned long __force_order/g' linux-$KERNEL_VERSION/arch/x86/boot/compressed/pgtable_64.c

echo "[+] Building the kernel..."
make -C linux-$KERNEL_VERSION -j$(nproc) bzImage

cd ../../linux-$KERNEL_VERSION
echo "[+] Making modules..."
make -j$(nproc) modules
