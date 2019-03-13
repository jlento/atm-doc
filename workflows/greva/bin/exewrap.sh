#!/bin/bash

# Run single individual
#
# Usage: bash exewrap.sh EXE PARFILE PARENTDIR CHILDDIR

# module purge
# module load ...

set -e

RUNTIME=413000

exe=$1
parfile=$2
read parentdir childdir <<<"$3"

# Generates N random integers between 0-65536

random_u2 () {
    local n=${1:?Usage: random_u2 N}
    od -An -N$(( 2 * n )) -w2 -t u2 < /dev/urandom | tr '\n' ' '
}

# Prepare input file

mkdir -p $childdir
sed "73s/.*/$(random_u2 12)/" ${parentdir}/individual.dat \
    > ${childdir}/individual.dat

# Run exe

cd $childdir
$exe individual.dat 2 $RUNTIME 1 $parfile
