#!/bin/bash


remove-path () {
    local a
    IFS=':' eval 'a=(${!2})'
    a=( $(for e in "${a[@]}"; do [ "$e" == "$1" ] || echo "$e"; done) )
    IFS=':' eval "$2=\"\${a[*]}\""
}

append-path () {
    remove-path $1 $2
    eval "$2=${!2}:$1"
}

module-set () {
    conflicts=$(awk '/^conflict/{print $2}' <(module show $* 2>&1))
    module unload $conflicts
    module load $*
}

next-file () {
    fname=$1
    if [ -f "$fname" ]; then
	[[ "$fname" =~ ^(.+)\.([0-9]+)$ ]]
	if [ -n "${BASH_REMATCH[2]}" ]; then
	    echo "${BASH_REMATCH[1]}.$(( BASH_REMATCH[2] + 1 ))"
	else
	    echo "$fname.0"
	fi
    else
	echo "$fname"
    fi
}

backup-copy () {
    local fname=$1
    local nextfile=$(next-file $fname)
    if [ -f $fname ]; then
	backup-copy $nextfile && rm -f $nextfile && cp -p $fname $nextfile
    fi
}
