#!/bin/bash

# mahti.csc.fi
 juha.lento @ csc.fi, 2021-06-14

export install_dir=/projappl/project_2003423/$USER

module load fftw openblas hdf5/1.10.7-mpi netcdf-c netcdf-fortran eccodes


# XIOS

cd $TMPDIR
svn co http://forge.ipsl.jussieu.fr/ioserver/svn/XIOS/branchs/xios-2.5   xios-2.5
cd xios-2.5

cat > arch/arch-OIFS.env <<'EOF'
module load gcc
module load openmpi
module load hdf5/1.10.7-mpi
module load netcdf-c/4.8.1
module load netcdf-fortran
export HDF5_INC_DIR=$HDF5_INSTALL_ROOT/include
export HDF5_LIB_DIR=$HDF5_INSTALL_ROOT/lib
export NETCDF_INC_DIR=$NETCDF4_INSTALL_ROOT/include
export NETCDF_LIB_DIR=$NETCDF4_INSTALL_ROOT/lib
EOF

cp arch/arch-GCC_LINUX.fcm  arch/arch-OIFS.fcm

cat > arch/arch-OIFS.path <<'EOF'
NETCDF_INCDIR="-I$NETCDF_INC_DIR"
NETCDF_LIBDIR="-L$NETCDF_LIB_DIR"
NETCDF_LIB="-lnetcdff -lnetcdf"
MPI_INCDIR=""
MPI_LIBDIR=""
HDF5_INCDIR="-I$HDF5_INC_DIR"
HDF5_LIBDIR="-L$HDF5_LIB_DIR"
HDF5_LIB="-lhdf5_hl -lhdf5 -lm -ldl -lz"
EOF

./make_xios --prod --job 2 --netcdf_lib netcdf4_seq --arch OIFS

mkdir -p $install_dir
cp -rp bin etc lib $install_dir
cp -rp inc ${install_dir}/include



# OpenIFS

cd $TMPDIR
tar xvf oifs43r3v2.tar.gz
cd oifs43r3v2

zlib=$(h5pfc -show | grep -oe '-L[^ ]*zlib[^ ]*/lib')

# Stripped version of oifs-config.editme.sh

export OIFS_HOME=$PWD
export OIFS_DATA_DIR="<editme>"
export OIFS_INIDATA_DIR="<editme>"
export OIFS_LAPACK_INCLUDE="-I${OPENBLAS_INSTALL_ROOT}/include"
export OIFS_LAPACK_LIB="-lopenblas"
export OIFS_NETCDF_INCLUDE="-I$NETCDF_FORTRAN_INSTALL_ROOT/include -I$NETCDF_C_INSTALL_ROOT/include"
export OIFS_NETCDF_LIB="-lnetcdff -lnetcdf -L$zlib -lz -Wl,-rpath=$zlib"
export OIFS_GRIB_INCLUDE="-I${ECCODES_INSTALL_ROOT}/include"
export OIFS_GRIB_LIB="-L${ECCODES_INSTALL_ROOT}/lib -leccodes_f90 -leccodes"
export OIFS_COMP=gnu
export OIFS_BUILD=opt
export OIFS_RUNCMD='srun'
export OIFS_FC='mpif90 -fallow-argument-mismatch -fallow-invalid-boz'
export OIFS_CC=mpicc
export OIFS_XIOS=enable
export OIFS_XIOS_INCLUDE="-I${install_dir}/include"
export OIFS_XIOS_LIB="-L${install_dir}/lib -lxios -lstdc++"


export PATH=${PATH}:${OIFS_HOME}/fcm/bin:${OIFS_GRIB_DIR}/bin

alias omake="fcm make -v -j16 -f $OIFS_HOME/make/oifs.fcm"
alias omakenew="fcm make --new -v -j16 -f $OIFS_HOME/make/oifs.fcm"
alias oenv='env|grep OIFS_'

# In file src/ifs/setup/sugfl1.F90 move line
#     #include "namchem.nam.h"
# containing a namelist definition down couple of lines so that it is after the declaration of the variables...

omake

mkdir -p ${install_dir}/bin
cp -r bin/* make/gnu-opt/oifs/bin/* ${install_dir}/bin
