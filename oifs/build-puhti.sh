#!/bin/bash

# Build notes for OpenIFS in puhti.csc.fi
# juha.lento @ csc.fi, 2022-19-03
# juha.lento @ csc.fi, 2019-09-09

cd $TMPDIR
lftp -u openifs,XXXXXXXXXXX -e 'get oifs43r3v2.tar.gz' ftp://ftp.ecmwf.int/src/openifs/43r3
tar xvf oifs43r3v2.tar.gz
cd oifs43r3v2

module load intel-oneapi-compilers-classic intel-oneapi-mpi intel-oneapi-mkl eccodes fftw netcdf-c netcdf-fortran


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

alias omake="fcm make -v -j4 -f $OIFS_HOME/make/oifs.fcm"
alias omakenew="fcm make --new -v -j4 -f $OIFS_HOME/make/oifs.fcm"
alias oenv='env|grep OIFS_'

# Build

omake



