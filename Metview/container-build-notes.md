# Interactive shell

Everything is better with SSD :)

```
srun -A project_2001659 -p small --x11=first --pty -t 120 \
    --mem=4G -c 4 --gres=nvme:500 $SHELL
```


# ECMWF Docker container for metview (no GUI ?!?)

Something like this could almost work...

```
unset XDG_RUNTIME_DIR
TMPDIR=$LOCAL_SCRATCH
singularity shell -W $LOCAL_SCRATCH -H $HOME docker://ecmwf/jupyter-notebook
```

...but maybe not. Just jump ahead.


# Building Singularity container with Metview app

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

Create container definition file:

```
cat > metview.def <<EOF
BootStrap: library
From: ubuntu:16.04

%post
    apt-get -y update
    apt-get -y install metview

%environment
    export LC_ALL=C

%runscript
    metview
EOF
```

Build container on remote builder:

```
singularity build --remote $LOCAL_SCRATCH/metview.sif metview.def
```

or get it with (you get <library> from https://cloud.sylabs.io/builder )

```
singularity pull <library>
```

if already built.

Run the container:

```
singularity shell -H $HOME -B /scratch rb-5ddb5ebdb84987019195021e_latest.sif
```

