#!/usr/bin/env bash
import exec

github::latest_release() {
    local _repo=$1
    local -n output_version=$2
    local _url
    _url=$(curl -f -w "%{url_effective}" -I -L -s -S "https://github.com/$_repo/releases/latest" -o /dev/null)
    if [ "$_url" != "https://github.com/$_repo/releases" ];then
        # shellcheck disable=SC2034
        output_version=$(echo -n "$_url"| sed -e 's|.*/||')
        return 0
    fi
    return 1
}

github::branch_archive_url() {
    local repo=$1
    local branch=$2
    echo "https://github.com/$repo/archive/$branch.tar.gz"
}

github::file_url() {
    local repo=$1
    local branch=$2
    local file="$3"
    echo "https://raw.githubusercontent.com/$repo/$branch/$file"
}

github::latest_commit() {
    local _repo=$1
    local _branch=$2
    local -n output_sha=$3
    exec::assert_cmd jq
    local _json
    _json=$(curl -f -s -L "https://api.github.com/repos/$_repo/commits/$_branch")
    local _sha=""
    if _sha=$(echo -n "$_json" | jq '.sha' -re);then
        # shellcheck disable=SC2034
        output_sha="$_sha"
        return 0
    fi
    return 1
}

github::release_file_url() {
    local repo=$1
    local version=$2
    local filename=$3
    echo "https://github.com/$repo/releases/download/$version/$filename"
}

