#!/bin/usr/env bash

import log

declare -Ag cli__options=()
declare -Ag cli__descriptions=()
cli__extra_info=""
cli__app_description=""
cli__program_name="$0"
cli__order=()

cli::reset() {
    cli__order=()
    cli__extra_info=""
    cli__app_description=""
    declare -Ag cli__options=()
    declare -Ag cli__descriptions=()
}

cli::set_program_name() {
    local program_name="$1"

    cli__program_name="${program_name}"
}

# Additional info that will be displayed under option listing
cli::set_extra_info() {
    local info=$1

    cli__extra_info="$info"
}

# Description visible under first line with arguments
cli::set_app_description() {
    local desc=$1
    
    cli__app_description="$desc"
}

cli::_option_encode() {
    local option="$1"

    log::debug "Encoding ${option}"

    echo "${option}"
}

cli::_option_decode() {
    local option="$1"

    log::debug "Decoding ${option}"

    echo "${option}"
}

# if letter require argument, then subfix letter with ':'
cli::add_option() {
    local letter="$1"
    local callback="$2"
    local description="$3"

    cli__order+=("$letter")
    cli__options["${letter:0:1}"]="$callback"
    cli__descriptions[$letter]="$description"
}

cli::print_help() {
    local usage="Usage: ${cli__program_name}"
    local description=""
    local description_formatted=""
    log::debug "${!cli__descriptions[@]}"
    log::debug "values: ${cli__descriptions[*]}"
    for letter in "${cli__order[@]}";do
    description_formatted="${cli__descriptions["$letter"]//\\n/\\n                  }"
        if [ "${letter:1:1}" = ":" ];then
            usage+=" [-${letter:0:1} ...]"
            description+="    -${letter:0:1} <...>      ${description_formatted}\n"
        else
            usage+=" [-${letter:0:1}]"
            description+="    -${letter:0:1}            ${description_formatted}\n"
        fi
        if [ "$(echo -e "$usage" | tail -n1 | wc -m )" -gt 70 ];then
            usage+="\n        "
        fi
    done
    local app_description_formatted
    if [ -n "$cli__app_description" ];then
        app_description_formatted="\n\n    ${cli__app_description//\\n/\\n    }"
    fi
    local extra_info_formatted
    if [ -n "$cli__extra_info" ];then
        extra_info_formatted="\nAdditional informations:\n\n    ${cli__extra_info//\\n/\\n    }"
    fi
    echo -e "${usage}${app_description_formatted}\n\nOptions:\n${description}${extra_info_formatted}"
}

cli::handle() {
    local all_options=""
    for letter in "${cli__order[@]}";do
        all_options+="${letter}"
    done

    while getopts ":${all_options}" opt; do
        if [ "$opt" = ":" ];then
            log::fatal "Option -${OPTARG} require an argument"
        elif [ "$opt" = "?" ];then
            log::fatal "Invalid option -${OPTARG}"
        fi
        ${cli__options[$opt]} "${OPTARG}"
    done
}

cli_test__a=0
cli_test__b=0
cli_test__c=0

cli_test::a_cb() {
    cli_test__a=1
}

cli_test::b_cb() {
    cli_test__b=$1
}

cli_test::c_cb() {
    cli_test__c=1
}

cli_test::test_handle() {
    cli::reset
    cli::set_program_name "example"
    cli::add_option "a" cli_test::a_cb "Example option a"
    cli::add_option "b:" cli_test::b_cb "Example option b"
    cli::add_option "c" cli_test::c_cb "Example option c"

    cli::handle "-a" "-b" "sth"
    unit::assert_eq "${cli_test__a}" "1"
    unit::assert_eq "${cli_test__b}" "sth"
    unit::assert_eq "${cli_test__c}" "0"
}

cli_test::test_help_gen() {
    cli::reset
    cli::set_program_name "example"
    cli::add_option "a" cli_test::a_cb "Example option a"
    cli::add_option "b:" cli_test::b_cb "Example option b"
    cli::add_option "c" cli_test::c_cb "Example option c"

    local expected_output
    expected_output="Usage: example [-a] [-b ...] [-c]

Options:
    -a            Example option a
    -b <...>      Example option b
    -c            Example option c"
    local output
    output=$(cli::print_help)
    
    unit::assert_eq "${output}" "${expected_output}"
}

cli_test::all() {
    unit::test cli_test::test_help_gen
    unit::test cli_test::test_handle
}
