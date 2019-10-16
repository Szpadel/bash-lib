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
            echo -e "$(tput el)\e[90m$(printf "%-6s %-30s" "$pid" "${FUNCNAME[1]}"): $*\e[0m" >&2
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
    wait
    exit 1
}

log::success() {
    if [ "$log__colors" = "1" ];then
        echo -e "$(tput el)\e[32m$*\e[0m" >&2
    elif [ "$log__colors" = "-1" ];then
        log::detect_colors
        log::success "$@"
    else
        echo -e "[SUCCESS] $*" >&2
    fi
}

log::info() {
    if [ "$log__colors" = "1" ];then
        echo -e "$(tput el)\e[36m$*\e[0m" >&2
    elif [ "$log__colors" = "-1" ];then
        log::detect_colors
        log::info "$@"
    else
        echo -e "[INFO   ] $*" >&2
    fi
}

log::error() {
    if [ "$log__colors" = "1" ];then
        echo -e "$(tput el)\e[31m$*\e[0m" >&2
    elif [ "$log__colors" = "-1" ];then
        log::detect_colors
        log::error "$@"
    else
        echo -e "[ERROR  ] $*" >&2
    fi
}

log::warn() {
    if [ "$log__colors" = "1" ];then
        echo -e "$(tput el)\e[33m$*\e[0m" >&2
    elif [ "$log__colors" = "-1" ];then
        log::detect_colors
        log::warn "$@"
    else
        echo -e "[WARN   ] $*" >&2
    fi
}

log::progress_bar() {
    local done=$1
    local total=${2:-100}

    if [ "$total" = "0" ];then
        log::debug "Total cannot be 0!"
        total=1
    fi
    if [ "$done" -gt "$total" ];then
        log::debug "Requested progress $done from $total"
        done="$total"
    fi
    cols="$(tput cols)"
    local filled="$((done * (cols - 6) / total))"
    local percent="$((done * 100 / total))"
    local a
    local bar
    bar="$(printf "%4s " "$percent%")"
    bar+="$(echo -e "\e[42m")"
    for ((a=0;a<filled;a++));do
        bar+=" "
    done
    bar+="$(echo -e "\e[49m")"
    
    TRUSTED_CONTENT=1 log::status "$bar"
}

log::status() {
    local line=$1

    if [ "$DEBUG" = "1" ] || [ "$log__colors" != "1" ];then
        return
    fi

    local cols
    cols="$(tput cols)"
    if [ "$TRUSTED_CONTENT" != "1" ];then
        line=$(echo -n "$line" | tr -d '[:cntrl:]' | cut -c "-$cols")
    fi
    
    local civis cuu el cr cnorm
    civis="$(tput civis)"
    cuu="$(tput cuu1)"
    el="$(tput el)"
    cr="$(tput cr)"
    cnorm="$(tput cnorm)"

    echo -n "${civis}"$'\n'"${cr}${el}${line}${cuu}${cr}${el}${cnorm}" >&2

}
