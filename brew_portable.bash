#!/usr/bin/env bash

# No imports to be able to use as portable install
# This is only patial of brew module that doesn't contain any depenndencies
# and is able to work with bash3
# This is used to bootstrap brew envirionment and restart application under bash4

brew::_install() {
    local dir=$1
    mkdir -p "$dir"
    echo "Initializing private homebrew instance" 1>&2
    curl -sL https://github.com/Homebrew/brew/tarball/master | tar xz --strip 1 -C "$dir"
}

brew::_setup() {
    local dir=$1
    local mode=$2
    if ! [[ "$OSTYPE" == "darwin"* ]]; then
        echo "brew can only we used on MacOs" 1>&2
        exit 1
    fi
    if [ "$BASHLIB_BREW_DIR" != "$dir" ] || [ "$BASHLIB_BREW_MODE" != "$mode" ];then
        brew::exit
    fi
    if ! [ -f "$dir/bin/brew" ];then
        brew::_install "$dir"
    fi
    export BASHLIB_BREW_DIR="$dir"
    export BASHLIB_BREW_MODE="$mode"
    if [ "$mode" = "exclusive" ];then
        export PATH="$dir/bin:$dir/sbin:/usr/bin:/bin:/usr/sbin:/sbin"
    else
        export PATH="$dir/bin:$dir/sbin:/usr/bin:/bin:/usr/sbin:/sbin:$PATH"
    fi
}

brew::exit() {
    if [ -z "$BASHLIB_BREW_DIR" ];then
        return
    fi

    local path_components
    local path_component
    mapfile -d':' -t path_components <<< "$PATH"
    local new_path=()
    for path_component in "${path_components[@]}";do
        if ! [[ path_component == ${BASHLIB_BREW_DIR}* ]];then
            new_path+=( "$path_component" )
        fi
    done

    PATH="$(brew::_join ":" "${new_path[@]}")"
    unset BASHLIB_BREW_DIR
    unset BASHLIB_BREW_MODE
}

brew::_join() {
    local IFS="$1"
    shift
    echo "$*"
}

brew::_assert_env() {
    if [ -z "$BASHLIB_BREW_DIR" ];then
        echo "You need to run this comand in brew envirionment" 1>&2
        exit 1
    fi
}

brew::brew() {
    brew::_assert_env
    GIT_SSH_COMMAND="ssh -o UserKnownHostsFile=/dev/null -o StrictHostKeyChecking=no" brew "$@"
}

brew::_quote () {
    for a in "${@//\"/\\\"}";do echo -n "\"$a\" ";done;
}

brew::enter() {
    local dir=$1
    local mode=$2
    brew::_setup "$dir" "$mode"
}

brew::exec_in() {
    local dir=$1
    shift
    brew::_setup "$dir"
    exec bash -c "$(brew::_quote "$@")"
}
