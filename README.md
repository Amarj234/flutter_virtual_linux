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
