# openSUSE Hyprland Desktop

A minimal, reproducible **openSUSE Tumbleweed + Hyprland + UWSM + DankMaterialShell** desktop bootstrap.

The goal of this project is to provide a clean starting point rather than a finished "rice". The installer handles the system-level setup, while the `config/` directory is intentionally left as a canvas for building the desktop configuration afterwards.

---

## Overview

This installer sets up:

* **openSUSE Tumbleweed**
* **Hyprland**
* **UWSM (Universal Wayland Session Manager)**
* **DankMaterialShell (DMS)**
* **Quickshell**
* **SDDM**
* **PipeWire + WirePlumber**
* **NetworkManager**
* **BlueZ**
* **XDG desktop portals**
* **AMD Vulkan / firmware support**
* A small collection of desktop applications and utilities

The intended session flow is:

```text
SDDM
 │
 ▼
Hyprland (UWSM-managed)
 │
 ▼
UWSM
 │
 ├── Hyprland
 ├── graphical-session.target
 └── user services
      │
      ▼
 DankMaterialShell
```

Hyprland's UWSM session is provided through:

```text
/usr/share/wayland-sessions/hyprland-uwsm.desktop
```

The installer does not create its own Hyprland systemd session target.

---

## What This Project Is

This is a **bootstrap installer**, not a complete desktop configuration.

It establishes the foundation needed for a Hyprland desktop and leaves the actual customization to the configuration layer.

That means things such as:

* keybinds
* monitor configuration
* window rules
* wallpapers
* themes
* fonts
* DMS customization
* animations
* appearance
* application preferences

can be developed separately under `config/`.

The intention is to keep the installer maintainable and avoid coupling system installation with personal configuration.

---

## Desktop Philosophy

The setup deliberately avoids installing multiple applications that provide the same desktop functionality.

### DankMaterialShell provides

* status bar
* launcher
* notifications
* lock screen
* idle/session handling
* power controls
* Wi-Fi controls
* Bluetooth controls
* desktop shell functionality

Because of this, the setup does **not** intentionally build a stack around:

* Waybar
* Rofi
* SwayNC
* Hyprlock
* Hypridle
* NetworkManager applet
* Blueman
* Wlogout

The underlying services remain installed where appropriate.

For example:

```text
NetworkManager
    ↓
DMS Wi-Fi UI

BlueZ
    ↓
DMS Bluetooth UI

PipeWire
    ↓
DMS audio controls

systemd / logind
    ↓
DMS power/session controls
```

This keeps the desktop layer relatively small while retaining the normal Linux backend services.

---

## Repository Structure

```text
opensuse-hyprland/
├── install.sh
│
├── scripts/
│   ├── 00-preflight.sh
│   ├── 01-repos.sh
│   ├── 02-packages.sh
│   ├── 03-sddm.sh
│   ├── 04-session.sh
│   ├── 05-dms.sh
│   └── 99-verify.sh
│
├── config/
│   └── ...
│
└── README.md
```

### Installer stages

| Stage             | Purpose                                     |
| ----------------- | ------------------------------------------- |
| `00-preflight.sh` | Validate the system before making changes   |
| `01-repos.sh`     | Configure required openSUSE repositories    |
| `02-packages.sh`  | Install the desktop and supporting packages |
| `03-sddm.sh`      | Configure and enable SDDM                   |
| `04-session.sh`   | Verify the Hyprland UWSM session            |
| `05-dms.sh`       | Configure DankMaterialShell                 |
| `99-verify.sh`    | Perform final installation checks           |

---

## Requirements

The installer currently targets:

* **openSUSE Tumbleweed**
* **x86_64**
* a normal non-root user
* `sudo`
* an active internet connection

The installer intentionally refuses to run as root.

Run it as your normal user.

---

## Installation

Clone the repository:

```bash
git clone <repository-url>
cd opensuse-hyprland
```

Make sure the installer is executable:

```bash
chmod +x install.sh
```

Run:

```bash
./install.sh
```

The installer will:

1. perform preflight checks
2. configure repositories
3. install required packages
4. configure SDDM
5. verify the UWSM Hyprland session
6. configure DankMaterialShell
7. perform final verification

A log is created in the repository directory:

```text
install-YYYYMMDD-HHMMSS.log
```

---

## Optional Packages

The default installation focuses on the desktop foundation.

Optional packages can be installed with:

```bash
INSTALL_OPTIONAL=1 ./install.sh
```

These include additional tools such as:

* Neovim
* ripgrep
* eza
* fzf
* fd
* btop
* fastfetch
* tmux
* C/C++ development tools
* Rust tooling
* build systems
* `opi`
* `cmatrix`

Optional packages are deliberately kept separate from the baseline installation.

---

## Package Groups

The installer separates packages into three groups.

### Core

The core group contains the components required for the desktop foundation:

```text
Hyprland
UWSM
Quickshell
DankMaterialShell
SDDM
XWayland
XDG desktop portals
PipeWire
WirePlumber
NetworkManager
BlueZ
power-profiles-daemon
AMD Vulkan / firmware support
basic shell and archive/network tools
```

### Extra

The extra group contains desktop applications, visual utilities and quality-of-life components:

