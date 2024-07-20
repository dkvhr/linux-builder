KERNEL_VERSION=6.9.8

qemu-system-x86_64 \
    -m 512M \
    -nographic \
    -kernel linux-$KERNEL_VERSION/arch/x86_64/boot/bzImage \
    -append "console=ttyS0 loglevel=3 oops=panic panic=-1 nopti nokaslr" \
    -no-reboot \
    -cpu qemu64 \
    -smp 1 \
    -monitor /dev/null \
    -initrd initramfs.cpio.gz \
    -net nic,model=virtio \
    -net user \
    -gdb tcp::1234 \
    -S
