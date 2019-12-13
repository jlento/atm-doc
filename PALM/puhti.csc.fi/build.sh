#!/bin/bash

# Install PALM 6.0 with RRTMG
# 2019-12-13, juha.lento@csc.fi

install_root=$(projappl)/palm

mkdir -p $install_root/{include/rrtmg-static,include/rrtmg-dynamic,lib}

module purge
module load intel/19.0.4 hpcx-mpi/2.4.0 intel-mkl/2019.0.4 fftw/3.3.8-mpi hdf5/1.10.4-mpi netcdf/4.7.0 netcdf-fortran/4.4.4 makedepf90

cd $TMPDIR
svn checkout --username NNN --password NNN https://palm.muk.uni-hannover.de/svn/palm/trunk palm


# RRTMG, building production versions. See `install_rrtmg` how to build
# debug versions.

cd palm/LIB/rrtmg
makedepf90 *.f90 > deps.mk

make -j 8 -f Makefile_static -f deps.mk F90=mpif90  PROG=librrtmg F90FLAGS="-O2 -cpp -r8 -nbs -convert little_endian -I${NETCDF_FORTRAN_INSTALL_ROOT}/include"
install -m 660 *.mod $install_root/include/rrtmg-static
install -m 660 librrtmg.a $install_root/lib
make -f Makefile_static clean

make -j 8 -f Makefile -f deps.mk F90=mpif90  PROG=librrtmg F90FLAGS="-O2 -cpp -r8 -nbs -convert little_endian -I${NETCDF_FORTRAN_INSTALL_ROOT}/include"
install -m 660 *.mod $install_root/include/rrtmg-dynamic
install -m 660 librrtmg.so $install_root/lib
make -f Makefile clean


# PALM

cd $TMPDIR/palm
PATH=$PWD/SCRIPTS:$PATH
palm_simple_build -b ifort.puhti
