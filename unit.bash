#!/bin/usr/env bash

import log

unit__asserts=0

unit::test() {
    local test_name=$1
    unit__asserts=0
    export BASH_LIB_UNDER_TEST=1
    log::info "Test $test_name"
    "$1"
    log::success "  ${unit__asserts} assertions passed"
    unset BASH_LIB_UNDER_TEST
}

unit::assert_eq() {
    local actual=$1
    local expected=$2
    local msg=${3:-"Error message not provided"}
    unit__asserts=$((unit__asserts + 1))
    if [ "$actual" != "$expected" ];then
        log::error "Assertion failed: $msg"
        log::error "  expectd \`$actual\` to be \`$expected\`"
        log::error "  at ${BASH_SOURCE[1]}:${BASH_LINENO[0]}"
        exit 1
    fi
}

unit::assert_success() {
    local cmd=$1
    shift
    local args=("$@")
    unit__asserts=$((unit__asserts + 1))
    if ! $cmd "${args[@]}";then
        log::error "Excpected $cmd ${args[*]} to succeed"
        exit 1
    fi
}

unit::assert_failed() {
    local cmd=$1
    shift
    local args=("$@")
    unit__asserts=$((unit__asserts + 1))
    if $cmd "${args[@]}";then
        log::error "Expected $cmd ${args[*]} to fail"
        exit 1
    fi
}

unit::assert_contain() {
    local actual=$1
    local contains=$2
    local msg=${3:-"Error message not provided"}
    unit__asserts=$((unit__asserts + 1))
    if ! [[ $actual =~ $contains ]];then
        log::error "Assertion failed: $msg"
        log::error "  expected \`$actual\` to contain \`$contains\`"
        log::error "  at ${BASH_SOURCE[1]}:${BASH_LINENO[0]}"
        exit 1
    fi
}
