#!/usr/bin/env bash
import tmp
import exec

fetch__tmp=""

fetch::_init() {
    if [ -z "$fetch__tmp" ];then
        tmp::create_dir fetch__tmp bash-lib-fetch
    fi
}

fetch::download_to_file() {
    local url="$1"
    local filename="$2"
    tmp::create_file filename "" "$fetch__tmp"
    exec::silent curl -o "$filename" -sfL "$url"
    echo "$filename"
}

fetch::download_stream() {
    local url=$1
    curl -sfL "$url"
}

fetch::file_exists() {
    local url=$1
    if curl --output /dev/null --silent --head --fail -L "$url";then
        return 0
    else
        return 1
    fi
}

fetch::verify() {
    local sha=$1
    local file=$2
    local actual
    actual=$(sha256sum "$file" | awk '{print $1}')
    if [ "$sha" != "$actual" ];then
        log::panic "Sha256 does not match. Expected ${sha} but got ${actual}"
    fi
}
