#!/bin/bash

set -e

cache_dir=cache
mkdir -p $cache_dir

twidth=$(tput cols)
theight=$(tput lines)

cow_width=40
cow_height=10

box () {
    local s="$(cat)"
    local x f ss
    read x f <<<$(wc -L <<<"$s")
    while IFS='' read -r ss || [[ -n "$ss" ]]; do
        printf "%-${x}s\n" "$ss"
    done <<<"$s"
}

alignbl () {
    local s="$(cat)"
    local w=$1
    local h=$2
    local x y f i ss
    read y x f <<<$(wc -l -L <<<"$s")
    if (( x > w )); then
        echo "Too wide to fit into the box ($w,$h):" >&2
        echo "$s" >&2
        return 1
    fi
    if (( y > h )); then
        echo "Too high to fit into the box ($w,$h):" >&2
        echo "$s" >&2
        return 1
    fi
    for i in $(seq 1 $((h-y))); do
        printf "%${w}s\n" " "
    done
    while IFS='' read -r ss || [[ -n "$ss" ]]; do
        printf "%-${w}s\n" "$ss"
    done <<<"$s"
}

cow () {
    local h=$(md5sum <<<"cow $1" | cut -f 1 -d ' ')
    local cache_file=${cache_dir}/$h.mp3
    if [ ! -f $cache_file ]; then
        curl -G -d 'ie=UTF-8' -d 'client=tw-ob' --data-urlencode "q=$1" -d 'tl=en' \
             -H 'Referer: http://translate.google.com/' \
             -H 'User-Agent: stagefright/1.2 (Linux;Android 5.0)' \
             'https://translate.google.com/translate_tts'  > $cache_file
    fi
    local y=$(( theight - cow_height - 1 ))
    tput cup $y 0 && cowsay -W $((cow_width-4)) "$1" | box | alignbl $cow_width $cow_height
    $mplayer -really-quiet -noconsolecontrols ${cache_dir}/$h.mp3 2> /dev/null
}

tput sc

# Quick test run to catch errors and cache voices
mplayer=:
source $1 > /dev/null

mplayer=mplayer
source $1

tput rc
