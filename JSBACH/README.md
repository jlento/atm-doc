# How to build JSBACH

juha.lento@csc.fi, 2019-01-15

## In taito.csc.fi...

### Download source and modified build script

If you build under `$TMPDIR` instead of under `$WRKDIR`, build is faster, but
you need to remember to copy the results somewhere under `$HOME`, `$USERAPPL`,
or `$WRKDIR`.

```
cd $WRKDIR/DONOTREMOVE
svn checkout --username NNN https://svn.zmaw.de/svn/cosmos/branches/mpiesm-landveg mpiesm-landveg
cd mpiesm-landveg
wget https://raw.githubusercontent.com/jlento/atm-doc/master/JSBACH/landveg-compile-taito.ksh
```


### Load environment

The same modules need to be loaded at both build and run time.

```
module purge
module load intel/18.0.1 intelmpi/18.0.1 hdf5-par/1.10.2 netcdf4/4.6.1
```


### Build

Some of the environment variables *may* be redundant redundant, clean up later
:)

```
export FC=ifort
export MPIFC=mpif90
export MPI_LAUNCH=$(which srun)
export FCFLAGS="-I${I_MPI_ROOT}/intel64/include"
export MPI_C_INCLUDE="-I${I_MPI_ROOT}/intel64/include"
export MPI_FC_INCLUDE="-I${I_MPI_ROOT}/intel64/include"
export LIBS="-lnetcdf"
export MPI_FC_LIB="$(read compiler options < <(mpif90 -show) ; echo $options)"
export MPI_C_LIB="$(read compiler options < <(mpicc -show) ; echo $options)"

chmod u+x landveg-compile-taito.ksh
./landveg-compile-taito.ksh
```

Good luck!


## In Ubuntu

This is just a note...

```
LIBS="-lnetcdf" \
  FCFLAGS="-I/usr/lib/x86_64-linux-gnu/openmpi/lib" \
  MPI_C_INCLUDE="-I/usr/lib/x86_64-linux-gnu/openmpi/include -I/usr/include" \
  MPI_FC_LIB="-L/usr/lib/x86_64-linux-gnu/openmpi/lib -lmpi_usempif08 -lmpi_usempi_ignore_tkr -lmpi_mpifh -lmpi" \
  MPI_C_LIB="-L/usr/lib/x86_64-linux-gnu/openmpi/lib -lmpi_usempi_ignore_tkr -lmpi_mpifh -lmpi" \
  MPI_FC_INCLUDE=-I/usr/lib/x86_64-linux-gnu/openmpi/include \
  FCLIBS="" \
  ./landveg-compile_LB.ksh
```
