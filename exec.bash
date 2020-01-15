#!/bin/usr/env bash

import log
import dialog

exec__last_log=""

# run command without displaying any output when it success
exec::silent() {
    if [ "$DEBUG" = 1 ]; then
        "$@"
        ret=$?
        return $ret
    else
        if ! exec__last_log="$("$@" 2>&1)";then
            log::error "Command $* failed"
            log::error "$exec__last_log"
            return 1
        fi

        return 0
    fi
}

exec::escape() {
    local p
    for p in "$@";do
        p="${p//\'/\"\'\"}"
        p="${p//\\/\\\\}"
        p="'${p}'"
        p="${p//\'\|\'/|}"
        echo -n "$p "
    done
}

exec::last_log() {
    echo "$exec__last_log"
}

exec::_exec_spinner_progress() {
    local line
    local last_line
    local lineno=0
    local spinner_pos
    local spinner=( "⢀⠀" "⡀⠀" "⠄⠀" "⢂⠀" "⡂⠀" "⠅⠀" "⢃⠀" "⡃⠀" "⠍⠀" "⢋⠀" "⡋⠀" "⠍⠁" "⢋⠁" "⡋⠁" "⠍⠉" "⠋⠉" "⠋⠉" "⠉⠙" "⠉⠙" "⠉⠩" "⠈⢙" "⠈⡙" "⢈⠩" "⡀⢙" "⠄⡙" "⢂⠩" "⡂⢘" "⠅⡘" "⢃⠨" "⡃⢐" "⠍⡐" "⢋⠠" "⡋⢀" "⠍⡁" "⢋⠁" "⡋⠁" "⠍⠉" "⠋⠉" "⠋⠉" "⠉⠙" "⠉⠙" "⠉⠩" "⠈⢙" "⠈⡙" "⠈⠩" "⠀⢙" "⠀⡙" "⠀⠩" "⠀⢘" "⠀⡘" "⠀⠨" "⠀⢐" "⠀⡐" "⠀⠠" "⠀⢀" "⠀⡀" )
    local spinner_len="${#spinner[@]}"
    local status
    while true;do
        read -r -t 0.1 line && status=$? || status=$? 
        if [ "$status" != 0 ] && [ "$status" -le 128 ];then
            break;
        fi
        if [ "$status" -gt 128 ];then
            line="${last_line}"
        else
            echo "$line"
        fi
        lineno=$((lineno + 1))
        spinner_pos=$((lineno % spinner_len))
        log::status "${spinner[$spinner_pos]} $line"
        last_line="$line"
    done
    log::status
}

exec::exec_preview() {
    local ret
    if [ "$DEBUG" = 1 ]; then
        "$@"
        ret=$?
        return $ret
    else
        ret=0
        exec__last_log="$("$@" 2>&1 | exec::_exec_spinner_progress; return "${PIPESTATUS[0]}")" || ret=$?
        if [ "$ret" != "0" ];then
            log::error "Command $* failed"
            log::error "$exec__last_log"
        fi
        return "$ret"
    fi
}

exec::dialog_silent() {
    if [ "$DEBUG" = 1 ]; then
        "$@"
        ret=$?
        return $ret
    else
        if ! exec__last_log="$("$@" 2>&1)";then
            dialog::msg "Command $* failed:\n\n$(dialog::format_text "$exec__last_log")" 15 80
            return 1
        fi

        return 0
    fi
}

exec::dialog() {
    local msg=$1
    shift;
    if [ "$DEBUG" = 1 ]; then
        "$@"
        ret=$?
        return $ret
    else
        dialog::info "$msg"
        if ! exec__last_log="$("$@" 2>&1)";then
            dialog::msg "Command $* failed:\n\n$(dialog::format_text "$exec__last_log")" 15 80
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
    for ((try=0; try<retries; try++)) {
        if exec__last_log="$("$@" 2>&1)" &>/dev/null;then
            return 0
        fi
        if [ "$DEBUG" = "1" ];then
            echo "$exec__last_log" >&2
        fi
        sleep "$sleep"
    }
    log::error "Command $* failed $retries times"
    log::error "$exec__last_log"
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

exec_test::test_escape() {
    local cmd_escaped
    cmd_escaped="$(exec::escape bash -c "echo 'lol'; echo -e 'a\nb'" \| base64)"
    echo "$cmd_escaped"
    unit::assert_eq "$(sh -c "$cmd_escaped")" "$(bash -c "echo 'lol'; echo -e 'a\nb'" | base64)"
}

exec_test::all() {
    unit::test exec_test::test_output
    unit::test exec_test::test_is_cmd_available
    unit::test exec_test::test_is_fn
    unit::test exec_test::test_escape
}
