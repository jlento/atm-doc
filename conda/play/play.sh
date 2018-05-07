#!/bin/bash

set -e

requires () {
    local missing=false
    while [ -n "$1" ]; do
        which "$1" 2>&1 > /dev/null || {
            missing=true
            echo "Required tool '${1}' missing." >&2
        }
        shift
    done
    if $missing; then
        return 1
    else
        return 0
    fi
}

box () {
    local s="$(cat)"
    local x f ss
    read x f <<<$(wc -L <<<"$s")
    while IFS='' read -r ss || [[ -n "$ss" ]]; do
        printf "%-${x}s\n" "$ss"
    done <<<"$s"
}

blbox () {
    local s="$(cat)"
    local x=$1
    local y=$2
    local w=$3
    local h=$4
    local hh ww f i ss
    read hh ww f <<<$(wc -l -L <<<"$s")
    if (( ww > w )); then
        echo "Too wide to fit into the box ($w,$h):" >&2
        echo "$s" >&2
        return 1
    fi
    if (( hh > h )); then
        echo "Too high to fit into the box ($w,$h):" >&2
        echo "$s" >&2
        return 1
    fi
    tput cup $y 0
    local skip=":"
    if (( x > 0 )); then
        skip="tput cuf $x"
    fi
    for i in $(seq 1 $((h-hh))); do
        $skip; printf "%${w}s\n" " "
    done
    while IFS='' read -r ss || [[ -n "$ss" ]]; do
        $skip; printf "%-${w}s\n" "$ss"
    done <<<"$s"
}

actor () {
    local looks=$1
    local voice=$2
    local x=$3
    local y=$4
    local w=$5
    local h=$6
    local s="$7"
    if [ -z "$s" ]; then
        local im=$(cat /usr/share/cowsay/cows/${looks}.cow | \
                       sed -rn '/EOC/,/EOC/{s/\$thoughts/ /;s/\$eyes/oo/;s/\$tongue/  /;s/\\(.)/\1/g;/EOC/!p}')
        echo "$im" | blbox $x $y $w $h
        return 0
    fi
    local fname=$(md5sum <<<"$type $voice $s" | cut -f 1 -d ' ')
    local cache_file=${cache_dir}/${fname}
    if [ ! -f $cache_file ]; then
        case $voice in
            mplayer)
                curl -G -d 'ie=UTF-8' -d 'client=tw-ob' --data-urlencode "q=$s" -d 'tl=en' \
                     -H 'Referer: http://translate.google.com/' \
                     -H 'User-Agent: stagefright/1.2 (Linux;Android 5.0)' \
                     'https://translate.google.com/translate_tts'  > $cache_file
                ;;
            espeak)
                espeak -w $cache_file "$s"
                ;;
            *)
                echo "Unimplemented voice '$voice'." >&2
                return 1
                ;;
        esac
    fi
    cowsay -f $looks -W $((w - 4)) "$s" | blbox $x $y $w $h
    $mplayer -really-quiet -noconsolecontrols ${cache_file} 2> /dev/null
}


koala () {
    actor koala espeak 0 $((console_height)) 35 10 "$1"
}

cow () {
    actor default mplayer 35 $((console_height)) 44 10 "$1"
}

# Voice cache
cache_dir=cache
mkdir -p $cache_dir

# Scene
term_width=$(tput cols)
term_height=$(tput lines)

# Console window
let "console_height = term_height - 11"

# Check requirements
requires mplayer espeak cowsay curl tput

tput sc

# Quick test run to catch errors and cache voices
mplayer=:
source $1 > /dev/null

# The play
mplayer=mplayer
source $1

tput rc


# Attic of ideas

# xcowsay 'Hello dude!' --at=50,400 & xcowsay --at=900,500 --image=mcow_med.png -l 'Hello to yourself!'
