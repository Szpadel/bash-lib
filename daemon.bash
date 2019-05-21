#!/usr/bin/env bash

import dirdb
import log

daemon::start() {
    local db=$1
    local service_name=$2
    local cmd=$3
    local timeout=${4:-5}
    if ! daemon::is_running "$db" "$service_name";then
        daemon::_wrapper "$db" "$service_name" "$cmd" &
        daemon::wait_for_running "$db" "$service_name" "$timeout"
    fi
}

daemon::wait_for_running() {
    local db=$1
    local service_name=$2
    local wait_time=$3
    for ((t=0;t<wait_time*5;t++));do
        if daemon::is_running "$db" "$service_name";then
            return 0
        fi
        sleep .2
    done
    return 1
}

daemon::wait_for_stopped() {
    local db=$1
    local service_name=$2
    local wait_time=$3
    for ((t=0;t<wait_time*5;t++));do
        if ! daemon::is_running "$db" "$service_name";then
            return 0
        fi
        sleep .2
    done
    return 1
}

daemon::get_running() {
    local db=$1
    local -n output_var=$2
    local known_services
    dirdb::list "$db" "services" known_services
    output_var=()
    for srv in "${known_services[@]}";do
        if daemon::is_running "$db" "$srv";then
            output_var+=("$srv")
        fi
    done
}

daemon::_wrapper() {
    local db=$1
    local service_name=$2
    local cmd=$3
    dirdb::write "$db" "services/$service_name" "$BASHPID"
    log::debug "Started $service_name as $BASHPID"
    $cmd
    dirdb::delete "$db" "services/$service_name"
}

daemon::is_running() {
    local db=$1
    local service_name=$2
    if dirdb::is_exists "$db" "services/$service_name";then
        local pid
        pid=$(dirdb::read "$db" "services/$service_name")
        if kill -0 "$pid" &> /dev/null;then
            return 0
        else
            dirdb::delete "$db" "services/$service_name"
        fi
    fi
    return 1
}

daemon::stop_all() {
    local db=$1
    local timeout=${2:-30}
    local signal=${3:-INT}
    local services=()
    daemon::get_running "$db" services
    for srv in "${services[@]}";do
        daemon::stop "$db" "$srv" "$timeout" "$signal"
    done
}

daemon::stop() {
    local db=$1
    local service_name=$2
    local timeout=${3:-30}
    local signal=${4:-INT}
    if daemon::is_running "$db" "$service_name";then
        local pid
        pid=$(dirdb::read "$db" "services/$service_name")
        log::debug "Killing $service_name($pid) (SIG$signal)"
        kill "-$signal" "$pid"
        if ! daemon::wait_for_stopped "$db" "$service_name" "$timeout";then
            log::debug "killing $service_name($pid) (SIGKILL)"
            kill -9 "$pid"
        fi
    else
        log::debug "Service $service_name is not running"
    fi
}

daemon_test::_example_task() {
    sleep 1m &
    wait
}

daemon_test::spawn_and_kill() {
    import tmp

    local test_db
    tmp::create_dir test_db

    unit::assert_failed daemon::is_running "$test_db" "example"
    local running
    daemon::get_running "$test_db" running
    unit::assert_eq "${running[*]}" ""
    daemon::start "$test_db" "example" daemon_test::_example_task
    unit::assert_success daemon::is_running "$test_db" "example"
    daemon::get_running "$test_db" running
    unit::assert_eq "${running[*]}" "example"
    daemon::stop "$test_db" "example"
    unit::assert_failed daemon::is_running "$test_db" "example"
    daemon::get_running "$test_db" running
    unit::assert_eq "${running[*]}" ""

    tmp::cleanup
}

daemon_test::all() {
    unit::test daemon_test::spawn_and_kill
}
