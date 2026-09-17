# Hyprland-Canvas

A minimal, reproducible **openSUSE Tumbleweed + Hyprland + UWSM + DankMaterialShell** desktop bootstrap.

This project is intentionally **not a finished rice**. It provides a clean, functional system foundation and leaves `config/` as a blank canvas for building your own Hyprland and DankMaterialShell configuration.

---

## What this installs

The bootstrap sets up:

* openSUSE Tumbleweed
* Hyprland
* UWSM
* DankMaterialShell (DMS)
* Quickshell
* SDDM
* Kitty
* Zsh
* Oh My Zsh
* Powerlevel10k
* Annotation Mono Nerd Font
* PipeWire + WirePlumber
* NetworkManager
* BlueZ
* Power Profiles Daemon
* zram
* XDG user directories
* Cargo tools
* Wayland/XDG desktop integration
* AMD graphics/Vulkan support
* Flatpak + Flathub
* Optional HyprMod integration

DMS provides the desktop shell layer, including the bar, launcher, notifications, session/lock functionality, and system controls. DMS is designed to replace the collection of traditional components normally used for these functions.

This project therefore **does not intentionally install redundant components such as**:

* Waybar
* Rofi
* SwayNC
* Hyprlock
* Hypridle
* Wlogout
* NetworkManager applet
* Blueman

Backend services such as NetworkManager, BlueZ, PipeWire, and systemd remain installed because DMS uses them for system integration.

---

## Philosophy

Hyprland-Canvas is designed around a few principles:

### Minimal foundation

The installer should provide the system components needed for a usable Hyprland desktop without turning the repository into a pre-made dotfiles collection.

### Reproducibility

Installation is divided into small, ordered stages rather than one large script.

Each stage has one responsibility and can be inspected independently.

### Safe reruns

Stages should avoid unnecessarily overwriting existing user configuration.

### Optional by design

Optional packages and components are controlled from the main installer rather than prompting independently in multiple stages.

Core desktop infrastructure is installed regardless of the optional-component selection.

### Blank canvas

The repository is a **bootstrap**, not a rice.

The `config/` directory is intentionally left available for future Hyprland/DMS configuration.

---

# Repository structure

```text
Hyprland-Canvas/
├── install.sh
│
├── scripts/
│   ├── common.sh
│   ├── 00-preflight.sh
│   ├── 01-repos.sh
│   ├── 02-snapshot.sh
│   ├── 03-packages.sh
│   ├── 04-sddm.sh
│   ├── 05-dms.sh
│   ├── 06-session.sh
│   ├── 07-services.sh
│   ├── 08-zram.sh
│   ├── 09-user_dirs.sh
│   ├── 10-cargos.sh
│   ├── 11-shell.sh
│   ├── 12-kitty.sh
│   ├── 13-flatpak.sh
│   ├── 14-hyprmod.sh
│   └── 99-verify.sh
│
├── config/
├── .gitattributes
└── README.md
```

---

# Installation flow

The installer runs the following stages in order:

```text
00-preflight
      ↓
01-repos
      ↓
02-snapshot
      ↓
03-packages
      ↓
04-sddm
      ↓
05-dms
      ↓
06-session
      ↓
07-services
      ↓
08-zram
      ↓
09-user_dirs
      ↓
10-cargos
      ↓
11-shell
      ↓
12-kitty
      ↓
13-flatpak
      ↓
14-hyprmod
      ↓
99-verify
```

Each stage is executed independently by `install.sh`.

`common.sh` provides the shared shell behavior and logging helpers used by the stages.

---

# Optional components

Optional installation is selected **once** by `install.sh`.

### Interactive

```bash
./install.sh
```

The installer asks:

```text
Install optional packages and components? [y/N]:
```

### Enable optional components

```bash
./install.sh --with-optional
```

### Disable optional components

```bash
./install.sh --without-optional
```

### Help

```bash
./install.sh --help
```

If the installer is executed non-interactively without an explicit option, optional components are skipped.

---

# Optional components currently include

Depending on the selected installer option:

* Additional command-line utilities
* Development tools
* HyprMod

