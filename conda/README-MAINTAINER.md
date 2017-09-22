Building software that runs on the login-nodes using conda
==========================================================

This documentation is for the [conda](https://conda.io/docs/) software stack "maintainers."


Installing Miniconda
--------------------

- Download the bash installer:

    wget https://repo.continuum.io/miniconda/Miniconda2-latest-Linux-x86_64.sh

- Run installer (option `-p PREFIX` can be used to specify the install
  directory):

    bash Miniconda2-latest-Linux-x86_64.sh -b -p $HOME/miniconda2


Activating conda
----------------

- Add conda to PATH:

    export PATH=$HOME/miniconda2:$PATH


Adding conda package repositories (channels)
--------------------------------------------

- Add conda channels

    conda config --add channels conda-forge
    conda config --add channels bioconda


Building new conda packages
---------------------------

- Do the steps above

- Use base OS system compilers. If the systems uses environment
  modules, for example, remove them from the PATH with:

    module purge
    module load cmake git

  You can check the version that is in the PATH with `which gcc`, for example.


