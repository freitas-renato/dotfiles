#!/usr/bin/env bash
# =============================================================================
# Dotfiles install script — Ubuntu (Hyprland setup)
# Run this on a fresh Ubuntu install.
# =============================================================================

set -euo pipefail
DOTFILES_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

# -----------------------------------------------------------------------------
# Colors
# -----------------------------------------------------------------------------
RED='\033[0;31m'; GREEN='\033[0;32m'; YELLOW='\033[1;33m'
CYAN='\033[0;36m'; BOLD='\033[1m'; NC='\033[0m'

info()    { echo -e "${CYAN}[INFO]${NC} $*"; }
success() { echo -e "${GREEN}[OK]${NC}   $*"; }
warn()    { echo -e "${YELLOW}[WARN]${NC} $*"; }
die()     { echo -e "${RED}[ERR]${NC}  $*" >&2; exit 1; }
step()    { echo -e "\n${BOLD}>>> $*${NC}"; }

# -----------------------------------------------------------------------------
# Sanity checks
# -----------------------------------------------------------------------------
[[ "$EUID" -eq 0 ]] && die "Do not run as root. The script will call sudo when needed."
command -v apt &>/dev/null || die "This script requires apt (Ubuntu/Debian)."

# -----------------------------------------------------------------------------
# 1. System update
# -----------------------------------------------------------------------------
step "Updating system packages"
sudo apt update && sudo apt upgrade -y
success "System up to date"

# -----------------------------------------------------------------------------
# 2. Add required PPAs / repos
# -----------------------------------------------------------------------------
step "Adding repositories"

# Hyprland via Ubuntu PPA (available on Ubuntu 24.04+)
if ! grep -r "hyprland" /etc/apt/sources.list.d/ &>/dev/null; then
    # Use the official hyprland Ubuntu PPA
    sudo add-apt-repository -y ppa:hyprland-team/hyprland 2>/dev/null || \
        warn "Hyprland PPA not available — will try apt directly (works on 24.04+)"
fi

# Nerd Fonts helper (via apt)
sudo apt update
success "Repositories ready"

# -----------------------------------------------------------------------------
# 3. Install packages
# -----------------------------------------------------------------------------
step "Installing packages"

PKGS=(
    # ── Hyprland ecosystem ─────────────────────────────────────────────────
    hyprland          # Wayland compositor
    hyprlock          # Screen locker
    hyprpaper         # Wallpaper daemon
    xdg-desktop-portal-hyprland

    # ── Status bar ─────────────────────────────────────────────────────────
    waybar

    # ── Notifications ──────────────────────────────────────────────────────
    swaync            # Notification daemon + control center

    # ── App launcher ───────────────────────────────────────────────────────
    wofi

    # ── Terminal ───────────────────────────────────────────────────────────
    kitty

    # ── Multiplexer ────────────────────────────────────────────────────────
    tmux

    # ── Audio ──────────────────────────────────────────────────────────────
    pipewire
    pipewire-pulse
    wireplumber
    pavucontrol
    playerctl         # MPRIS media control (waybar mpris module)
    pactl             # PulseAudio CLI (included in pulseaudio-utils)
    pulseaudio-utils

    # ── Networking ─────────────────────────────────────────────────────────
    network-manager
    network-manager-gnome   # nm-connection-editor
    blueman                 # Bluetooth manager GUI

    # ── Screenshot / clipboard ─────────────────────────────────────────────
    grim              # Wayland screenshot
    slurp             # Region selector
    wl-clipboard      # wl-copy / wl-paste

    # ── File manager ───────────────────────────────────────────────────────
    dolphin

    # ── Fonts ──────────────────────────────────────────────────────────────
    fonts-font-awesome
    fonts-roboto

    # ── System tools ───────────────────────────────────────────────────────
    htop
    git
    curl
    wget
    python3
    python3-pip
    jq

    # ── Theming / GTK ──────────────────────────────────────────────────────
    nwg-look          # GTK theme settings for Wayland

    # ── XDG / portal ───────────────────────────────────────────────────────
    xdg-utils
    dbus-x11
)

sudo apt install -y "${PKGS[@]}" || warn "Some packages may have failed — check output above."
success "Packages installed"

