#!/usr/bin/env bash

terminal::get_cursor_position() {
    local x
    local y
    IFS=';' read -sdRr -p $'\E[6n' y x
    echo "$x $y"
}

terminal::get_height() {
    tput lines
}

terminal::get_width() {
    tput cols
}
