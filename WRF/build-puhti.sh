#!/bin/bash

# Build WRF and WPS puhti.csc.fi
# 2020-04-02, Added WPS instructions, juha.lento@csc.fi 
# 2019-11-25, juha.lento@csc.fi


# Environment

modules="intel/19.0.4 hpcx-mpi/2.4.0 intel-mkl/2019.0.4 hdf5/1.10.4-mpi\
 netcdf/4.7.0 netcdf-fortran/4.4.4"

module purge
module load $modules
export NETCDF=/appl/soft/phys/WRF/4.1.2


# Create netcdf + netcdf-fortran Spack view
#   - no need to redo this if it already exist

mkdir -p $NETCDF
cd $NETCDF
source /appl/spack/spack/share/spack/setup-env.sh
spack view -d no add . /5xwiij /tmvulh


# Set WRF build directory
#   - here a temporary one, since I do not intend to keep it
#   - compilation of the 'module_sf_clm.f90' seems to take 20 minutes...

WRF_INSTALL_ROOT=${LOCAL_SCRATCH:-$TMPDIR}
cd $WRF_INSTALL_ROOT


# Download source from tar ball, or...

wget https://github.com/wrf-model/WRF/archive/v4.1.2.tar.gz
tar xvf v4.1.2.tar.gz
cd WRF-4.1.2

# ...or download the latest from github

git clone https://github.com/wrf-model/WRF
cd WRF


# Configure

./configure <<<"67

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
