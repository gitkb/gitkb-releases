#!/bin/bash
set -eu

# GitKB Installation Script
# Usage: curl -fsSL https://get.gitkb.com/install.sh | bash
#   or:  VERSION=0.1.5 curl -fsSL ... | bash
#   or:  INSTALL_DIR=/usr/local/bin curl -fsSL ... | bash

REPO="gitkb/gitkb-releases"
INSTALL_DIR="${INSTALL_DIR:-$HOME/.local/bin}"
VERSION="${VERSION:-latest}"
SKIP_CHECKSUM="${SKIP_CHECKSUM:-0}"  # Set to 1 to bypass checksum verification

# Colors (disabled when stdout is not a terminal)
if [ -t 1 ]; then
    RED='\033[0;31m'
    GREEN='\033[0;32m'
    YELLOW='\033[1;33m'
    NC='\033[0m'
else
    RED=''
    GREEN=''
    YELLOW=''
    NC=''
fi

info() {
    printf '%b\n' "${GREEN}[INFO]${NC} $1"
}

warn() {
    printf '%b\n' "${YELLOW}[WARN]${NC} $1"
}

error() {
    printf '%b\n' "${RED}[ERROR]${NC} $1"
    exit 1
}

# Persist a gateway-issued setup UUID for one authenticated CLI handoff.
# Never print the identifier, put it in argv, or replace a valid pending ID on
# upgrade: the first unassociated install remains the durable join boundary.
persist_setup_id() (
    local setup_id="${GITKB_SETUP_ID:-}"
    local setup_id_pattern='^[0-9a-f]{8}-[0-9a-f]{4}-4[0-9a-f]{3}-[89ab][0-9a-f]{3}-[0-9a-f]{12}$'
    if [[ ! "$setup_id" =~ $setup_id_pattern ]]; then
        return 0
    fi

    local config_home
    case "${XDG_CONFIG_HOME:-}" in
        /*) config_home="$XDG_CONFIG_HOME" ;;
        *) config_home="$HOME/.config" ;;
    esac

    if [ -L "$config_home" ] || { [ -e "$config_home" ] && [ ! -d "$config_home" ]; }; then
        warn "Could not save install attribution state: unsafe GitKB config directory"
        return 0
    fi

    local state_dir="$config_home/gitkb"
    local state_file="$state_dir/setup-id"
    if [ -L "$state_dir" ] || { [ -e "$state_dir" ] && [ ! -d "$state_dir" ]; }; then
        warn "Could not save install attribution state: unsafe GitKB config directory"
        return 0
    fi

    umask 077
    mkdir -p "$state_dir" || {
        warn "Could not save install attribution state"
        return 0
    }
    if [ ! -O "$state_dir" ] || ! chmod 700 "$state_dir" 2>/dev/null; then
        warn "Could not save install attribution state: unsafe GitKB config directory"
        return 0
    fi

    if [ -L "$state_file" ] || { [ -e "$state_file" ] && [ ! -f "$state_file" ]; }; then
        warn "Could not save install attribution state: unsafe existing file"
        return 0
    fi
    if [ -f "$state_file" ]; then
        if [ ! -O "$state_file" ]; then
            warn "Could not save install attribution state: unsafe existing file"
            return 0
        fi
        local state_mode
        local state_links
        local existing_setup_id=""
        state_mode=$(stat -c '%a' "$state_file" 2>/dev/null || stat -f '%Lp' "$state_file" 2>/dev/null || true)
        state_links=$(stat -c '%h' "$state_file" 2>/dev/null || stat -f '%l' "$state_file" 2>/dev/null || true)
        IFS= read -r existing_setup_id < "$state_file" || true
        if [ "$state_mode" = "600" ] &&
            [ "$state_links" = "1" ] &&
            [[ "$existing_setup_id" =~ $setup_id_pattern ]] &&
            printf '%s\n' "$existing_setup_id" | cmp -s - "$state_file"
        then
            return 0
        fi
        warn "Could not save install attribution state: unsafe existing file"
        return 0
    fi

    local state_tmp
    state_tmp=$(mktemp "$state_dir/setup-id.XXXXXX") || {
        warn "Could not save install attribution state"
        return 0
    }
    # Link into place without replacement so a concurrent writer cannot turn
    # this best-effort handoff into an overwrite primitive.
    if ! printf '%s\n' "$setup_id" > "$state_tmp" || ! chmod 600 "$state_tmp" || ! ln "$state_tmp" "$state_file"; then
        rm -f "$state_tmp"
        warn "Could not save install attribution state"
        return 0
    fi
    rm -f "$state_tmp"
)

# Detect platform
detect_platform() {
    local os
    local arch
    os=$(uname -s | tr '[:upper:]' '[:lower:]')
    arch=$(uname -m)

    case "$os" in
        darwin) os="darwin" ;;
        linux) os="linux" ;;
        *) error "Unsupported operating system: $os" ;;
    esac

    case "$arch" in
        x86_64|amd64) arch="x64" ;;
        arm64|aarch64) arch="arm64" ;;
        *) error "Unsupported architecture: $arch" ;;
    esac

    echo "${os}-${arch}"
}

# Get latest version from GitHub.
# Tries the redirect-based approach first (no API quota), falls back to REST API.
get_latest_version() {
    # Method 1: Follow the /releases/latest redirect — free, no API rate limit
    local redirect_url
    redirect_url=$(curl -fsSL -o /dev/null -w '%{url_effective}' "https://github.com/${REPO}/releases/latest" 2>/dev/null) || true
    if [ -n "$redirect_url" ]; then
        # URL looks like https://github.com/…/releases/tag/v0.1.5
        local tag
        tag="${redirect_url##*/}"
        tag="${tag#v}"
        if [ -n "$tag" ]; then
            echo "$tag"
            return
        fi
    fi

    # Method 2: GitHub REST API (subject to 60 req/hr unauthenticated rate limit)
    local response
    response=$(curl -fsSL "https://api.github.com/repos/${REPO}/releases/latest") || {
        error "Failed to fetch latest release info from GitHub"
    }
    if command -v jq >/dev/null 2>&1; then
        echo "$response" | jq -r '.tag_name // empty' | sed 's/^v//'
    else
        echo "$response" | grep '"tag_name":' | sed -E 's/.*"([^"]+)".*/\1/' | sed 's/^v//'
    fi
}

