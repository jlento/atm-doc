#!/bins/bash

# Build notes for eumetsat rttov 13.1 in puhti.csc.fi
# 2022-10-06, juha.lento@csc.fi

# Currently Loaded Modules:
# 1) csc-tools (S)   3) intel-oneapi-compilers-classic/2021.6.0   5) intel-oneapi-mpi/2021.6.0   7) hdf5/1.12.2-mpi
# 2) StdEnv          4) intel-oneapi-mkl/2022.1.0                 6) netcdf-fortran/4.5.4

mkdir -p $TMPDIR/rttov
cd $TMPDIR/rttov
tar xvf ~/software-downloads/rttov131.tar.xz
cd build
cp ~/atm-doc/eumetsat/rttov/Makefile.local .
# Interactive, compiler flag file = 'ifort-openmp'
./rttov_compile.sh

