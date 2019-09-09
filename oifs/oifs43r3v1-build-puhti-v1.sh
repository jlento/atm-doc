#!/bin/bash

# !!! OpenIFS test version !!!

# puhti.csc.fi
# juha.lento @ csc.fi, 2019-09-09

cd $TMPDIR
scp $USER@taito.csc.fi:/proj/atm/oifs/oifs43r3v1.tar.gz .
tar xvf oifs43r3v1.tar.gz
cd oifs43r3v1

# In addition to default environment,
#
#     intel/19.0.4 hpcx-mpi/2.4.0 intel-mkl/2019.0.4
#
module load perl eccodes/2.5.0 fftw/3.3.8-mpi netcdf/4.7.0 netcdf-fortran/4.4.4 


# Stripped version of oifs-config.editme.sh

export OIFS_HOME=$PWD
export OIFS_DATA_DIR="<editme>"
export OIFS_INIDATA_DIR="<editme>"
export OIFS_LAPACK_INCLUDE="-mkl=sequential"
export OIFS_LAPACK_LIB="-mkl=sequential"
export OIFS_NETCDF_INCLUDE="-I$NETCDF_FORTRAN_INSTALL_ROOT/include -I$NETCDF_INSTALL_ROOT/include"
export OIFS_NETCDF_LIB="-L$NETCDF_FORTRAN_INSTALL_ROOT/lib -lnetcdff -L$NETCDF_INSTALL_ROOT/lib -lnetcdf -lz -lrt"
export OIFS_GRIB_DIR=$ECCODES_INSTALL_ROOT
export OIFS_COMP=intel
export OIFS_BUILD=opt
export OIFS_RUNCMD='srun'
export OIFS_FC=mpif90
export OIFS_CC=mpicc

export PATH=${PATH}:${OIFS_HOME}/fcm/bin:${OIFS_GRIB_DIR}/bin

alias omake="fcm make -v -j4 -f $OIFS_HOME/make/oifs.cfg"
alias omakenew="fcm make --new -v -j4 -f $OIFS_HOME/make/oifs.cfg"
alias oenv='env|grep OIFS_'

# Build

omake



