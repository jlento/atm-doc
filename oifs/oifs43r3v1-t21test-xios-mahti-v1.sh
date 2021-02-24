# Testing

module load eccodes/2.13.0 netcdf-fortran/4.5.2 netcdf-c/4.7.3-mpi

export OIFS_HOME=/projappl/project_2003423/$USER
export ECCODES_SAMPLES_PATH=/MEMFS/ifs_samples/grib1_mlgrib2:/MEMFS/samples

cd /scratch/project_2003423/$USER
tar xvf $OIFS_HOME/oifs43r3v1.tar.gz --wildcards --no-anchored '*t21test*' --strip-components=1

cd t21test_xios
srun -A project_2003423 -n 2 -p test -t 5 $OIFS_HOME/bin/master.exe -e epc8
