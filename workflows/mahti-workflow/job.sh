#!/bin/bash
#SBATCH -A project_2001659
#SBATCH -p test
#SBATCH -N 1
#SBATCH -t 10

# Run four copies of script 'single.sh' concurrently,
# each with own input???.txt argument from the zip file
# 'inputs.zip'

unzip -Z1 inputs.zip | xargs -L 1 -P 4 bash single.sh

