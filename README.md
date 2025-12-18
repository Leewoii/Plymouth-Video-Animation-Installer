# Plymouth Video Animation Installer

A **safe, automated installer** that converts a video (`.mp4`) into an animated Plymouth boot splash and installs it as the system default.

This project is designed for **Ubuntu / Xubuntu (22.04+)**, including **Cubic-based custom ISOs**, and supports both **interactive** and **non-interactive** usage.

---

## Important Warnings (Read First)

* **This modifies the boot splash and rebuilds `initramfs`.**
* **A reboot is required** for changes to appear.
* If something goes wrong, your system may fall back to a black screen or default spinner.

---

## Features

* Convert a video into a Plymouth animation automatically
* Frame extraction and resizing to **1280×720** (safe for early boot)
* Generates a professional `boot.script` dynamically
* Auto-detects frame count
* Supports:

  * Interactive mode (guided)
  * Non-interactive mode (CLI flags)
* Registers theme using `update-alternatives`
* Rebuilds `initramfs`

---

## Dependencies

These **must** be installed before running the script:

```bash
sudo apt update
sudo apt install -y ffmpeg plymouth plymouth-themes
```

### Notes

* `ffmpeg` is required to extract frames from video
* `plymouth` and `plymouth-themes` are required to register and render the theme
* On **Cubic**, installing `ffmpeg` means it will be included in the ISO

---

## Installation

Clone the repository:

```bash
git clone https://github.com/Leewoii/Plymouth-Video-Animation-Installer.git
cd Plymouth-Video-Animation-Installer
chmod +x plymouth_theme.sh
```

Ensure your video file:

* Is `.mp4`
* Is placed inside the `video/` directory
* Only **one video** exists in that directory

---

## Usage

### Way 1 — Interactive Mode

```bash
sudo ./plymouth_theme.sh
```

You will be prompted for:

* Plymouth theme name

Best for manual installs or first-time use.

---

### Way 2 — Non-Interactive Mode (CLI Flags)

```bash
sudo ./plymouth_theme.sh -t Defcomm -d 2
```

**Parameters:**

* `-t` → Theme name
* `-d` → Frame delay (higher = slower animation)

Best for:

* Automation
* CI / build scripts
* Cubic workflows

---

## What the Script Does (High-Level)

1. Validates dependencies
2. Extracts video frames using `ffmpeg`
3. Resizes frames to **1280×720** with letterboxing
4. Generates `boot.script` dynamically
5. Creates a `.plymouth` theme file
6. Registers the theme using `update-alternatives`
7. Rebuilds `initramfs`
8. Reboots the system

---

## Verifying the Active Plymouth Theme

After reboot:

```bash
update-alternatives --display default.plymouth
```

To verify what is embedded at boot:

```bash
lsinitramfs /boot/initrd.img-$(uname -r) | grep plymouth
```

---

## Uninstall / Rollback

To revert to the default spinner or distro logo:

```bash
sudo update-alternatives --config default.plymouth
sudo update-initramfs -u
sudo reboot
```

---

## Compatibility

Tested on:

* Ubuntu 22.04+
* Xubuntu 22.04+
* Cubic custom ISOs

Not tested on:

* Non-Debian systems
* Secure Boot–restricted environments

---

## Author

**Leewoii**
Custom OS Builder • Security & Systems Engineering

---

## Disclaimer

This project modifies low-level boot components. Use at your own risk. The author is not responsible for boot failures or data loss.
