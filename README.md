# virtual_linux
# Flutter Alpine Linux VM Console

This Flutter app runs an Alpine Linux virtual machine (VM) using QEMU on macOS (Apple Silicon / ARM64).  
It provides a simple terminal console interface to interact with the VM directly from the Flutter UI.

---

## Features

- Boots Alpine Linux VM using QEMU (`qemu-system-aarch64`)
- Extracts required assets (QEMU binary, Alpine disk image, ISO, UEFI firmware) on first run
- Displays VM console output in a scrollable, selectable terminal view
- Sends keyboard input to the VM via a terminal input box
- Supports restarting the VM from the UI
- Automatically configures networking on VM boot via startup script (optional)

---

## Getting Started

   qemu-img create -f qcow2 alpine_disk.img 2G ##  Create a 2GB disk image for Alpine Linux
    wget https://dl-cdn.alpinelinux.org/alpine/v3.22/releases/aarch64/alpine-minirootfs-3.22.0-aarch64.tar.gz

# Download Alpine Linux disk image and ISO

### Prerequisites

- macOS (Apple Silicon preferred)
- Flutter SDK installed
- Homebrew-installed QEMU (recommended)

  ```bash
  brew install qemu


#!/bin/sh
ip link set eth0 up
udhcpc -i eth0
echo "http://dl-cdn.alpinelinux.org/alpine/v3.22/main" > /etc/apk/repositories
echo "http://dl-cdn.alpinelinux.org/alpine/v3.22/community" >> /etc/apk/repositories
rc-update add networking default

Credits
QEMU - Open source machine emulator and virtualizer

Alpine Linux - Lightweight Linux distribution

Flutter team and community
