#!/usr/bin/env bash

SCRIPT_DIR="$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")" && pwd)"

source "$SCRIPT_DIR/common.sh"

log "Installing packages..."

command -v zypper >/dev/null 2>&1 \
    || die "zypper is not available."

command -v rpm >/dev/null 2>&1 \
    || die "rpm is not available."

# ------------------------------------------------------------
# Core packages
# ------------------------------------------------------------

CORE_PACKAGES=(
    hyprland
    hyprland-guiutils
    hyprland-qt-support
    hyprsunset
    uwsm
    quickshell
    dgop
    danksearch
    cliphist
    dms
    kitty
    sddm
    xwayland
    xdg-desktop-portal
    xdg-desktop-portal-gtk
    xdg-desktop-portal-hyprland
    xdg-user-dirs
    xdg-utils
    wl-clipboard
    udisks2
    upower
    power-profiles-daemon
    NetworkManager
    bluez
    pipewire
    pipewire-alsa
    pipewire-pulseaudio
    pipewire-jack
    wireplumber
    libvulkan_radeon
    libvulkan_radeon-32bit
    kernel-firmware-amdgpu
    ucode-amd
    zsh
    cargo
    wget
    unzip
    tar
    gzip
    zstd
    git
)

# ------------------------------------------------------------
# Extra packages
#
# These are part of the standard desktop installation but are
# separate from the minimal core package set.
# ------------------------------------------------------------

EXTRA_PACKAGES=(
    hyprpolkitagent
    gnome-keyring
    dolphin
    gwenview
    ark
    kio-extras
    breeze6
    kf6-breeze-icons
    breeze6-cursors
    gtk3-metatheme-adwaita
    qt6ct
    qt6-imageformats
    qt6-multimedia
    ffmpegthumbs
    kdegraphics-thumbnailers
    kimageformats
    awww
    cava
    brightnessctl
    playerctl
    grim
    slurp
    wf-recorder
    google-noto-fonts
    google-noto-sans-cjk-fonts
    google-noto-coloremoji-fonts
    dejavu-fonts
    liberation-fonts
    zram-generator
    fwupd
    flatpak
)

# ------------------------------------------------------------
# Optional packages
#
# Installed only when INSTALL_OPTIONAL=1 is passed from the
# main installer.
# ------------------------------------------------------------

OPTIONAL_PACKAGES=(
    ffmpeg
    neovim
    tree
    ripgrep
    eza
    fzf
    fd
    htop
    btop
    nvtop
    fastfetch
    tmux
    cmake
    meson
    ninja
    clang
    gdb
    pkg-config
    opi
    cmatrix
)

# ------------------------------------------------------------
# Refresh package metadata
# ------------------------------------------------------------

log "Refreshing package metadata..."

sudo zypper \
    --non-interactive \
    --gpg-auto-import-keys \
    refresh

# ------------------------------------------------------------
# Install core packages
# ------------------------------------------------------------

log "Installing core packages..."

sudo zypper \
    --non-interactive \
    --auto-agree-with-licenses \
    install \
    "${CORE_PACKAGES[@]}"

# ------------------------------------------------------------
# Install extra desktop packages
# ------------------------------------------------------------

log "Installing desktop and quality-of-life packages..."

sudo zypper \
    --non-interactive \
    --auto-agree-with-licenses \
    install \
    "${EXTRA_PACKAGES[@]}"

# ------------------------------------------------------------
# Install optional packages
# ------------------------------------------------------------

if [[ "${INSTALL_OPTIONAL:-0}" == "1" ]]; then
    log "Installing optional packages..."

    if ((${#OPTIONAL_PACKAGES[@]} > 0)); then
        sudo zypper \
            --non-interactive \
            --auto-agree-with-licenses \
            install \
            "${OPTIONAL_PACKAGES[@]}"
    else
        log "No optional packages are configured."
    fi
else
    log "Skipping optional packages."
fi

# ------------------------------------------------------------
# Verify required packages
# ------------------------------------------------------------

log "Verifying required packages..."

REQUIRED_PACKAGES=(
    "${CORE_PACKAGES[@]}"
    "${EXTRA_PACKAGES[@]}"
)

for package in "${REQUIRED_PACKAGES[@]}"; do
    if rpm -q "$package" >/dev/null 2>&1; then
        log "Installed: $package"
    else
        die "Required package was not installed: $package"
    fi
done

# ------------------------------------------------------------
# Verify optional packages
# ------------------------------------------------------------

if [[ "${INSTALL_OPTIONAL:-0}" == "1" ]]; then
    log "Verifying optional packages..."

    for package in "${OPTIONAL_PACKAGES[@]}"; do
        if rpm -q "$package" >/dev/null 2>&1; then
            log "Installed: $package"
        else
            die "Optional package installation failed: $package"
        fi
    done
fi

# ------------------------------------------------------------
# Finished
# ------------------------------------------------------------

log "Package installation complete."

exit 0