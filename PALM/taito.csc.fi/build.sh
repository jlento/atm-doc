cd $TMPDIR
svn checkout --username NNN --password NNN https://palm.muk.uni-hannover.de/svn/palm/tags/release-6.0 release-6.0 
cd release-6.0/
module purge
module load intel/18.0.1 intelmpi/18.0.1
module load fftw/3.3.7 hdf5-par/1.10.2 netcdf4/4.6.1 
PATH=$PWD/SCRIPTS:$PATH
palm_simple_build -b ifort.taito
