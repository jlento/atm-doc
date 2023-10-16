#!/bin/bash

infile=$1
outfile=output${1//[^0-9]/}.txt

# Pre-processing step

unzip inputs.zip $infile

# Simulation step

srun --exact -n 32 --mem=50G process $infile $outfile

# Post-processing step

zip --grow outputs.zip $outfile
rm $infile $outfile