```text
Dolphin
Gwenview
Ark
KDE Framework integration
GTK/Qt theming support
wallpaper backend
CAVA
brightnessctl
playerctl
screenshots / recording tools
fonts
zram-generator
fwupd
Flatpak
```

### Optional

The optional group contains development and terminal utilities that aren't required for the desktop itself.

---

## Repositories

The installer configures the repositories required for the selected packages:

```text
X11:Wayland
home:AvengeMedia:danklinux
home:AvengeMedia:dms
```

Repository metadata is refreshed before package installation.

---

## SDDM

SDDM is used as the display manager.

The installer creates:

```text
/etc/sddm.conf.d/10-hyprland.conf
```

with:

```ini
[General]
DisplayServer=wayland
```

SDDM is then enabled through systemd.

---

## Hyprland + UWSM

The installer expects Hyprland to provide:

```text
/usr/share/wayland-sessions/hyprland-uwsm.desktop
```

This is the UWSM-managed Hyprland session exposed to the display manager.

After rebooting, select the Hyprland UWSM session from SDDM.

UWSM handles the compositor session and systemd integration.

The installer does **not** manually create:

```text
hyprland-session.target
```

and does not manually start it.

Current Hyprland integrates its session target automatically, while UWSM starts `graphical-session.target` for the managed graphical session.

---

## DankMaterialShell

DMS is configured using its headless setup mode:

```bash
dms setup headless \
    --compositor hyprland \
    --terminal kitty \
    --skip-existing
```

This is intended for automated installations and avoids interactive setup during the bootstrap process.

The installer also creates:

```text
~/.config/environment.d/90-dms.conf
```

containing:

```ini
QT_QPA_PLATFORM=wayland
QT_QPA_PLATFORMTHEME=gtk3
ELECTRON_OZONE_PLATFORM_HINT=auto
TERMINAL=kitty
```

DMS's Hyprland integration is expected under:

```text
~/.config/hypr/dms/
```

---

## Verification

The final verification stage checks:

### Programs

```text
Hyprland
uwsm
dms
quickshell
kitty
sddm
systemctl
```

### SDDM

* configuration exists
* Wayland greeter is configured
* SDDM is enabled

### UWSM

* `hyprland-uwsm.desktop` exists
* the session entry uses UWSM

### DMS

* environment configuration exists
* expected environment variables are present
* DMS Hyprland configuration exists

### Backend services

The installer verifies that the following service units are installed:

```text
NetworkManager.service
bluetooth.service
pipewire.service
pipewire-pulse.service
wireplumber.service
```

Some user-systemd checks may produce warnings during installation because the installer is normally running outside the newly-created graphical session. These warnings are not treated as installation failures.

---

## After Installation

Once the installer completes:

```text
1. Reboot
2. SDDM appears
3. Select the Hyprland UWSM session
4. Log in
5. DMS starts with the session
```

The first reboot is recommended because the installer is configuring a new graphical session and user environment.

---

## Configuration

The `config/` directory is intentionally kept separate from the installer.

The long-term goal is to build the desktop configuration incrementally rather than ship a pre-made rice.

Possible future configuration areas include:

```text
config/
├── hypr/
├── dms/
├── uwsm/
├── kitty/
├── qt/
├── gtk/
└── ...
```

These should be added only as the configuration actually develops.

---

## Design Principles

### 1. Reproducible

A fresh Tumbleweed installation should be able to bootstrap the same desktop foundation by cloning the repository and running:

```bash
./install.sh
```

### 2. Idempotent where practical

Existing repositories and configuration should not unnecessarily be recreated.

DMS setup uses:

```text
--skip-existing
```

to avoid overwriting existing configuration.

### 3. Fail early

The installer uses:

```bash
set -euo pipefail
```

and performs preflight validation before making system changes.

### 4. Clear separation of responsibilities

```text
install.sh
    ↓
installer stages
    ↓
system foundation
    ↓
desktop session
    ↓
configuration
```

The installer should establish the platform; the configuration should define the user's desktop.

### 5. Avoid unnecessary duplication

If DMS already provides a desktop-shell feature, another program should not be installed simply to provide the same feature.

---

## Recovery

The installer is designed to stop when a required stage fails.

Every installation creates a timestamped log:

```text
install-YYYYMMDD-HHMMSS.log
```

If something goes wrong, inspect the log first.

Because the installer modifies system packages, repositories and SDDM configuration, it is recommended to have a working system snapshot/backup strategy before performing a major system bootstrap.

---

## Important Notes

This project currently targets **openSUSE Tumbleweed only**.

It is not intended to be a universal Linux installer.

The package selection also assumes an **AMD graphics environment** for the Vulkan/firmware packages included in the baseline.

Hardware-specific configuration may need to be added later for systems using different GPU hardware.

---

## Current Status

The bootstrap currently provides:

```text
[✓] Preflight checks
[✓] Repository setup
[✓] Core package installation
[✓] Extra package installation
[✓] Optional package support
[✓] SDDM configuration
[✓] Hyprland UWSM session
[✓] DankMaterialShell setup
[✓] Final verification
[ ] Personal Hyprland configuration
[ ] Personal DMS configuration
[ ] Final desktop theming
```

The installer is intentionally considered the **foundation** of the project.

The actual desktop configuration will be developed separately.