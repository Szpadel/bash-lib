#!/usr/bin/env bash
set -e

# We are on old bash on macos, we have startup brew directory set and we are not already in such env
if [[ "${BASH_VERSINFO[0]}" -lt 4 ]] && [[ "$OSTYPE" == "darwin"* ]] && [ -n "$BASHLIB_STARTUP_BREW" ] && [ -z "$BASHLIB_BREW_DIR" ];then
    # shellcheck source=/dev/null
    source "$(dirname "${BASH_SOURCE[0]}")/brew_portable.bash"
    brew::enter "$BASHLIB_STARTUP_BREW"
    if ! [ -f "$BASHLIB_BREW_DIR/bin/bash" ];then
        echo "Composing modern bash for itself" 1>&2
        brew::brew install bash &> /dev/null
    fi
    # restart
    exec bash "$0" "$@"
fi

[[ "${BASH_VERSINFO[0]}" -lt 4 ]] && echo "This application require bash >= 4, please upgrade it first" && exit 1

declare -A bash_lib__imported
bash_lib__paths=( "$(dirname "${BASH_SOURCE[0]}")" )


import::add_path() {
    local path="$1"
    bash_lib__paths+=("$path")
}

import() {
    # because it might be unset in subshell
    set -e
    for dir in "${bash_lib__paths[@]}";do
        local filename="$dir/$*.bash"
        if ! [ -f "$filename" ];then
            continue
        fi
        if [ "${bash_lib__imported["$filename"]}" != "1" ];then
            bash_lib__imported["$filename"]=1
            # shellcheck source=/dev/null
            source "$filename"
        fi
        return
    done
    echo "Import failed for: $*" >&2
    stack::print 1 1
}

import stack
