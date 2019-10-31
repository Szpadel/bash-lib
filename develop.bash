#!/usr/bin/env bash

import exec
import git

develop::lint() {
    local dir=$1
    shift
    local files_raw
    local files
    if ! develop::is_in_dev_mode "$dir";then
        # we are not in git or git ins't dirty, then we run in production mode
        return 0
    fi
    exec::is_cmd_available shellcheck || return 0
    log::info "Running in development mode, linting files first"
    files_raw=$(find -L "$dir" -type f -name '*.bash' -not -path "$dir/.*")
    log::info "Linting: ${files_raw}"
    mapfile -t files <<< "$files_raw"
    exec::exec_preview develop::_shellcheck "$dir" "$@" "${files[@]}" || log::fatal "There are issues in source code, aborting"
    log::success "Lint succeed, continuing"
}

develop::is_in_dev_mode() {
    local dir=$1
    if git::is_git_repo "$dir" && git::is_dirty "$dir";then
        return 0
    fi
    return 1
}

develop::_shellcheck() {
    local dir=$1
    shift
    echo "DEV MODE: Linting..."
    (
        cd "$dir" || return 1
        shellcheck -Calways -S style "$@"
    )
}