# -----------------------------------------------------------------------------
# 4. Starship prompt
# -----------------------------------------------------------------------------
step "Installing Starship prompt"
if ! command -v starship &>/dev/null; then
    curl -sS https://starship.rs/install.sh | sh -s -- --yes
    success "Starship installed"
else
    success "Starship already installed"
fi

# -----------------------------------------------------------------------------
# 5. MacOS Tahoe Cursor (used by Hyprland)
# -----------------------------------------------------------------------------
step "Checking MacOS-Tahoe-Cursor"
if [[ ! -d "/usr/share/icons/MacOS-Tahoe-Cursor" && ! -d "$HOME/.local/share/icons/MacOS-Tahoe-Cursor" ]]; then
    warn "MacOS-Tahoe-Cursor not found — install it from:"
    warn "https://github.com/ful1e5/apple_cursor or search on Gnome-Look.org"
    warn "Then place it in ~/.local/share/icons/ and run: hyprctl setcursor MacOS-Tahoe-Cursor 32"
else
    success "MacOS-Tahoe-Cursor found"
fi

# -----------------------------------------------------------------------------
# 6. Screenshots folder
# -----------------------------------------------------------------------------
step "Creating Screenshots directory"
mkdir -p "$HOME/Pictures/Screenshots"
success "~/Pictures/Screenshots ready"

# -----------------------------------------------------------------------------
# 7. Deploy dotfiles
# -----------------------------------------------------------------------------
step "Deploying dotfiles"

# .config/*  ──  merge into ~/.config/
rsync -av --mkpath "$DOTFILES_DIR/.config/" "$HOME/.config/" \
    --exclude='*.lock' --exclude='*.pid'
success ".config deployed"

# ~/.local/bin scripts
mkdir -p "$HOME/.local/bin"
rsync -av "$DOTFILES_DIR/.local/bin/" "$HOME/.local/bin/"
chmod +x "$HOME/.local/bin/"*
success ".local/bin scripts deployed"

# Fonts
mkdir -p "$HOME/.local/share/fonts"
rsync -av "$DOTFILES_DIR/.local/share/fonts/" "$HOME/.local/share/fonts/"
fc-cache -f "$HOME/.local/share/fonts"
success "Fonts deployed and cache updated"

# Wallpaper
mkdir -p "$HOME/Pictures"
rsync -av "$DOTFILES_DIR/Pictures/" "$HOME/Pictures/"
success "Wallpaper deployed"

# Cursor theme
mkdir -p "$HOME/.icons"
rsync -av "$DOTFILES_DIR/.icons/" "$HOME/.icons/"
success "Cursor theme deployed (~/.icons)"

# Home-level dotfiles (.bashrc, .gitconfig)
for f in .bashrc .gitconfig; do
    if [[ -f "$DOTFILES_DIR/$f" ]]; then
        # Back up existing file before overwriting
        [[ -f "$HOME/$f" ]] && cp "$HOME/$f" "$HOME/${f}.bak" && \
            info "Backed up existing ~/$f to ~/${f}.bak"
        cp "$DOTFILES_DIR/$f" "$HOME/$f"
        success "$f deployed"
    fi
done

# Make network_menu.sh executable
chmod +x "$HOME/.config/waybar/network_menu.sh" 2>/dev/null || true

# -----------------------------------------------------------------------------
# 8. Enable pipewire as default audio
# -----------------------------------------------------------------------------
step "Enabling PipeWire audio"
systemctl --user enable --now pipewire pipewire-pulse wireplumber 2>/dev/null || \
    warn "Could not enable pipewire services — may need a reboot"
success "PipeWire audio configured"

# -----------------------------------------------------------------------------
# Done
# -----------------------------------------------------------------------------
echo ""
echo -e "${GREEN}${BOLD}============================================${NC}"
echo -e "${GREEN}${BOLD}  Dotfiles installed successfully!${NC}"
echo -e "${GREEN}${BOLD}============================================${NC}"
echo ""
echo -e "Next steps:"
echo -e "  1. ${YELLOW}Log out${NC} and select ${YELLOW}Hyprland${NC} in your display manager"
echo -e "  2. For GPU monitoring in swaync, install ${YELLOW}nvtop${NC}: sudo apt install nvtop"
echo -e "  3. Reboot to apply all session changes: ${CYAN}sudo reboot${NC}"
echo ""
