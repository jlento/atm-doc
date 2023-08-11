# 2023-08-11, juha.lento@csc.fi

# https://github.com/ESCOMP/CESM
# http://esmci.github.io/cime/versions/master/html/users_guide

export PROJECT=project_465000454
export PROJECTROOT=/scratch/$PROJECT
export CESMROOT=$PROJECTROOT/jlento/my_cesm_sandbox
export CIMEROOT=$CESMROOT/cime

# These are used in ~/.cime/machine_config.xml (which is close to similar machine "archer2" in
#   $CIMEROOT/config/cesm/machines/config_machines.xml
export CASE=
export CESMDATAROOT=
export CIMEOUTPUTROOT=

module load LUMI/23.03 partition/C Subversion cray-python cray-hdf5 cray-netcdf cray-parallel-netcdf

mkdir -p ${CESMROOT%/*}
cd ${CESMROOT%/*}
git clone https://github.com/escomp/cesm.git ${CESMROOT##*/}
cd ${CESMROOT##*/}

git checkout release-cesm2.1.4

./manage_externals/checkout_externals

mkdir -p ~/.cime
wget -O ~/.cime/config_machines.xml https://raw.githubusercontent.com/jlento/atm-doc/master/CESM/LUMI/config_machines.xml
