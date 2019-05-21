#!/usr/bin/env bash
set -e

[[ "${BASH_VERSINFO[0]}" -lt 4 ]] && echo "This application require bash >= 4, please upgrade it first" && exit 1

declare -A bash_lib__imported
bash_lib__paths=( "$(dirname "${BASH_SOURCE[0]}")" )


import::add_path() {
    local path="$1"
    bash_lib__paths+=("$path")
}

import() {
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
