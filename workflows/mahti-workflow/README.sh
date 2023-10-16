#!/bin/bash

# A workflow example for running 4 concurrent MPI programs, with
# pre- and post-processing steps
#
# 2023-10-16, juha.lento@csc.fi
#
# Files:
#     README.sh
#     job.sh
#     single.sh
#     process.f90

# Generate zip archive 'inputs.zip' of the input files
# input000.txt .. input020.txt

for i in {000..020}
do
    mkfifo input${i}.txt
    echo "Parameter: ${i}" > input${i}.txt &
    zip --grow --fifo inputs.zip input${i}.txt
    rm input${i}.txt
done

# Build the processing program

mpif90 -o process process.f90

# Submit the workflow

sbatch job.sh
