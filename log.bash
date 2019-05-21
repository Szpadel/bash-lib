#!/usr/bib/env bash

log__debug=0

log::enable_debug() {
    log__debug=1
}

log::disable_debug() {
    log__debug=0
}

log::debug() {
    local pid=$BASHPID
    if [ "$log__debug" = "1" ] || [ "$DEBUG" = "1" ];then
        echo -e "\e[90m$(printf "%-6s %-30s" "$pid" "${FUNCNAME[1]}"): $*\e[0m" >&2
    fi
}

log::panic() {
    log::error "Panic: $*"
    stack::print 1 1
}

log::success() {
    echo -e "\e[32m$*\e[0m" >&2
}

log::info() {
    echo -e "\e[36m$*\e[0m" >&2
}

log::error() {
    echo -e "\e[31m$*\e[0m" >&2
}

log::warn() {
    echo -e "\e[33m$*\e[0m" >&2
}
