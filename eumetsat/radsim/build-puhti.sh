#!/bins/bash

# Build notes for eumetsat radsim 3.1 in puhti.csc.fi
# 2022-10-06, juha.lento@csc.fi

# Currently Loaded Modules:
# 1) csc-tools (S)   3) intel-oneapi-compilers-classic/2021.6.0   5) intel-oneapi-mpi/2021.6.0   7) hdf5/1.12.2-mpi
# 2) StdEnv          4) intel-oneapi-mkl/2022.1.0                 6) netcdf-fortran/4.5.4        8) eccodes/2.25.0

cd $TMPDIR
tar xvf ~/software-downloads/radsim-3.1.tar.gz
cd radsim-3.1
rsync --backup ~/atm-doc/eumetsat/radsim/user.cfg user.cfg
rsync --backup ~/atm-doc/eumetsat/radsim/ifort.cfg build/cfg/ifort.cfg
sed -i'~' 's/hdf5hl_fortran/hdf5_hl_fortran/' build/cfg/common.cfg
./radsim_install

