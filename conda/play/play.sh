#!/bin/bash

export cache_dir=cache
mkdir -p $cache_dir

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
    local h w f ss
    read h w f <<<$(wc -l -L <<<"$s")
    for i in $(seq 1 $(( $2 - h ))); do
        printf "%${1}s\n" " "
    done
    while IFS='' read -r ss || [[ -n "$ss" ]]; do
        ss="$(printf "%-${w}s" "$ss")"
        case $3 in
            bottom-right)
                printf "%${1}s\n" "$ss"
                ;;
            bottom-left)
                printf "%-${1}s\n" "$ss"
                ;;
            *)
                echo "Unknown alignment '$a' in box()" >&2
                return 1
                ;;
        esac
    done <<<"$s"
}

# Deal with dumb cows
silence () {
    if [[ -n "$1" ]]; then
        cat
    else
        sed '1,3s/.*/ /;4,5s/\\/ /'
    fi
}

draw () {
    local t="$(cat)"
    local x y w h a
    read -r x y w h a <<<"$1"
    shift 
    local s
    local i=0
    echo "$t" | cowsay -W $(( w - 4 )) "$@" | silence "$t" | box $w $h $a | \
        while IFS='' read -r s || [[ -n "$s" ]]; do
            tput cup $((y + i)) $x
            ((i++))
            printf "%s" "$s"
        done
}

play () {
    tmux new-session -s play "bash $1"
}

the-end () {
    tmux kill-session -t play
}

requires tmux tput cowsay mplayer espeak curl

export -f requires draw box play silence the-end

# Quick test run to catch errors and cache voices
#alias say=:
#
#tmux kill-session -t play

# The play
#mplayer=mplayer
#source $1


# Attic of ideas

# xcowsay 'Hello dude!' --at=50,400 & xcowsay --at=900,500 --image=mcow_med.png -l 'Hello to yourself!'


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