Flatpak and Flathub are **not optional**. They are part of the core system foundation and are configured by `13-flatpak.sh` on every installation.

---

# HyprMod

HyprMod is an optional Hyprland settings application.

When optional components are enabled, the installer uses the current upstream HyprMod installer and then registers its desktop entry.

The upstream installation method is:

```bash
curl -LsSf https://raw.githubusercontent.com/BlueManCZ/hyprmod/main/install.sh | sh
```

followed by:

```bash
hyprmod --install
```

HyprMod remains separate from the core desktop foundation and is therefore skipped when optional components are disabled.

---

# DMS architecture

DankMaterialShell is the primary desktop shell for this setup.

DMS is built on Quickshell and supports Hyprland as a compositor. Its current documentation describes DMS as a complete desktop shell rather than simply a panel.

The intended architecture is therefore:

```text
                 SDDM
                  │
                  ▼
             UWSM session
                  │
                  ▼
              Hyprland
                  │
          ┌───────┴───────┐
          │               │
          ▼               ▼
      Quickshell          DMS
                          │
        ┌─────────────────┼──────────────────┐
        │                 │                  │
        ▼                 ▼                  ▼
       Bar             Launcher          Notifications
        │
        ├────────────── Session / Lock
        │
        ├────────────── Power controls
        │
        ├────────────── Network controls
        │
        └────────────── Bluetooth controls
```

DMS generates its Hyprland integration under:

```text
~/.config/hypr/dms/
```

and provides the shell-side desktop functionality.

The project intentionally does not add another bar, notification daemon, lock screen, or idle daemon alongside DMS.

---

# Session management

The login/session stack is:

```text
SDDM
 ↓
Hyprland (UWSM session)
 ↓
DMS / Quickshell
```

The installer verifies the Hyprland UWSM Wayland session provided by the installed Hyprland/UWSM integration.

The expected UWSM session entry launches Hyprland through UWSM:

```text
uwsm start
```

with the Hyprland desktop entry as its session target.

This keeps compositor startup under UWSM rather than launching Hyprland directly from SDDM.

---

# Services

The bootstrap enables the system services required by the desktop:

```text
NetworkManager.service
bluetooth.service
power-profiles-daemon.service
```

Audio is provided through the user's systemd session:

```text
pipewire.service
pipewire-pulse.service
wireplumber.service
```

These are backend services. They are not intended to be replaced by shell-specific applets.

DMS is attached to the graphical user session and is started through the systemd graphical-session lifecycle rather than being manually launched as a normal system service during installation.

---

# zram

The installer can configure:

```text
/etc/systemd/zram-generator.conf
```

with:

```ini
[zram0]
zram-size = ram / 2
compression-algorithm = zstd
```

Existing zram configuration is preserved rather than blindly overwritten.

---

# Shell environment

The shell setup provides:

* Zsh
* Oh My Zsh
* Powerlevel10k
* zoxide
* Cargo binary path integration

The default shell is changed to Zsh.

Powerlevel10k is installed as the Oh My Zsh theme:

```text
powerlevel10k/powerlevel10k
```

The installer does not automatically run the interactive Powerlevel10k configuration wizard.

---

# Fonts

The bootstrap installs **Annotation Mono Nerd Font**.

The font is also configured for Kitty:

```text
font_family AnnotationMono Nerd Font
```

The intention is to provide a consistent terminal font foundation without imposing a complete visual theme.

---

# Kitty

Kitty is the default terminal for the DMS setup.

The installer creates:

```text
~/.config/kitty/kitty.conf
```

if it does not already exist.

Existing Kitty configuration is preserved, with the required font configuration added when necessary.

---

# Cargo tools

Cargo is installed as part of the core environment.

The bootstrap installs:

```text
pokeget
zoxide
matugen
```

into the user's Cargo binary directory.

Normally this is:

```text
~/.cargo/bin/
```

or the equivalent directory when `CARGO_HOME` is customized.

### Matugen

