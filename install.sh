#!/usr/bin/env bash
# =============================================================================
# Dotfiles install script — Ubuntu (Hyprland setup)
# Uses GNU Stow to symlink packages into $HOME.
# Run this on a fresh Ubuntu install from inside the dotfiles directory.
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
[[ "$(pwd)" == "$DOTFILES_DIR" ]] || die "Run this script from inside the dotfiles directory: cd $DOTFILES_DIR && ./install.sh"

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

sudo add-apt-repository universe

#if ! grep -r "hyprland" /etc/apt/sources.list.d/ &>/dev/null; then
#    sudo add-apt-repository -y ppa:hyprland-team/hyprland 2>/dev/null || \
#        warn "Hyprland PPA not available — will try apt directly (works on 24.04+)"
#fi


sudo apt update
success "Repositories ready"

# -----------------------------------------------------------------------------
# 3. Install packages
# -----------------------------------------------------------------------------
step "Installing packages"

PKGS=(
    # ── Core tool ──────────────────────────────────────────────────────────
    stow

    # ── Hyprland ecosystem ─────────────────────────────────────────────────
    hyprland
    swaylock
    gtklock
    swayidle
    hyprpaper
    xdg-desktop-portal-hyprland

    # ── Status bar ─────────────────────────────────────────────────────────
    waybar

    # ── Notifications ──────────────────────────────────────────────────────
   # swaync
    sway-notification-center

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
    playerctl
    pulseaudio-utils

    # ── Networking ─────────────────────────────────────────────────────────
    network-manager
    network-manager-gnome
    blueman

    # ── Screenshot / clipboard ─────────────────────────────────────────────
    grim
    slurp
    wl-clipboard
    cliphist
    7zip

    # ── File manager ───────────────────────────────────────────────────────
    dolphin

    # ── Fonts (system) ─────────────────────────────────────────────────────
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

    # ── Theming ────────────────────────────────────────────────────────────
    nwg-look

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
# 5. Cursor theme — create ~/.icons if missing (not managed by stow)
# -----------------------------------------------------------------------------
step "Preparing ~/.icons"
mkdir -p "$HOME/.icons"
success "~/.icons ready"

# -----------------------------------------------------------------------------
# 6. Screenshots folder
# -----------------------------------------------------------------------------
step "Creating Screenshots directory"
mkdir -p "$HOME/Pictures/Screenshots"
success "~/Pictures/Screenshots ready"

# -----------------------------------------------------------------------------
# 7. Stow packages
# -----------------------------------------------------------------------------
step "Backing up pre-existing dotfiles that would conflict with Stow"

CONFLICTS=(
    "$HOME/.bashrc"
    "$HOME/.bash_logout"
    "$HOME/.profile"
    "$HOME/.gitconfig"
)
for f in "${CONFLICTS[@]}"; do
    if [[ -e "$f" && ! -L "$f"  ]]; then
         mv "$f" "${f}.bak"
         info "Backed up: $f -> ${f}.bak"
    fi
done

step "Stowing dotfiles packages"

# All stow packages in this repo
PACKAGES=(
    hypr
    waybar
    kitty
    tmux
    wofi
    swaync
    gtklock
    swaylock
    fontconfig
    gtk
    htop
    bash
    git
    fonts
    scripts
    icons
    wallpaper
)

cd "$DOTFILES_DIR"
for pkg in "${PACKAGES[@]}"; do
    if [[ -d "$pkg" ]]; then
        # --restow removes and re-creates stale symlinks
        stow --restow --target="$HOME" "$pkg"
        success "stowed: $pkg"
    else
        warn "Package directory not found, skipping: $pkg"
    fi
done

# Make scripts executable
chmod +x "$HOME/.local/bin/"* 2>/dev/null || true
chmod +x "$HOME/.config/waybar/network_menu.sh" 2>/dev/null || true

# Register fonts
fc-cache -f "$HOME/.local/share/fonts"
success "Font cache updated"

# -----------------------------------------------------------------------------
# 7b. Apple fonts + UI font settings
# -----------------------------------------------------------------------------
# The SF/New York fonts are NOT in this repo: Apple's licence forbids
# redistributing them and they are ~570MB. The script downloads them from
# Apple into ~/.local/share/apple-fonts (outside the repo, since
# ~/.local/share/fonts is a stow symlink into it). The fontconfig package maps
# the generic families onto them.
step "Installing Apple SF fonts"
if fc-list : family | grep -q "SF Pro Text"; then
    success "SF fonts already installed"
else
    "$HOME/.local/bin/install-apple-fonts" || warn "SF font install failed — run ~/.local/bin/install-apple-fonts manually"
fi

# GTK reads its UI font from gsettings as well as gtk-*/settings.ini, and
# gsettings is not a file so stow cannot manage it.
step "Applying UI font settings"
gsettings set org.gnome.desktop.interface font-name 'SF Pro Text 11'
gsettings set org.gnome.desktop.interface document-font-name 'SF Pro Text 12'
gsettings set org.gnome.desktop.interface monospace-font-name 'SF Mono 11'
success "UI fonts set"

# -----------------------------------------------------------------------------
# 8. Enable PipeWire audio
# -----------------------------------------------------------------------------
step "Enabling PipeWire audio"
#systemctl --user enable --now pipewire pipewire-pulse wireplumber 2>/dev/null || \
#    warn "Could not enable pipewire services — may need a reboot"
#success "PipeWire audio configured"

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
echo -e "  3. Lock screen is ${YELLOW}gtklock${NC} (\$mainMod+SHIFT+L); swaylock is the fallback"
echo -e "  3. Reboot to apply all session changes: ${CYAN}sudo reboot${NC}"
echo ""
echo -e "Tip: to add/remove a config package later:"
echo -e "  ${CYAN}stow --target=\$HOME hypr${NC}        # symlink"
echo -e "  ${CYAN}stow --delete --target=\$HOME hypr${NC}  # remove symlinks"
echo ""
