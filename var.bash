#!/usr/bin/env bash

var::exists() {
    local var=$1
    if declare -p "$var" &>/dev/null;then
        return 0
    else
        return 1
    fi
}

