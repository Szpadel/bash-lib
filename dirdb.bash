#!/usr/bin/env bash

dirdb::read() {
    local location="$1"
    local key="$2"
    local default="$3"

    local path="$location/$key"
    if [ -f "$path" ];then
        cat "$path" 2>/dev/null
    else
        echo -n "$default"
    fi
}

dirdb::is_exists() {
    local location="$1"
    local key="$2"

    local path="$location/$key"
    if [ -f "$path" ];then
        return 0
    fi
    return 1
}

dirdb::delete() {
    local location="$1"
    local key="$2"

    local path="$location/$key"

    if [ -e "$path" ];then
        rm -r "$path"
    fi
}

dirdb::list() {
    local _location="$1"
    local _key="$2"
    local -n output_list=$3

    local _path="$_location/$_key"
    output_list=()
    if [ -e "$_path" ];then
        local _list=( "$_path"/* )
        for _item in "${_list[@]}";do
            if [ -f "$_item" ];then
                output_list+=("${_item##$_path/}")
            fi
        done
    fi
}

dirdb::write() {
    local location="$1"
    local key="$2"
    local value="$3"

    local path="$location/$key"
    mkdir -p "$( dirname "$path")"
    echo -n "$value" > "$path"
}


dirdb_test::test_operations() {
    import tmp
    local tempdb=""
    tmp::create_dir tempdb "dirdb_unit_test"

    unit::assert_eq "$(dirdb::read "$tempdb" some/key "default")" "default"
    unit::assert_failed dirdb::is_exists "$tempdb" some/key
    dirdb::write "$tempdb" some/key "content"
    unit::assert_eq "$(dirdb::read "$tempdb" some/key "default")" "content"
    unit::assert_success dirdb::is_exists "$tempdb" some/key
    dirdb::delete "$tempdb" some/key
    unit::assert_eq "$(dirdb::read "$tempdb" some/key "default")" "default"
    unit::assert_failed dirdb::is_exists "$tempdb" some/key

    tmp::cleanup
}

dirdb_test::test_lists() {
    import tmp
    local tempdb=""
    tmp::create_dir tempdb "dirdb_unit_test"

    dirdb::write "$tempdb" list/a "1"
    dirdb::write "$tempdb" list/b "2"
    local items=""
    dirdb::list "$tempdb" list items
    unit::assert_eq "${items[*]}" "a b"
    dirdb::delete "$tempdb" list
    unit::assert_failed dirdb::is_exists "$tempdb" list/a
    unit::assert_failed dirdb::is_exists "$tempdb" list/b
    dirdb::list "$tempdb" list items
    unit::assert_eq "${items[*]}" ""

    tmp::cleanup
}

dirdb_test::all() {
    unit::test dirdb_test::test_operations
    unit::test dirdb_test::test_lists
}