# Download and install
install_gitkb() {
    local platform
    platform=$(detect_platform)
    local version="$VERSION"
    version="${version#v}"  # Strip leading v if user passed VERSION=v0.1.5

    # Detect existing installation
    if command -v git-kb >/dev/null 2>&1; then
        local current
        current=$(git-kb --version 2>/dev/null || echo "unknown")
        info "Existing installation detected: $current"
    fi

    if [ "$version" = "latest" ]; then
        info "Fetching latest version..."
        version=$(get_latest_version)
        if [ -z "$version" ]; then
            error "Could not determine latest version"
        fi
    fi

    info "Installing git-kb v${version} for ${platform}..."

    local download_url="https://github.com/${REPO}/releases/download/v${version}/gitkb-${platform}.tar.gz"
    local checksum_url="https://github.com/${REPO}/releases/download/v${version}/gitkb-${platform}.tar.gz.sha256"
    tmp_dir=$(mktemp -d)
    trap 'rm -rf "$tmp_dir"' EXIT INT TERM

    info "Downloading from ${download_url}..."
    if ! curl -fsSL "$download_url" -o "${tmp_dir}/gitkb.tar.gz"; then
        error "Failed to download git-kb (check that version '${version}' exists)"
    fi

    if [ "$SKIP_CHECKSUM" = "1" ]; then
        warn "Skipping checksum verification (SKIP_CHECKSUM=1)"
    elif curl -fsSL "$checksum_url" -o "${tmp_dir}/gitkb.tar.gz.sha256" 2>/dev/null; then
        info "Verifying checksum..."
        local expected
        expected=$(awk '{print $1}' "${tmp_dir}/gitkb.tar.gz.sha256")
        local actual
        if command -v sha256sum >/dev/null 2>&1; then
            actual=$(sha256sum "${tmp_dir}/gitkb.tar.gz" | awk '{print $1}')
        elif command -v shasum >/dev/null 2>&1; then
            actual=$(shasum -a 256 "${tmp_dir}/gitkb.tar.gz" | awk '{print $1}')
        else
            error "Cannot verify checksum: neither sha256sum nor shasum found. Install one and retry."
        fi

        if [ "$expected" != "$actual" ]; then
            error "Checksum verification failed!\n  Expected: ${expected}\n  Actual:   ${actual}"
        fi
        info "Checksum verified."
    else
        error "Could not download checksum file. Set SKIP_CHECKSUM=1 to bypass verification."
    fi

    info "Extracting..."
    tar -xzf "${tmp_dir}/gitkb.tar.gz" -C "$tmp_dir"

    # Create install directory if needed
    mkdir -p "$INSTALL_DIR"

    # Install binary
    info "Installing to ${INSTALL_DIR}..."
    if [ -f "$tmp_dir/git-kb" ]; then
        cp "$tmp_dir/git-kb" "$INSTALL_DIR/"
        chmod +x "$INSTALL_DIR/git-kb"
        info "Installed git-kb"
    else
        error "Binary git-kb not found in archive"
    fi

    # Verify the binary runs
    local installed_version
    if installed_version=$("$INSTALL_DIR/git-kb" --version 2>&1); then
        info "Verified: $installed_version"
    else
        error "Installed binary failed to run: ${installed_version}"
    fi

    persist_setup_id

    # Check if INSTALL_DIR is in PATH (POSIX-compatible)
    case ":$PATH:" in
        *":$INSTALL_DIR:"*) ;;
        *)
            warn "$INSTALL_DIR is not in your PATH"
            echo ""
            echo "Add it to your shell configuration:"
            echo ""
            echo "  # For bash (~/.bashrc or ~/.bash_profile):"
            echo "  export PATH=\"\$PATH:$INSTALL_DIR\""
            echo ""
            echo "  # For zsh (~/.zshrc):"
            echo "  export PATH=\"\$PATH:$INSTALL_DIR\""
            echo ""
            echo "  # For fish (~/.config/fish/config.fish):"
            echo "  fish_add_path $INSTALL_DIR"
            echo ""
            ;;
    esac

    info "Installation complete!"
    echo ""
    echo "Run 'git kb --help' to get started."
}

# Main
main() {
    echo "GitKB Installer"
    echo "==============="
    echo ""

    # Check for curl
    if ! command -v curl >/dev/null 2>&1; then
        error "curl is required but not installed"
    fi

    # Check for tar
    if ! command -v tar >/dev/null 2>&1; then
        error "tar is required but not installed"
    fi

    install_gitkb
}

if [ "${GITKB_INSTALLER_LIB_ONLY:-0}" != "1" ]; then
    main "$@"
fi
