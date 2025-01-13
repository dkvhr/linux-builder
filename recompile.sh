#!/usr/bin/bash

export KERNEL_VERSION=5.10.101

echo "[+] Recompiling the kernel..."
make -C linux-$KERNEL_VERSION -j$(nproc) bzImage

cd linux-$KERNEL_VERSION
echo "[+] Making modules..."
make -j$(nproc) modules
