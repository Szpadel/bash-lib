#!/usr/bin/env bash

# passed array name must be global variable
array::pop() {
    local -n arr=$1
    local -n target=$2
    # shellcheck disable=SC2034
    target="${arr[-1]}"
    unset "arr[-1]"
}

# array::from_string some_array " "  "a b c"
array::from_string() {
    local output_var=$1
    local split_by=${2:-$'\n'}

    mapfile -t -d "$split_by" "$output_var"
}

# array::contains "find_me" "${array[@]}"
array::contains() {
    local item="$1"
    shift
    local arr=("$@")
    for a in "${arr[@]}";do
        if [ "$a" = "$item" ];then
            return 0
        fi
    done
    return 1
}

array_test::pop() {
    array=(1 2 3 4 5)
    array::pop array item
    unit::assert_eq "$item" "5"
    unit::assert_eq "${array[*]}" "1 2 3 4"
}

array_test::contains() {
    array=(1 2 3 4 5)
    unit::assert_success array::contains 3 "${array[@]}"
    unit::assert_success array::contains 5 "${array[@]}"
    unit::assert_success array::contains 1 "${array[@]}"
    unit::assert_failed array::contains 0 "${array[@]}"
    unit::assert_failed array::contains 12 "${array[@]}"
}

array_test::all() {
    unit::test array_test::pop
    unit::test array_test::contains
}
