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

# If you want WRF to output grib2

module load jasper
export JASPERINC=$JASPER_INSTALL_ROOT/include
export JASPERLIB=$JASPER_INSTALL_ROOT/lib
sed -ir 's/(I_really_want_to_output_grib2_from_WRF = )(.*)/\1"TRUE" ;/p' arch/Config.pl

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


# Download WPS

git clone https://github.com/wrf-model/WPS
cd WPS


# Configure (using the same modules and NETCDF as above)

./configure <<<3

# Compile and link...

./compile
