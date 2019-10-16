#!/usr/bin/env bash

import brew_portable
import log
import exec

brew::is_installed() {
    local pkg=$1
    if brew::brew list "$1" &>/dev/null;then
        return 0
    fi
    return 1
}

brew::install() {
    local pkg=$1
    log::info "Installing $pkg..."
    exec::exec_preview brew::brew install "$pkg"
}

brew::upgrade() {
    local pkg=$1
    log::info "Upgrading $pkg..."
    exec::exec_preview brew::brew upgrade "$pkg"
}

brew::upgrade_all() {
    log::info "Upgrading packages..."
    exec::exec_preview brew::brew upgrade
}

# $1 pkg name
# $2 (optional) binary name for quick instalation check
brew::require() {
    local pkg=$1
    local binary=${2:-$1}
    brew::_assert_env
    if [ -f "$BASHLIB_BREW_DIR/bin/$binary" ];then
        return
    fi
    if ! brew::is_installed "$pkg";then
        brew::install "$pkg"
    fi
}