[Matugen](https://github.com/InioX/matugen) is a Material You and Base16 color-generation tool. It can generate color schemes from inputs such as images and expose those colors to configured templates.

It is installed through Cargo using:

```bash
cargo install matugen
```

Matugen is part of the **core Cargo toolset**, rather than an optional component.

---

# Flatpak

Flatpak is part of the **core installation**.

The bootstrap installs Flatpak and configures the system Flathub remote.

The configuration is handled by:

```text
13-flatpak.sh
```

The installer does not install specific Flatpak applications. It simply provides the Flatpak foundation and Flathub repository so applications can be installed later.

The configured remote is:

```text
flathub
```

using the official Flathub repository.

Flatpak configuration therefore occurs regardless of whether optional packages are enabled.

---

# Configuration

The repository deliberately does **not** ship a finished Hyprland rice.

The intended layout is:

```text
config/
```

as a future configuration canvas.

You can build your own:

```text
Hyprland
DMS
Quickshell
Kitty
GTK
Qt
Matugen
```

configuration without having to remove a pre-existing theme or dotfiles collection first.

---

# Verification

The final installer stage is:

```text
99-verify.sh
```

It checks the resulting installation for things such as:

* Required executables
* SDDM configuration
* SDDM enablement
* Graphical target
* Hyprland session
* UWSM session
* DMS environment
* DMS Hyprland configuration
* XDG user directories
* Cargo-installed tools
* `pokeget`
* `zoxide`
* `matugen`
* Zsh
* Oh My Zsh
* Powerlevel10k
* Default shell
* Annotation Mono Nerd Font
* Kitty configuration
* zram
* NetworkManager
* Bluetooth
* Power Profiles Daemon
* User PipeWire/WirePlumber units
* Hyprland systemd session integration
* Flatpak
* Flathub
* Optional HyprMod
* Required user configuration directories

The verifier distinguishes between:

```text
[PASS]
[WARN]
[FAIL]
```

Core installation problems produce a failed verification.

Session-dependent user services that cannot necessarily be queried before the graphical session is active are treated as warnings.

Optional components never cause the core installation verification to fail merely because they were not requested.

---

# Logs

`install.sh` creates a timestamped log in the repository directory:

```text
install-YYYYMMDD-HHMMSS.log
```

For example:

```text
install-20260916-193000.log
```

The log captures the installer output and is useful when diagnosing a failed stage.

---

# Reboot

After a successful installation, a reboot is recommended before starting the new desktop session.

```bash
sudo reboot
```

After reboot, select the Hyprland/UWSM session from SDDM.

---

# Important notes

## This is intended for openSUSE Tumbleweed

The project targets:

```text
openSUSE Tumbleweed
```

It is not intended to be a generic Arch/Fedora/Debian installer.

Package names, repositories, and system integration are therefore specific to the openSUSE environment.

## Existing desktop environments

This project is intended to establish a Hyprland-focused desktop environment.

If you are installing it on a machine that already has another desktop environment, display manager, shell configuration, or extensive system customization, review the scripts before running them.

In particular, the installer configures SDDM as the display manager and changes the user's default shell to Zsh.

## Backups

The installer includes a snapshot stage before the main system/package changes.

However, you should still maintain your own backups of important files and configurations.

---

# Development

Installer stages are intentionally independent.

To add or modify functionality:

1. Create or edit the appropriate stage.
2. Keep shared shell behavior in `common.sh`.
3. Avoid sourcing another executable stage from a stage.
4. Keep stages focused on one responsibility.
5. Add corresponding verification to `99-verify.sh` when appropriate.
6. Test on a clean Tumbleweed installation.

The main installer is responsible for:

* stage ordering
* logging
* optional-component selection
* sudo handling
* stage discovery
* stage execution
* stopping on stage failure

Individual stages are responsible for their own configuration work.

---

# Design goal

The end result should be a clean starting point:

```text
openSUSE Tumbleweed
        │
        ▼
      SDDM
        │
        ▼
   UWSM + Hyprland
        │
        ▼
 DankMaterialShell
        │
        ▼
     Your config
```

**The bootstrap builds the foundation.
The `config/` directory is where the rice begins.**