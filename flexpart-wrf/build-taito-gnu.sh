#!/bin/bash

module purge
module load gcc/7.3.0 intelmpi/18.0.2 mkl/18.0.2 hdf5-par/1.8.20 netcdf4/4.6.1

version=3.3.2

wget https://www.flexpart.eu/downloads/58 -O flexpart-wrf-${version}.tar.gz
tar xvf flexpart-wrf-${version}.tar.gz
cd Src_flexwrf_v${version}

make -f makefile.mom omp NETCDF=$(nc-config --prefix)
