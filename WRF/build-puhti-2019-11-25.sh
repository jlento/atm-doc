#!/bin/bash

# Build WRF puhti.csc.fi
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


# Build WRF em_b_wave test

cd $WRF_INSTALL_ROOT
wget https://github.com/wrf-model/WRF/archive/v4.1.2.tar.gz
tar xvf v4.1.2.tar.gz
cd WRF-4.1.2

./configure <<<"67

"

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



