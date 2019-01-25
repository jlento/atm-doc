#!/bin/bash

# Build WRF taito.csc.fi
# 2018-08-23, juha.lento@csc.fi

wget http://www2.mmm.ucar.edu/wrf/src/WRFV4.0.TAR.gz
tar xvf WRFV4.0.TAR.gz

module purge
module load gcc/7.3.0 intelmpi/18.0.2 hdf5-par/1.8.20 netcdf4/4.6.1 mkl/18.0.2

export NETCDF=$(nc-config --prefix)

./configure <<<"35

"

./compile -j 8 em_b_wave

# Test

mkdir $WRKDIR/wrf
cp -r main run test $WRKDIR/wrf
cd $WRKDIR/wrf/test/em_b_wave
./run_me_first.csh
./ideal.exe
sbatch -n 2 -p test <<EOF
#!/bin/bash
module purge
module load gcc/7.3.0 intelmpi/18.0.2 hdf5-par/1.8.20 netcdf4/4.6.1 mkl/18.0.2
srun wrf.exe
EOF


