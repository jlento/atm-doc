# Evolution workflow example

## Outline

The goal is to run an evolution process, a sequence of generations of
individuals. Each individual in a generation is independent and can be run in
parallel. Between each generation, there is a selection from the parent
generation's individuals, that determines the individuals for the next
generation.

## Computational considerations

The complete evolution consist of 4000 generations, each with 200 individuals.
Running each individual takes roughly one minute. One minute run is too short
for an efficient stand-alone batch job, and the shear number of jobs is too much
for the sheduling and accounting system. On the other hand, the computations
need to be run in parallel as much as possible. The contents of this repository
outline a workflow that can be used to pack multiple individual runs into a
larger batch job.

## Example implementation

### Directory hierarchy

The workflow scripts are in directory [bin], and the single evolution experiment
input files are in directory [experiment-b30612].

Each generation is a subfolder in the working directory, and contains subfolders
for each individual. Directory names for generations and individuals are numbers
from 00000 onwards.

### Scripts

The zeroth generation is prepared separately, using script [bin/bootstrap.sh].
The evolution algorithm is in script [bin/evolve.sh]. Script `evolve.sh` checks
what is the latest generation on the work directory, and continues from there.

For each generation in sequence, script `evolve.sh` calls selection program to
determine all parent -- child pairs, and forwards each pair as an argument to
multiple parallel invocations of the script [bin/exewrap.sh]. Script
`exewrap.sh` contains all steps that are needed to run a single individual from
a given parent.

#### bootstrap.sh

`Usage: bash bootstrap.sh STARTFILE WORKDIR POPSIZE`

Run `bootstrap.sh` to generate 0th generation. For example,

    ./bin/bootstrap.sh experiment-b30612/b30612.dat $WRKDIR/b30612 6

#### evolve.sh

`Usage: sbatch evolve.sh PARFILE WORKDIR`

Continue evolution from where the last batch job left it, with for example

    sbatch ./bin/evolve.sh experiment-b30612/b30612rates.par $WRKDIR/b30612

or, while developing, run interactively with

    ./bin/evolve.sh experiment-b30612/b30612rates.par $WRKDIR/b30612

[bin/bootstrap.sh]: bin/bootstrap.sh
[bin/evolve.sh]: bin/evolve.sh
[experiment-b30612]: experiment-b30612
[bin/exewrap.sh]: bin/exewrap.sh
