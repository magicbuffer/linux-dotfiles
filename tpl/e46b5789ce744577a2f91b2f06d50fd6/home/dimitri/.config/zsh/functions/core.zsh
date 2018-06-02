#!/bin/env zsh

# copied from grml
function zrcgotwidget()
{
    (( ${+widgets[$1]} ))
}

# copied from grml
function zrcgotkeymap()
{
    [[ -n ${(M)keymaps:#$1} ]]
}

# copied from grml
function zrcbindkey()
{
    if (( ARGC )) && zrcgotwidget ${argv[-1]}; then
        bindkey "$@"
    fi
}

# copied from grml
function bind2maps ()
{
    local i sequence widget
    local -a maps

    while [[ "$1" != "--" ]]; do
        maps+=( "$1" )
        shift
    done
    shift

    if [[ "$1" == "-s" ]]; then
        shift
        sequence="$1"
    else
        sequence="${key_info[$1]}"
    fi
    widget="$2"

    [[ -z "$sequence" ]] && return 1

    for i in "${maps[@]}"; do
        zrcbindkey -M "$i" "$sequence" "$widget"
    done
}

