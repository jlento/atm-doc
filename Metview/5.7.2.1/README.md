# Metview 5.7.2.1

Metview 5.7.2.1 in a Singularity container, for puhti.csc.fi.

2019-11-28, juha.lento@csc.fi


## Container

Container `metview.sif` was built from `metview.def` in this
directory.


## Running the container

Currently the Singularity containers can only be run in the compute
nodes. Interactive compute nodes would be perfect, but "puhti-shell"
is not available yet.

Meanwhile, we have to reserve interactive batch job with `srun`
command with specified maximum runtime `-t`, memory `--mem`, thread
(core) number `-c`, account `-A`, plus options for the interactive job
`--x11=first --pty`. Running the Metview container itself is done
using `singularity run` command, with options `-H` and `-B` for making
`$HOME`, `/scratch` and `/projappl` directories accessible to the
container.

Defining an alias for launching Metview is not a bad idea, for example

```
alias metview="\
srun -t 120 --mem=2G -c 1 -A $DEFAULT_PROJECT --x11=first --pty\
  singularity run -H $HOME -B /scratch -B /projappl\
    /appl/soft/phys/metview/5.7.2.1/metview.sif\
"
```
