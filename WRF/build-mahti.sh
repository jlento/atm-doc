#!/bin/bash

# Build WRF and WPS mahti.csc.fi
# 2022-06-21, juha.lento@csc.fi


# Mahti default environment
#
# Currently Loaded Modules:
#   1) gcc/11.2.0   2) openmpi/4.1.2   3) openblas/0.3.18-omp   4) csc-tools (S)   5) StdEnv

export NETCDF=$PROJAPPL/netcdf-wrf
export PATH=$PATH:${NETCDF}/bin

# Create netcdf + netcdf-fortran Spack view
#   - no need to redo this if it already exist

mkdir -p $NETCDF
source /appl/spack/v017/spack/share/spack/setup-env.sh
spack view -d yes add -i $NETCDF /y5m33p3


# Set WRF build directory
#   - here a temporary one, since I do not intend to keep it
#   - compilation of the 'module_sf_clm.f90' seems to take 20 minutes...

WRF_INSTALL_ROOT=${LOCAL_SCRATCH:-$TMPDIR}
cd $WRF_INSTALL_ROOT


# Download source from tar ball, or...

# wget https://github.com/wrf-model/WRF/archive/v4.1.2.tar.gz
# tar xvf v4.1.2.tar.gz
# cd WRF-4.1.2

# ...or download the latest from github

git clone https://github.com/wrf-model/WRF
cd WRF


# Configure

./configure <<<"35

"


# Build WRF em_b_wave test

./compile -j 8 em_b_wave


# Test em_b_wave

export LD_LIBRARY_PATH=$LD_LIBRARY_PATH:$NETCDF/lib

RUNDIR=$SCRATCH/wrf
mkdir -p $RUNDIR

cp -r main run test $RUNDIR
cd ${RUNDIR}/test/em_b_wave
./run_me_first.csh
./ideal.exe
sbatch -A $DEFAULT_PROJECT -n 2 -t 5 <<EOF
#!/bin/bash
srun wrf.exe
EOF


##############################################
# NOTE: The instructions below for WPS build #
# are not updated from puhti -> mahti        #
##############################################

# Download WPS

git clone https://github.com/wrf-model/WPS
cd WPS


# Configure (using the same modules and NETCDF as above)

./configure <<<19


# Edit configure.wps (overwritten everytime ./configure is run)
# - give the locations of jasper, png and zlib (using gcc/9.1.0, hoping it's C only and
#   actually works...)
# - add option -mkl to all FLAGS

sed -i '60,79c\
COMPRESSION_LIBS    = -L/appl/spack/install-tree/gcc-9.1.0/jasper-2.0.14-cbgw7w/lib64 -ljasper -L/appl/spack/install-tree/gcc-9.1.0/libpng-1.6.34-lneo6q/lib -lpng -L/appl/spack/install-tree/gcc-9.1.0/zlib-1.2.11-nq5wt2/lib -lz\
COMPRESSION_INC     = -I/appl/spack/install-tree/gcc-9.1.0/jasper-2.0.14-cbgw7w/include -I/appl/spack/install-tree/gcc-9.1.0/jasper-2.0.14-cbgw7w/include -I/appl/spack/install-tree/gcc-9.1.0/zlib-1.2.11-nq5wt2/include\
FDEFS               = -DUSE_JPEG2000 -DUSE_PNG\
SFC                 = ifort\
SCC                 = icc\
DM_FC               = mpif90\
DM_CC               = mpicc\
FC                  = $(DM_FC)\
CC                  = $(DM_CC)\
LD                  = $(FC)\
FFLAGS              = -FR -convert big_endian -mkl\
F77FLAGS            = -FI -convert big_endian -mkl\
FCSUFFIX            = \
FNGFLAGS            = $(FFLAGS)\
LDFLAGS             = -mkl\
CFLAGS              = -w -mkl\
CPP                 = /lib/cpp -P -traditional\
CPPFLAGS            = -D_UNDERSCORE -DBYTESWAP -DLINUX -DIO_NETCDF -DIO_BINARY -DIO_GRIB1 -DBIT32 -D_MPI\
ARFLAGS             = \
CC_TOOLS            = ' configure.wps


# Compile and link...

./compile
