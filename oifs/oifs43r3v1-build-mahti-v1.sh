#!/bin/bash

# puhti.csc.fi
# juha.lento @ csc.fi, 2020-09-01

cd $TMPDIR
tar xvf oifs43r3v1.tar.gz
cd oifs43r3v1

module load perl fftw openblas netcdf-c netcdf-fortran eccodes


# Stripped version of oifs-config.editme.sh

export OIFS_HOME=$PWD
export OIFS_DATA_DIR="<editme>"
export OIFS_INIDATA_DIR="<editme>"
export OIFS_LAPACK_INCLUDE="-I${OPENBLAS_INSTALL_ROOT}/include"
export OIFS_LAPACK_LIB="-lopenblas"
export OIFS_NETCDF_INCLUDE="-I$NETCDF_FORTRAN_INSTALL_ROOT/include -I$NETCDF_C_INSTALL_ROOT/include"
export OIFS_NETCDF_LIB="-lnetcdff -lnetcdf -L/appl/spack/v014/install-tree/gcc-9.3.0/zlib-1.2.11-ll4b3c/lib -lz -Wl,-rpath=/appl/spack/v014/install-tree/gcc-9.3.0/zlib-1.2.11-ll4b3c/lib"
export OIFS_GRIB_DIR=$ECCODES_INSTALL_ROOT
export OIFS_COMP=gnu
export OIFS_BUILD=opt
export OIFS_RUNCMD='srun'
export OIFS_FC=mpif90
export OIFS_CC=mpicc

export PATH=${PATH}:${OIFS_HOME}/fcm/bin:${OIFS_GRIB_DIR}/bin

alias omake="fcm make -v -j4 -f $OIFS_HOME/make/oifs.fcm"
alias omakenew="fcm make --new -v -j4 -f $OIFS_HOME/make/oifs.fcm"
alias oenv='env|grep OIFS_'

# Build

omake



