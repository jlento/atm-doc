
** Unnecessary **

Simply

    module load bioconda

and follow the documentation there. The effect is the same as with the
longer story below...

Using Conda in puhti.csc.fi
===========================

Conda does not work well together with parallel filesystems that are
used in supercomputers, such as puhti.csc.fi. In particular, single
client performances is not stellar, which one notices as slow initial
starup times for applications installed with conda. Also, the per
project file number quotas are easily exceeded.

This document describes how to use Conda to install software on
parallel filesystem, if using environments provided by computing
center or singularity containers do not work.

The approach we take here is that we use a temporary Conda install,
and keep only the software installed with Conda, in a Conda
environment.


Installing Miniconda for one shot use
-------------------------------------

- Move to temporary directory

    cd $TMPDIR

- Download the bash installer:

    wget https://repo.anaconda.com/miniconda/Miniconda3-latest-Linux-x86_64.sh

- Run installer

    bash Miniconda3-latest-Linux-x86_64.sh -b -p $PWD/miniconda3


- Initialize conda

    source miniconda3/etc/profile.d/conda.sh

- Config Conda to always copy files to environment instead of hard
  linking them to pkgs directory

    conda config --set always_copy True


Creating an environment with environment.yaml file
--------------------------------------------------

- Write an example file `python.yaml`

    name: python
    channels:
        - conda-forge
    dependencies:
        - conda
        - python
        - pip

- Create environment

    conda env create -f python.yaml -p /projappl/<project>/envs/python


Clean up
--------

- Optionally, return Conda config to default (using hard links)

    conda config --set always_copy False

- Remove Conda from TMPDIR

    rm -r miniconda3


Using the environment
---------------------

- Activate the environment

    source /projappl/<project>/envs/python/etc/profile.d/conda.sh
    conda activate /projappl/<project>/envs/python

