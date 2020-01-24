# Building Singularity container in puhti.csc.fi

2019-11-26, juha.lento@csc.fi


## Interactive shell in compute node

Singularity is only in compute nodes. While we are on it, let's grab
some SSD :)

```
srun -A project_2001659 -c 4 --pty --x11=first -t 120 --gres=nvme:500 --mem=16G $SHELL
```


## Configure remote builder

Get remote builder (Sylabs.io) access token, and paste it to

```
cat > ~/.singularity/remote.yaml <<EOF
Active: SylabsCloud
Remotes:
  SylabsCloud:
    URI: cloud.sylabs.io
    Token: <paste token here>
    System: true
EOF
```

## Build Singularity container with Metview app

The definition file `metview.def` is in this directory.

NOTE: Wait for the build to finish, do not interrupt it, even when
knowing it will not produce intended container.

```
export SINGULARITY_TMPDIR=$LOCAL_SCRATCH
export SINGULARITY_CACHEDIR=$LOCAL_SCRATCH
unset XDG_RUNTIME_DIR PROMPT_COMMAND
TMPDIR=$LOCAL_SCRATCH

singularity build --remote $LOCAL_SCRATCH/metview.sif metview.def
```

Test the container:

```
singularity run -W $LOCAL_SCRATCH -H $HOME -B $LOCAL_SCRATCH -B /scratch $LOCAL_SCRATCH/metview.sif
```

