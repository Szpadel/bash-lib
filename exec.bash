#!/bin/usr/env bash

import log

# run command without displaying any output when it success
exec::silent() {
    if [ "$DEBUG" = 1 ]; then
        "$@"
        ret=$?
        return $ret
    else
        local log=""
        if ! log="$("$@" 2>&1)";then
            log::error "Command $* failed"
            log::error "$log"
            return 1
        fi

        return 0
    fi
}

exec::retried_exec() {
    local retries=$1
    local sleep=$2
    shift;shift
    local try
    local log
    for ((try=0; try<retries; try++)) {
        if log="$("$@" 2>&1)" &>/dev/null;then
            return 0
        fi
        if [ "$DEBUG" = "1" ];then
            echo "$log" >&2
        fi
        sleep "$sleep"
    }
    log::error "Command $* failed $retries times"
    log::error "$log"
    return 1
}

exec__sudo_keeping=0

exec::sudo_keep_alive() {
    exec::assert_cmd "sudo"
    if [ "$exec__sudo_keeping" != "1" ];then
        exec__sudo_keeping=1
        if ! sudo -v;then
            log::fatal "sudo authentication failed"
        fi
        while true; do sudo -n true; sleep 60; kill -0 "$$" || exit; done 2>/dev/null &
    fi
}

exec::sudo() {
    exec::sudo_keep_alive
    sudo "$@"
}

exec::is_cmd_available() {
    local cmd="$1"
    if command -v "$cmd" &>/dev/null;then
        return 0
    fi
    return 1
}

exec::is_fn() {
    local fn="$1"
    if [ "$(type -t "$fn")" = "function" ];then
        return 0
    fi
    return 1
}

exec::assert_cmd() {
    local cmd="$1"
    if ! exec::is_cmd_available "$cmd";then
        log::fatal "Command \`$cmd\` is not available, but is required by this application"
    fi
}

exec_test::test_is_cmd_available() {
    unit::assert_success "exec::is_cmd_available bash"
    unit::assert_failed "exec::is_cmd_available this_for_sure_not_exists_bleh"
}

exec_test::test_output() {
    local og_debug="$DEBUG"
    DEBUG=0
    set +eE
    local should_be_silent
    should_be_silent=$(exec::silent bash -c 'echo output && true' 2>&1)
    unit::assert_eq "$should_be_silent" "" "shouldn't have output on success"
    
    local should_have_output
    should_have_output=$(exec::silent bash -c 'echo output && false' 2>&1 || true)
    unit::assert_contain "$should_have_output" "output" "should have output on error"

    DEBUG=1
    local output_in_debug
    output_in_debug=$(exec::silent bash -c 'echo output && true' 2>&1)
    unit::assert_contain "$output_in_debug" "output" "should have output in debug"
    DEBUG="$og_debug"
    set -eE
}

exec_test::test_is_fn() {
    # shellcheck disable=SC2034
    local some_var=""

    unit::assert_success exec::is_fn exec::is_fn
    unit::assert_failed exec::is_fn exec_test::not_exists_for_sure
    unit::assert_failed exec::is_fn some_var
}

exec_test::all() {
    unit::test exec_test::test_output
    unit::test exec_test::test_is_cmd_available
    unit::test exec_test::test_is_fn
}
