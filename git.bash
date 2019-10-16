#!/usr/bin/env bash

import dialog

git::_git() {
    local path=$1
    shift
    (
        cd "$path"
        git "$@"
    ) || return 1
}

git::is_git_repo() {
    local path=$1

    [ -d "$path/.git" ] || return 1
}

git::is_dirty() {
    local path=$1

    git::_git "$path" diff --quiet || return 0
    return 1
}

git:::tag() {
    local path=$1
    local sha=$2
    local tag=$3
    local msg=$4

    if [ -n "$msg" ];then
        git::_git "$path" -m "$msg" "$tag" "$sha"
    else
        git::_git "$path" "$tag" "$sha"
    fi
}

git::tag2commit_ref() {
    local path=$1
    local tag=$2

    local output
    output="$(git::_git "$path" tag -l --format '%(objectname) %(*objectname)' "$tag")"
    local tag_ref
    local chained_ref
    tag_ref="$(cut -d' ' -f1 <<< "$output")"
    chained_ref="$(cut -d' ' -f2 <<< "$output")"

    if [ -n "$chained_ref" ];then
        echo "$chained_ref"
    elif [ -n "$tag_ref" ];then
        echo "$tag_ref"
    else
        return 1
    fi
}

git::find_commit_containing() {
    local path=$1
    local commit_content=$2

    local sha
    sha="$(git::_git "$path" log --all --grep "$commit_content" --pretty='format:%H')"
    if [ -n "$sha" ];then
        echo "$sha"
    else
        return 1
    fi
}

git::clone_progress() {
    local path=$1
    local repo=$2
    local repo_display=${3:-$repo}
    (
        dialog::progress_msg "Cloning $repo_display"
        # There are 4 passes with progress when clonning git repo, last awk command make every 100 worth 25%
        git clone "$repo" "$path" --progress 2>&1 | stdbuf -i0 -o0 -e0 tr '\r' '\n' | stdbuf -i0 -o0 -e0 grep -o "[0-9]\{1,2\}\%" | stdbuf -i0 -o0 -e0 grep -o '[0-9]*' | stdbuf -i0 -o0 -e0 awk "BEGIN{p=0;x=0} {if(\$1 < p) {x+=25;print x} else {print x+(\$1/4)};p=\$1 }"
    ) | dialog::progress "git clone" 8 80
    if ! [ -d "$path/.git" ];then
        dialog::msg "Failed to clone $repo"
        return 1
    fi
}