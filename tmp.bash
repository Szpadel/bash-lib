#!/usr/bin/env bash
import traps
import log

tmp__to_remove=()
tmp__trap_exists=0

tmp::mktemp() {
    local tag="$1"
    local flags="$2"
    local tmpdir="$3"
    if [[ "$OSTYPE" == "darwin"* ]]; then
        if [ -n "$tmpdir" ];then
            # shellcheck disable=SC2086
            mktemp $flags "$tmpdir/$tag"
        else
            # shellcheck disable=SC2086
            mktemp $flags "$tag"
        fi
    else
        # shellcheck disable=SC2086
        mktemp $flags -t "$tag" -p "$tmpdir"
    fi
}

tmp::create_persistent_dir() {
    local -n output_var=$1
    local tag=${2:-"bash-lib"}
    local inside="${3:-"${TMPDIR:-/tmp}"}"
    local dir
    dir=$(tmp::mktemp "$tag.XXXXXXXXXX" "-d" "$inside")
    
    tmp::_init
    log::debug "New dir $dir"
    output_var="$dir"
}

tmp::create_dir() {
    tmp::create_persistent_dir "$@"
    local -n output_var=$1
    log::debug "Scheduling removal of $output_var"
    tmp__to_remove+=("$output_var")
}

tmp::create_persistent_file() {
    local -n output_var=$1
    local tag=${2:-"bash-lib"}
    local inside="${3:-"${TMPDIR:-/tmp}"}"
    local file
    file=$(tmp::mktemp "$tag.XXXXXXXXXX" "" "$inside")

    tmp::_init
    log::debug "New file $file"
    output_var="$file"
}

tmp::create_file() {
    tmp::create_persistent_file "$@"
    local -n output_var=$1
    log::debug "Scheduling removal of $output_var"
    tmp__to_remove+=("$output_var")
}

tmp::cleanup() {
    for tmp in "${tmp__to_remove[@]}";do
        log::debug "Purging $tmp"
        rm -rf "$tmp"
    done
    tmp__to_remove=()
}

tmp::_init() {
    if [ "$tmp__trap_exists" = "0" ];then
        traps::add_exit_trap tmp::cleanup
        tmp__trap_exists=1
    fi
}

tmp_test::test_dir() {
    local test_dir=""
    local child_dir=""
    tmp::create_dir test_dir
    unit::assert_success [ -d $test_dir ]
    tmp::create_dir child_dir "" "$test_dir"
    unit::assert_success [ -d $child_dir ]
    unit::assert_eq "$test_dir" "$(dirname $child_dir)"
    tmp::cleanup
    unit::assert_failed [ -d $test_dir ]
}

tmp_test::test_file() {
    local test_file=""
    tmp::create_file test_file
    unit::assert_success [ -f $test_file ]
    tmp::cleanup
    unit::assert_failed [ -f $test_file ]
}

tmp_test::all() {
    unit::test tmp_test::test_dir
    unit::test tmp_test::test_file
}
