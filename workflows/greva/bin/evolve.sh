#!/bin/bash
#SBATCH -n 2
#SBATCH -t 15
#SBATCH -p test

# This script can be run as a SLURM batch job, or interactively. Default number
# of parallel tasks to run in an interactive job is 2, but can be overridden
# with environment variable USER_NTASKS.

set -e

#module purge
#module load gcc intelmpi

BINDIR=/homeappl/home/jlento/github/jlento/atm-doc/workflows/greva/bin

select=${BINDIR}/select
exewrap=${BINDIR}/exewrap.sh
exe=${BINDIR}/fooexe
#exe=${BINDIR}/elli.e

parfile=$(readlink -f $1)
workdir=$(readlink -f $2)

cd $workdir

zero_pad_u2 () {
    printf "%05d" $1
}

is_slurm_batch_job () {
    [ -n "$SLURM_JOB_ID" ]
}

if is_slurm_batch_job; then
    ntasks=$SLURM_NTASKS
    nodefile=$(generate_pbs_nodefile)
    sed -i 's|^|1/|' $nodefile
    multinodeopts="-M --sshloginfile $nodefile"
else
    ntasks=${USER_NTASKS:-2}
fi

# Find the lastest generation in workdir

startgen=$(ls -d [0-9][0-9][0-9][0-9][0-9] | tail -1)

generations_per_batch=2

stopgen=$(( startgen + generations_per_batch ))

# This function generates the command line arguments for each individual
# exewrap.sh
generate_args () {
    local parentgen=$(readlink -f $(zero_pad_u2 $1))
    local childgen=$(readlink -f $(zero_pad_u2 $(( $1 + 1 ))))
    local parents=$(cat ${parentgen}/[0-9][0-9][0-9][0-9][0-9]/fitness | $select | sort -n)
    local c=0
    local p
    local parents
    for p in $parents; do
        echo "${parentgen}/$(zero_pad_u2 $p) ${childgen}/$(zero_pad_u2 $c)"
        (( c++ ))
    done
}


# Generations are run sequentially, individuals within generation are run in
# parallel

for (( parentgen = startgen; parentgen < stopgen; parentgen++ )); do
    parallel --gnu -j $ntasks $multinodeopts --halt 2 --env PATH --env LD_LIBRARY_PATH --env PYTHONPATH $exewrap $exe $parfile  <<<"$(generate_args ${parentgen})"
done
