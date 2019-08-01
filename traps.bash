#!/usr/bin/env bash

traps__exit_trap=()
traps__err_trap=()
traps__int_trap=()
traps__err_ignore=0
traps__set_up=0

import log

traps::add_exit_trap() {
    local handler=$1
    traps::_init
    traps__exit_trap=( "$handler" "${traps__exit_trap[@]}" )
}

traps::add_err_trap() {
    local handler=$1
    traps::_init
    traps__err_trap=( "$handler" "${traps__err_trap[@]}" )
}

traps::add_int_trap() {
    local handler=$1
    traps::_init
    traps__int_trap=( "$handler" "${traps__int_trap[@]}" )
}

traps::_handle_exit() {
    log::debug "Handling EXIT traps"
    for cb in "${traps__exit_trap[@]}";do
        $cb
    done
}

traps::_handle_int() {
    log::debug "Handling INT traps"
    for cb in "${traps__int_trap[@]}";do
        $cb
    done
}

traps::_handle_err() {
    local err=$?
    log::debug "Handling ERR traps"
    if [ "$traps__err_ignore" = "1" ];then
        return 0
    fi
    for cb in "${traps__err_trap[@]}";do
        $cb "$err"
    done
}

traps::_init() {
    if [ "$traps__set_up" = "0" ] && [ -z "$BASH_LIB_UNDER_TEST" ];then
        log::debug "Setting up traps for $BASHPID"
        traps__set_up=$BASHPID
        traps__exit_trap=()
        traps__int_trap=()
        trap traps::_handle_exit EXIT
        trap traps::_handle_err ERR
        trap traps::_handle_int INT
    fi
}

traps::ignore_err_start() {
    traps__err_ignore=1
}

traps::ignore_err_end() {
    traps__err_ignore=0
}


traps_test::_example_handler_1() {
    traps_test__handled1=yes
}

traps_test::_example_handler_2() {
    traps_test__handled2=yes
}

traps_test::handling_exit_traps() {
    traps_test__handled1=no
    traps_test__handled2=no
    traps::add_exit_trap traps_test::_example_handler_1
    traps::add_exit_trap traps_test::_example_handler_2
    traps::_handle_exit
    unit::assert_eq "$traps_test__handled1" yes
    unit::assert_eq "$traps_test__handled2" yes
}

traps_test::handling_int_traps() {
    traps_test__handled1=no
    traps_test__handled2=no
    traps::add_int_trap traps_test::_example_handler_1
    traps::add_int_trap traps_test::_example_handler_2
    traps::_handle_int
    unit::assert_eq "$traps_test__handled1" yes
    unit::assert_eq "$traps_test__handled2" yes
}

traps_test::all() {
    unit::test traps_test::handling_exit_traps
    unit::test traps_test::handling_int_traps
}
