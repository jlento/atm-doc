# Build in tmp dir, unzip sources

cd $TMPDIR
#wget -O flexpart_v10.4.tar https://www.flexpart.eu/downloads/66
#tar xvf flexpart_v10.4.tar
#cd cd flexpart_v10.4_3d7eebf/
git clone https://www.flexpart.eu/gitmob/flexpart
cd flexpart/src

# Build environment

module purge
module load gcc hpcx-mpi intel-mkl hdf5 netcdf netcdf-fortran eccodes

# Currently Loaded Modules:
# 1) StdEnv      3) hpcx-mpi/2.4.0   5) intel-mkl/2019.0.4   7) netcdf/4.7.0
# 2) gcc/9.1.0   4) eccodes/2.5.0    6) hdf5/1.10.4          8) netcdf-fortran/4.4.4


# Build MPI parallel version

make clean
make -j 8 mpi F90=gfortran MPIF90=mpif90 FFLAGS="-O2 -cpp -m64 -mcmodel=medium -fconvert=little-endian -frecord-marker=4 -fmessage-length=0 -flto=jobserver -I$ECCODES_INSTALL_ROOT/include -I$NETCDF_FORTRAN_INSTALL_ROOT/include" LIBS="-leccodes_f90"

# Sequential (non-parallel) version build is the same, just leave out the "mpi" from the previous make command

# At runtime, have the same modules loaded as at build time
