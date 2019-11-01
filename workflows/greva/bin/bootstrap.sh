#!/bin/bash

usage="
Usage: bash bootstrap.sh STARTFILE WORKDIR POPSIZE

Sets up the 0th generation,

WORKDIR/
        00000/
                00000/
                    individual.dat
                    fitness
                00001/
                    individual.dat
                    fitness
               ...
              POPSIZE/
                    individual.dat
                    fitness
"

set -e

startfile=$(readlink -f $1)
workdir=$(readlink -f $2)
population=$3
generation=0

zero_pad_u2 () {
    printf "%05d" $1
}

outdir=${workdir}/$(zero_pad_u2 $generation)

mkdir -p $outdir
cd $outdir

for (( i = 0; i < population; i++ )); do
    individual=$(zero_pad_u2 $i)
    mkdir $individual
    cp $startfile $individual/individual.dat
    echo "1.0" > ${individual}/fitness
done
