#!/usr/bib/env bash

log__debug=0
log__colors=-1

log::detect_colors() {
    if [ -t 1 ];then
        log__colors=1
    else
        log__colors=0
    fi
}

log::enable_debug() {
    log__debug=1
}

log::disable_debug() {
    log__debug=0
}

log::disable_colors() {
    log__colors=0
    log::debug "Colors forcefuly disabled"
}

log::enable_colors() {
    log__colors=1
    log::debug "Colors forcefuly enabled"
}

log::debug() {
    local pid=$BASHPID
    if [ "$log__debug" = "1" ] || [ "$DEBUG" = "1" ];then
        if [ "$log__colors" = "1" ];then
            echo -e "\e[90m$(printf "%-6s %-30s" "$pid" "${FUNCNAME[1]}"): $*\e[0m" >&2
        elif [ "$log__colors" = "-1" ];then
            log::detect_colors
            log::debug "$@"
        else
            echo -e "[DEBUG  ] $(printf "%-6s %-30s" "$pid" "${FUNCNAME[1]}"): $*" >&2
        fi
    fi
}

log::panic() {
    log::error "Panic: $*"
    stack::print 1 1
}

log::fatal() {
    log::error "$*"
    exit 1
}

log::success() {
    if [ "$log__colors" = "1" ];then
        echo -e "\e[32m$*\e[0m" >&2
    elif [ "$log__colors" = "-1" ];then
        log::detect_colors
        log::success "$@"
    else
        echo -e "[SUCCESS] $*" >&2
    fi
}

log::info() {
    if [ "$log__colors" = "1" ];then
        echo -e "\e[36m$*\e[0m" >&2
    elif [ "$log__colors" = "-1" ];then
        log::detect_colors
        log::info "$@"
    else
        echo -e "[INFO   ] $*" >&2
    fi
}

log::error() {
    if [ "$log__colors" = "1" ];then
        echo -e "\e[31m$*\e[0m" >&2
    elif [ "$log__colors" = "-1" ];then
        log::detect_colors
        log::error "$@"
    else
        echo -e "[ERROR  ] $*" >&2
    fi
}

log::warn() {
    if [ "$log__colors" = "1" ];then
        echo -e "\e[33m$*\e[0m" >&2
    elif [ "$log__colors" = "-1" ];then
        log::detect_colors
        log::warn "$@"
    else
        echo -e "[WARN   ] $*" >&2
    fi
}
