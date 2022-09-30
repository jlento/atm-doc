#!/bin/bash

# Nemo (+xios) buld in puhti.csc.fi

# 2022-09-30, juha.lento@csc.fi, adaptation to puhti.csc.fi rhel8
# 2022-09-02, Jona Mac Intyre

buildroot=$TMPDIR
xios_install_root=$buildroot/xios

# Xios

cd $buildroot
svn co http://forge.ipsl.jussieu.fr/ioserver/svn/XIOS/trunk xios
cd xios

cat > arch/arch-puhti-intel.env <<EOF
module load intel-oneapi-compilers-classic
module load intel-oneapi-mpi
module load hdf5/1.12.2-mpi
module load netcdf-c
module load netcdf-fortran
module load boost/1.79.0-mpi
EOF

cat > arch/arch-puhti-intel.fcm <<EOF
%CCOMPILER      mpicc
%FCOMPILER      mpif90
%LINKER         mpif90 -nofor-main

%BASE_CFLAGS    -diag-disable 1125 -diag-disable 279 -std=c++11
%PROD_CFLAGS    -O2 -D BOOST_DISABLE_ASSERTS -xHost
%DEV_CFLAGS     -g -traceback -xHost -fp-model precise
%DEBUG_CFLAGS   -DBZ_DEBUG -g -traceback -fno-inline -xHost -fp-model precise

%BASE_FFLAGS    -D__NONE__
%PROD_FFLAGS    -O2
%DEV_FFLAGS     -g -O2 -traceback -xHost -fp-model precise
%DEBUG_FFLAGS   -g -traceback

%BASE_INC       -D__NONE__
%BASE_LD        -lstdc++

%CPP            mpicc -EP
%FPP            cpp -P
%MAKE           make
EOF

cat > arch/arch-puhti-intel.path <<EOF
NETCDF_LIB="-lnetcdff -lnetcdf"
HDF5_LIB="-lhdf5_hl -lhdf5"
EOF

./make_xios --arch puhti-intel --prod --full --job 16


# nemo (~4.2.0)

source $buildroot/xios/arch/arch-puhti-intel.env

cd $buildroot
git clone https://forge.nemo-ocean.eu/nemo/nemo.git nemo
cd nemo

cat > arch/arch-puhti-intel.fcm <<EOF
%CC                  mpicc
%CFLAGS              -O2 -march=native -mtune=native
%CPP                 cpp
%FC                  mpif90 -c -cpp -fpp
%FCFLAGS             -g -i4 -r8 -O2 -fp-model precise -march=native -mtune=native -qoverride-limits -fno-alias -qopt-report=4 -align array64byte -traceback
%FFLAGS              %FCFLAGS
%LD                  mpif90
%LDFLAGS             -lstdc++
%FPPFLAGS            -P -traditional
%AR                  ar
%ARFLAGS             rs
%MK                  make

%XIOS_HOME           $xios_install_root

%NCDF_INC
%NCDF_LIB            -lnetcdff -lnetcdf -lhdf5_hl -lhdf5 -lhdf5
%XIOS_INC            -I%XIOS_HOME/inc
%XIOS_LIB            -L%XIOS_HOME/lib -lxios -lstdc++

%USER_INC            %XIOS_INC %NCDF_INC
%USER_LIB            %XIOS_LIB %NCDF_LIB
EOF

./makenemo -r ORCA2_ICE_PISCES -m puhti-intel -j 16
