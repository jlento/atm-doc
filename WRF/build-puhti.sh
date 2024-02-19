#!/bin/bash

# Build WRF and WPS puhti.csc.fi
# 2020-09-29, Updated for Puhti RHEL8, Intel -> GNU compilers, juha.lento@csc.fi
# 2020-04-02, Added WPS instructions, juha.lento@csc.fi
# 2019-11-25, juha.lento@csc.fi


# Environment

modules="gcc/11.3.0 openmpi/4.1.4 intel-oneapi-mkl/2022.1.0 hdf5/1.12.2-mpi netcdf-c/4.8.1 netcdf-fortran/4.5.4"

module purge
module load $modules


# Create netcdf + netcdf-fortran Spack view (in your project directory)
#   - no need to redo this if it already exist

export NETCDF=$PWD/netcdf
mkdir -p $NETCDF
source /appl/spack/v018/spack/share/spack/setup-env.sh
spack view -d no add $NETCDF /${NETCDF_C_INSTALL_ROOT##*-} /${NETCDF_FORTRAN_INSTALL_ROOT##*-}


# Set WRF build directory
#   - here a temporary one, since I do not intend to keep it

WRF_INSTALL_ROOT=${LOCAL_SCRATCH:-$TMPDIR}
cd $WRF_INSTALL_ROOT


# Download source from github

git clone --recurse-submodules https://github.com/wrf-model/WRF
cd WRF


# Configure

./configure <<<"34

"

# For 2009 WRF version 3.1.1 needed for PlanetWRF, configure with "13"
# instead of "34", and after ./configure, edit 'configure.wrf' lines 92-95:
#    92 SFC             =       gfortran -cpp -fallow-argument-mismatch -fallow-invalid-boz
#    93 SCC             =       gcc -std=gnu89 -DMPI2_SUPPORT
#    94 DM_FC           =       mpif90 -cpp -fallow-argument-mismatch -fallow-invalid-boz
#    95 DM_CC           =       mpicc -std=gnu89 -DMPI2_SUPPORT
# to make the new compilers play with the old source.

# Build WRF em_b_wave test

./compile -j 8 em_b_wave


# Test em_b_wave

RUNDIR=/scratch/${DEFAULT_PROJECT}/$USER/wrf
mkdir -p $RUNDIR

cp -r main run test $RUNDIR
cd ${RUNDIR}/test/em_b_wave
./run_me_first.csh
./ideal.exe
sbatch -p rhel8-cpu -A $DEFAULT_PROJECT -n 2 -t 5 <<EOF
#!/bin/bash
module purge
module load $modules
srun wrf.exe
EOF


# Download WPS

cd $WRF_INSTALL_ROOT
git clone https://github.com/wrf-model/WPS
cd WPS


# Configure (using the same modules and NETCDF as above)

./configure <<<3


# Edit configure.wps (overwritten everytime ./configure is run)
# - give the locations of jasper, png and zlib (using gcc/9.1.0, hoping it's C only and
#   actually works...)
# - add option -mkl to all FLAGS

sed -i '62,63d' configure.wps


# Compile and link...

./compile
