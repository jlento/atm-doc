module purge
module load intel-oneapi-compilers-classic intel-oneapi-mpi intel-oneapi-mkl netcdf-c netcdf-fortran

# These two you need to edit
export SBATCH_ACCOUNT=$PROJECT
export SBATCH_PARTITION=rhel8-cpu

# The rest hopefully not
export FC=mpif90
export CC=mpicc
export MPIFC=mpif90
export MPI_LAUNCH=srun
#export MPI_FC_LIB="$(read compiler options < <(mpif90 -show) ; echo $options)"
#export MPI_C_LIB="$(read compiler options < <(mpicc -show) ; echo $options)"
export MPI_C_LIB=
export MPI_FC_LIB=

export FCFLAGS="-I${I_MPI_ROOT}/intel64/include"
export MPI_C_INCLUDE="-I${I_MPI_ROOT}/intel64/include"
export MPI_FC_INCLUDE="-I${I_MPI_ROOT}/intel64/include"
export LDFLAGS="-L${HDF5_INSTALL_ROOT}/lib -L${I_MPI_ROOT}/intel64/lib"
export CPPFLAGS="-I${HDF5_INSTALL_ROOT}/include"
export LIBS="-lnetcdf"
