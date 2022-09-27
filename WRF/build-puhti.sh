#!/bin/bash

# Build WRF and WPS puhti.csc.fi
# 2020-09-27, Updated for Puhti RHEL8, Intel -> GNU compilers, juha.lento@csc.fi
# 2020-04-02, Added WPS instructions, juha.lento@csc.fi
# 2019-11-25, juha.lento@csc.fi


# Environment

modules="gcc/11.3.0 openmpi/4.1.4 intel-oneapi-mkl/2022.1.0 hdf5/1.12.2-mpi netcdf-c/4.8.1 netcdf-fortran/4.5.4"

module purge
module load $modules
export NETCDF=$PWD/netcdf


# Create netcdf + netcdf-fortran Spack view
#   - no need to redo this if it already exist

mkdir -p $NETCDF
source /appl/spack/v018/spack/share/spack/setup-env.sh
spack view -d no add $NETCDF /${NETCDF_C_INSTALL_ROOT##*-} /${NETCDF_FORTRAN_INSTALL_ROOT##*-}


# Set WRF build directory
#   - here a temporary one, since I do not intend to keep it
#   - compilation of the 'module_sf_clm.f90' seems to take 20 minutes...

WRF_INSTALL_ROOT=${LOCAL_SCRATCH:-$TMPDIR}
cd $WRF_INSTALL_ROOT


# Download source from github

git clone --recurse-submodules https://github.com/wrf-model/WRF
cd WRF


# Configure

./configure <<<"35

"


# Build WRF em_b_wave test

./compile -j 8 em_b_wave


# Test em_b_wave

RUNDIR=/scratch/${DEFAULT_PROJECT}/$USER/wrf
mkdir -p $RUNDIR

cp -r main run test $RUNDIR
cd ${RUNDIR}/test/em_b_wave
./run_me_first.csh
./ideal.exe
sbatch -A $DEFAULT_PROJECT -n 2 -t 5 <<EOF
#!/bin/bash
module purge
module load $modules
srun wrf.exe
EOF


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
