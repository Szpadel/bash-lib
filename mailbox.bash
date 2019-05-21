#!/usr/bin/env bash

mailbox::create() {
    local location=$1
    if [ -e "$location" ];then
        return 1
    fi
    mkdir -p "$location"
    mkfifo "$location/knock"
    mkdir "$location/requests"
    mkdir "$location/responses"
}

mailbox::send() {
    local location=$1
    local -n _output_var=$2
    local msg=$3
    local id="$BASHPID.$RANDOM"
    echo -n "$msg" > "$location/requests/$id"
    # shellcheck disable=SC2034
    _output_var="$id"
}

mailbox::receive() {
    local location=$1
    local id=$2
    local timeout=${3:-30}
    while true;do
        for ((t=0;t<timeout*10;t++));do
            if [ -e "$location/responses/$id" ];then
                cat "$location/responses/$id"
                rm "$location/responses/$id"
                return 0
            fi
            sleep .1
        done
    done
    return 1
}

mailbox::serve() {
    local location=$1
    local handler=$2
    while true;do
        read -r < "$location/knock"
        mailbox::_handle_all "$location" "$handler"
    done
}

mailbox::handle_all() {
    for request in "$location/requests"/*;do
        if ! [ -f "$request" ];then
            continue
        fi
        mailbox::handle "$location" "$handler" "${request##$location/requests/}"
    done
}

mailbox::handle() {
    local location=$1
    local handler=$2
    local request=$3
    $handler < "$location/requests/$request" > "$location/responses/$request"
}

mailbox_test::_echo_srv() {
    local msg
    read -r msg
    echo "$msg"
}

mailbox_test::messaging() {
    import tmp
    
    local 
    tmp::create_dir 
}

mailbox_test::all() {
    unit::test mailbox_test::handler
}
