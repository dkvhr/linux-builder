KERNEL_VERSION=6.9.8
BUSYBOX_VERSION=1.36.1

echo "[+] Copying everything from the src folder to the system home..."
cp src/* busybox-$BUSYBOX_VERSION/initramfs/home/
echo "[+] Generating initramfs..."
cd busybox-$BUSYBOX_VERSION/initramfs
find . -print0 | cpio --null -ov --format=newc > ../initramfs.cpio
gzip ./../initramfs.cpio
cd ../../

echo "[+] Running QEMU..."
qemu-system-x86_64 \
    -m 512M \
    -nographic \
    -kernel linux-$KERNEL_VERSION/arch/x86_64/boot/bzImage \
    -append "console=ttyS0 loglevel=3 oops=panic panic=-1 nopti nokaslr" \
    -no-reboot \
    -cpu qemu64 \
    -smp 1 \
    -monitor /dev/null \
    -initrd busybox-$BUSYBOX_VERSION/initramfs.cpio.gz \
    -net nic,model=virtio \
    -net user \
    -gdb tcp::1234 \
    -S
