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

# Extensions installed beside git-kb: `git-kb <name>` runs `git-kb-<name>`.
# Each release from 1.0.0 ships one archive per extension, gitkb-<name>-<platform>.tar.gz.
EXTENSIONS="code semantic"

# download_verified <archive name> <base URL> <destination>
# Downloads one release archive and checks it against its .sha256 file.
download_verified() {
    local archive="$1"
    local base_url="$2"
    local dest="$3"

    info "Downloading ${base_url}/${archive}..."
    if ! curl -fsSL "${base_url}/${archive}" -o "$dest"; then
        error "Failed to download ${archive} (check that the version exists)"
    fi

    if [ "$SKIP_CHECKSUM" = "1" ]; then
        warn "Skipping checksum verification (SKIP_CHECKSUM=1)"
    elif curl -fsSL "${base_url}/${archive}.sha256" -o "${dest}.sha256" 2>/dev/null; then
        info "Verifying checksum..."
        local expected
        expected=$(awk '{print $1}' "${dest}.sha256")
        local actual
        if command -v sha256sum >/dev/null 2>&1; then
            actual=$(sha256sum "$dest" | awk '{print $1}')
        elif command -v shasum >/dev/null 2>&1; then
            actual=$(shasum -a 256 "$dest" | awk '{print $1}')
        else
            error "Cannot verify checksum: neither sha256sum nor shasum found. Install one and retry."
        fi

        if [ "$expected" != "$actual" ]; then
            error "Checksum verification failed for ${archive}!\n  Expected: ${expected}\n  Actual:   ${actual}"
        fi
        info "Checksum verified."
    else
        error "Could not download checksum file. Set SKIP_CHECKSUM=1 to bypass verification."
    fi
}

# install_binary <name> <extract dir>
install_binary() {
    local name="$1"
    local dir="$2"
    if [ -f "$dir/$name" ]; then
        cp "$dir/$name" "$INSTALL_DIR/"
        chmod +x "$INSTALL_DIR/$name"
        info "Installed $name"
    else
        error "Binary $name not found in archive"
    fi

    # Verify the binary runs
    local installed_version
    if installed_version=$("$INSTALL_DIR/$name" --version 2>&1); then
        info "Verified: $installed_version"
    else
        error "Installed binary $name failed to run: ${installed_version}"
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

    local base_url="https://github.com/${REPO}/releases/download/v${version}"
    tmp_dir=$(mktemp -d)
    trap 'rm -rf "$tmp_dir"' EXIT INT TERM

    download_verified "gitkb-${platform}.tar.gz" "$base_url" "${tmp_dir}/gitkb.tar.gz"

    info "Extracting..."
    mkdir -p "${tmp_dir}/gitkb"
    tar -xzf "${tmp_dir}/gitkb.tar.gz" -C "${tmp_dir}/gitkb"

    # Create install directory if needed
    mkdir -p "$INSTALL_DIR"

    # Install binary
    info "Installing to ${INSTALL_DIR}..."
    install_binary git-kb "${tmp_dir}/gitkb"

    # Extensions. A release lists every archive it has in checksums.txt;
    # releases before 1.0.0 have none for the extensions, and git-kb still
    # had code intelligence built in.
    local listed=""
    if curl -fsSL "${base_url}/checksums.txt" -o "${tmp_dir}/checksums.txt" 2>/dev/null; then
        listed=$(awk '{print $2}' "${tmp_dir}/checksums.txt")
    else
        warn "Could not download checksums.txt; skipping the git-kb extensions"
    fi
    local ext
    for ext in $EXTENSIONS; do
        local archive="gitkb-${ext}-${platform}.tar.gz"
        if ! printf '%s\n' "$listed" | grep -qx "$archive"; then
            info "Release v${version} has no git-kb-${ext}; skipping it"
            continue
        fi
        download_verified "$archive" "$base_url" "${tmp_dir}/${archive}"
        mkdir -p "${tmp_dir}/${ext}"
        tar -xzf "${tmp_dir}/${archive}" -C "${tmp_dir}/${ext}"
        install_binary "git-kb-${ext}" "${tmp_dir}/${ext}"
    done

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

main "$@"
