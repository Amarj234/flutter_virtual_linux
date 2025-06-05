qemu-system-aarch64 \
  -machine virt \
  -cpu cortex-a72 \
  -m 512 \
  -nographic \
  -drive if=pflash,format=raw,readonly=on,file="/opt/homebrew/Cellar/qemu/10.0.2/share/qemu/edk2-aarch64-code.fd" \
  -cdrom "alpine-virt-3.22.0-aarch64.iso" \
  -drive "file=alpine_disk.img,if=none,id=hd0,format=qcow2" \
  -device "virtio-blk-device,drive=hd0" \
  -serial mon:stdio \
  -boot d






  #!/bin/sh
auto eth0
iface eth0 inet dhcp
echo "nameserver 8.8.8.8" > /etc/resolv.conf

ip link set eth0 up
udhcpc -i eth0

  echo "http://dl-cdn.alpinelinux.org/alpine/v3.22/main" > /etc/apk/repositories,
  echo "http://dl-cdn.alpinelinux.org/alpine/v3.22/community" >> /etc/apk/repositories,
  rc-update add networking default,
