#!/usr/bin/env bash

xdg::data_file() {
    local filename="$1"
    echo -n "${XDG_DATA_HOME:-"$HOME/.local/share"}/$filename"
}

xdg::config_file() {
    local filename="$1"
    echo -n "${XDG_CONFIG_HOME:-"$HOME/.config"}/$filename"
}

xdg::cache_file() {
    local filename="$1"
    echo -n "${XDG_CACHE_HOME:-"$HOME/.cache"}/$filename"
}

xdg::runtime_file() {
    local filename="$1"
    if [ -z "${XDG_RUNTIME_DIR}" ];then
        log::panic "\$XDG_RUNTIME_DIR isn't set but is required by this application"
    fi
    echo -n "${XDG_RUNTIME_DIR}/$filename"
}

xdg::_find_file_in_paths() {
    local filename="$1"
    local paths="$2"
    local directories=()
    mapfile -d' ' directories <<< "$paths"
    for dir in "${directories[@]}";do
        if [ -d "$dir/$filename" ];then
            echo -n "$dir/$filename"
            return
        fi
    done
}

xdg::find_data_file() {
    local filename="$1"
    local data_dirs
    data_dirs="$(xdg::data_file ""):${XDG_DATA_DIRS:-"/usr/local/share/:/usr/share/"}"
    xdg::_find_file_in_paths "$filename" "$data_dirs"
}

xdg::find_config_file() {
    local filename="$1"
    local config_dirs
    config_dirs="$(xdg::config_file ""):${XDG_CONFIG_DIRS:-"/etc/xdg"}"
    xdg::_find_file_in_paths "$filename" "$config_dirs"
}

xdg_test::test_find_data_file() {
    XDG_DATA_DIRS=
}

