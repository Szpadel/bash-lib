#!/usr/bin/env bash
# shellcheck source=./lib.bash
source "$(dirname "$(realpath "${BASH_SOURCE[0]}")")"/lib.bash
import unit
import traps
import exec
import log
import array
import dirdb
import tmp
import installer
import daemon

test_fails() {
    unit::assertEq 1 2 "this is error"
}

shellcheck -S style "$(dirname "$(realpath "${BASH_SOURCE[0]}")")"/*
traps_test::all
exec_test::all
array_test::all
dirdb_test::all
tmp_test::all
installer_test::all
daemon_test::all
