#/bin/bash

# 2024-10-02

export PROJAPPL=/scratch/project_2010980

export NETCDF=$PROJAPPL/netcdf
export PATH=$PATH:${NETCDF}/bin
mkdir -p $NETCDF
source /appl/spack/v017/spack/share/spack/setup-env.sh
spack view -d yes add -i $NETCDF /y5m33p3

cd $TMPDIR
wget https://github.com/wrf-model/WRF/archive/refs/tags/V3.9.tar.gz
tar xf V3.9.tar.gz
cd WRF-3.9
cp -b share/landread.c.dist share/landread.c

export WRF_CHEM=1
export WRF_KPP=1
export FLEX_LIB_DIR=/appl/spack/v017/install-tree/gcc-11.2.0/flex-2.6.4-xsigvf/lib
export LD_LIBRARY_PATH=$LD_LIBRARY_PATH:/appl/spack/v017/install-tree/gcc-11.2.0/flex-2.6.4-xsigvf/lib
export YACC='/usr/bin/yacc -d'

./configure  # Select "35"

cp configure.wrf configure.wrf.orig
sed -i '/^DM_CC/s/$/ -DMPI2_SUPPORT/;/^FCBASEOPTS /s/$/ -fallow-argument-mismatch -fallow-invalid-boz/' configure.wrf

# [jlento@mahti-login14 WRF-3.9]$ diff configure.wrf.orig configure.wrf
# 123c123
# < DM_CC           =       mpicc
# ---
# > DM_CC           =       mpicc -DMPI2_SUPPORT
# 143c143
# < FCBASEOPTS      =       $(FCBASEOPTS_NO_G) $(FCDEBUG)
# ---
# > FCBASEOPTS      =       $(FCBASEOPTS_NO_G) $(FCDEBUG) -fallow-argument-mismatch -fallow-invalid-boz

./compile em_real 2>&1 | tee compile.log
