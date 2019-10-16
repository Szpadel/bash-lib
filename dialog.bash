#!/usr/bin/env bash

dialog__rc=""
dialog__backtitle=""
dialog__result=""

dialog::set_rc() {
    local rcfile=$1
    dialog__rc="$rcfile"
}

dialog::set_backtitle() {
    local title=$1
    dialog__backtitle="$title"
}

dialog::_dialog() {
    local options=()
    if [ -n "$dialog__backtitle" ];then
        options+=( "--backtitle" "$dialog__backtitle" )
    fi
    dialog__result="$(DIALOGRC="$dialog__rc" dialog --stdout "${options[@]}" "${DIALOG_EXTRA[@]}" "$@")"
}

# $1 - message
# $2 - name of *assoc* array with options
# $3 - order of keys in $2 in with it should be displayed
# $4 - optional height
# $5 - optional width
dialog::menu() {
    local msg=$1
    local -n _items=$2
    local -n _order=$3
    local height=${4:-0}
    local width=${5:-0}
    local options=()
    local key
    for key in "${_order[@]}";do
        options+=( "$key" "${_items[$key]}" )
    done
    if dialog::_dialog --menu "$msg" "$height" "$width" "$height" "${options[@]}";then
        return 0
    fi
    return 1
}

dialog::simple_list_select() {
    local msg=$1
    local list=$2
    local -n _output=$3
    local order=()
    local -A menu
    local line
    local n=0
    while IFS= read -r line;do
        order+=( "$n" )
        menu[$n]="$line"
        n=$((n+1))
    done < <(echo "$list")
    if dialog::menu "$msg" menu order 0 60;then
        # shellcheck disable=SC2034
        _output="${menu[$(dialog::result)]}"
        return 0
    fi
    return 1
}

dialog::file_selector() {
    local path=$1
    local entities=""
    local next
    while ! [ -f "$path" ];do
        entities="$(ls -ap --group-directories-first "$path")"
        dialog::simple_list_select "Select file\n$path" "$entities" next || return 1
        if [ -d "$path" ];then
            path+="/"
            path+="$next"
            path="$(realpath -s "$path")"
        fi
    done
    echo "$path"
}

dialog::dir_selector() {
    local path=$1
    local entities=""
    local next
    while [ "$next" != "./" ];do
        entities="$(ls -ap --group-directories-first "$path")"
        dialog::simple_list_select "Select . in directory you want to use\n$path" "$entities" next || return 1
        if [ -d "$path" ];then
            path+="/"
        fi
        path+="$next"
        path="$(realpath -s "$path")"
    done
    echo "$path"
}

# ( dialog::progress_percent 10; dialog::progress_msg "doing that" ) | dialog::progress "initialmsg" 5 100
dialog::progress() {
    local msg=$1
    local height=${2:-0}
    local width=${3:-0}
    dialog::_dialog --gauge "$msg" "$height" "$width"
}

dialog::progress_percent() {
    local pct=$1
    echo "$pct"
}

dialog::format_text() {
    local text=$1
    echo "$text" | sed ':a;N;$!ba;s/\n/\\n/g'
}

dialog::progress_msg() {
    local msg=$1
    echo "XXX"
    echo "$msg"
    echo "XXX"
}

dialog::yesno() {
    local msg=$1
    local height=${2:-0}
    local width=${3:-0}
    if dialog::_dialog --yesno "$msg" "$height" "$width";then
        return 0
    fi
    return 1
}

dialog::nextback() {
    local msg=$1
    local height=${2:-0}
    local width=${3:-0}
    if dialog::_dialog --yes-label "Next" --no-label "Back" --yesno "$msg" "$height" "$width";then
        return 0
    fi
    return 1
}

# Window with OK button
dialog::msg() {
    local msg=$1
    local height=${2:-0}
    local width=${3:-0}
    dialog::_dialog --msgbox "$msg" "$height" "$width"
}

# Just window with text
dialog::info() {
    local msg=$1
    local height=${2:-0}
    local width=${3:-0}
    dialog::_dialog --infobox "$msg" "$height" "$width"
}

dialog::input() {
    local msg=$1
    local height=${2:-0}
    local width=${3:-0}
    if dialog::_dialog --inputbox "$msg" "$height" "$width";then
        return 0
    fi
    return 1
}

dialog::pause() {
    local msg=$1
    local timeout=$2
    local height=${3:-8}
    local width=${4:-80}
    dialog::_dialog --pause "$msg" "$height" "$width" "$timeout" || return 1
}

dialog::input_required() {
    while true;do
        if dialog::input "$@" && [ -n "$(dialog::result)" ];then
            return 0
        else
            dialog::msg "You need to provide value for this field" 5 80
        fi
    done
}

dialog::edit_file() {
    local file=$1
    local height=${2:-0}
    local width=${3:-0}
    dialog::_dialog --editbox "$file" "$height" "$width" || return 1
    dialog::result > "$file"
}

dialog::result() {
    echo -n "$dialog__result"
}