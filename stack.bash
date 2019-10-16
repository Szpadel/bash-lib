#!/usr/bin/env bash

stack::print() {
    local err=$?
    set +o xtrace
    local code="${1:$err}"
    local up=${2:-0}
    # Ignore errors detected in bashdb
    if [[ ${FUNCNAME[$up+1]} == _Dbg_* ]];then
        return
    fi
    echo -e "\n\e[91mRuntime failure at ${BASH_SOURCE[$up+1]}:${BASH_LINENO[$up]} exit code $code\n"
    stack::point_line "${BASH_SOURCE[$up+1]}" "${BASH_LINENO[$up]}"
    if [ ${#FUNCNAME[@]} -gt $((up+2)) ];then
        echo -e "\n\e[91mStack trace:"
        for ((a=0;a<${#FUNCNAME[@]}-up-1;a++));do
            local line
            line=$(printf "  %-30s %s" "${BASH_SOURCE[$a+$up+1]}:${BASH_LINENO[$up+$a]}" "${FUNCNAME[$up+$a]}")
            echo -e "\e[91m$line"
        done
    fi
    echo -e "\n\e[91mExiting with error status $code"
    wait
    exit "$code"
}

stack::point_line() {
    local file=$1
    local line=$2

    local start=$((line-2))
    local end=$((line+3))
    if [ $start -lt 1 ];then
        start=1
    fi

    for ((a=start;a<end;a++));do
        lineno=$(printf "%3s" "$a")
        if [ "$a" = "$line" ];then
            echo -e "\e[93m${lineno}\e[37m \e[91m>\e[37m| \e[91m$(sed "${a}q;d" "$file")"
        else
            echo -e "\e[93m${lineno}\e[37m  | \e[33m$(sed "${a}q;d" "$file")"
        fi
    done
}

trap stack::print ERR
set -o errtrace
set -E

import traps
traps::add_err_trap "stack::print 1 1"
