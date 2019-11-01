#!/bin/bash

# EC-EARTH3
# =========
#
# puhti.csc.fi, Intel compiler suite
# jukka-pekka.keskinen@helsinki.fi, juha.lento@csc.fi
# 2017-09-03, 2017-09-21, 2019-02-27, 2019-08-30

usage="
Usage: bash $0

         or

       source $0

The first invocation tries to build everything with one go, the second
one just loads variables and functions to the current shell, and one
can run the functions one by one (debug).

Requires that the following files are in the same directory with this
script

    config-build.xml
    csc-puhti-intel.xml
    puhti.cfg.tmpl
    puhti.xml

It may look like the script is doing nothing, if it works :) That's
because the output of the build functions is redirected to files
in ${BLDROOT}/${TAG}/*.log. Just open another terminal and monitor the
log files. Something like

    ls -ltr ${BLDROOT}/${TAG}/*.log

"


### Local/user defaults ###

: ${TAG:=3.3.1.1}
: ${BLDROOT:=$TMPDIR/ece3}
: ${INSTALLROOT:=/projappl/project_$(id -g)/$USER/ece3}
: ${RUNROOT:=/scratch/project_$(id -g)/$USER/ece3}
: ${PLATFORM:=csc-puhti-intel}
: ${GRIBEX_TAR_GZ:=${HOME}/gribex_000370.tar.gz}
# : ${REVNO:=6611}


### Some general bash scripting stuff ###

# Check if this script is sourced or run interactively

[[ "$0" != "${BASH_SOURCE}" ]] && sourced=true || sourced=false
${sourced} || set -e

# The directory of this script and auxiliary files

thisdir=$(readlink -f $(dirname $BASH_SOURCE))


### Environment setup ###

module purge
module load intel/19.0.4
module load hpcx-mpi/2.4.0
module load intel-mkl/2019.0.4
module load hdf/4.2.13
module load hdf5/1.10.4-mpi
module load netcdf/4.7.0
module load netcdf-fortran/4.4.4
module load grib-api/1.24.0
module load cmake/3.12.3

### Helper functions ###

expand-variables () {
    local infile="$1"
    local outfile="$2"
    local tmpfile="$(mktemp)"
    eval 'echo "'"$(sed 's/\\/\\\\/g;s/\"/\\\"/g' $infile)"'"' > "$tmpfile"
    if ! diff -s "$outfile" "$tmpfile" &> /dev/null; then
	VERSION_CONTROL=t \cp -f --backup "$tmpfile" "$outfile"
    fi
}


### EC-EARTH3 related functions ###


updatesources () {
    [ "$REVNO" ] && local revflag="-r $REVNO"
    mkdir -p $BLDROOT
    cd $BLDROOT
    svn checkout https://svn.ec-earth.org/ecearth3/tags/$TAG $TAG
    svn checkout https://svn.ec-earth.org/vendor/gribex/gribex_000370 gribex_000370
}

ecconfig () {
    cd ${BLDROOT}/${TAG}/sources
    ./util/ec-conf/ec-conf --platform=${PLATFORM} ${thisdir}/config-build.xml
}

oasis () {
    cd ${BLDROOT}/${TAG}/sources/oasis3-mct/util/make_dir
    FCLIBS=" " make -f TopMakefileOasis3 BUILD_ARCH=ecconf
}

lucia() {
    cd ${BLDROOT}/${TAG}/sources/oasis3-mct/util/lucia
    bash lucia -c
}

xios () {
    cd ${BLDROOT}/${TAG}/sources/xios-2.5
    ./make_xios --dev --arch ecconf --use_oasis oasis3_mct --netcdf_lib netcdf4_par --job 4
}

nemo () {
    cd ${BLDROOT}/${TAG}/sources/nemo-3.6/CONFIG
    ./makenemo -n ORCA1L75_LIM3 -m ecconf -j 4
}

oifs () {
    # gribex first
    cd ${BLDROOT}/gribex_000370
    ./build_library <<EOF
i
y
${BLDROOT}/${TAG}/sources/ifs-36r4/lib
n
EOF
    mv libgribexR64.a ${BLDROOT}/${TAG}/sources/ifs-36r4/lib

    # ifs
    cd ${BLDROOT}/${TAG}/sources/ifs-36r4
    #sed -i '666s/STATUS=IRET/IRET/' src/ifsaux/module/grib_api_interface.F90
    make BUILD_ARCH=ecconf -j 8 lib
    make BUILD_ARCH=ecconf master
}


tm5 () {
    cd ${BLDROOT}/${TAG}/sources/tm5mp
    # patch -u -p0 < $thisdir/tm5.patch
    sed -i 's/\?//g' base/convection.F90
    PATH=${BLDROOT}/${TAG}/sources/util/makedepf90/bin:$PATH ./setup_tm5 -n -j 4 ecconfig-ecearth3.rc
}

runoff-mapper () {
    cd ${BLDROOT}/${TAG}/sources/runoff-mapper/src
    make
}

amip-forcing () {
    cd ${BLDROOT}/${TAG}/sources/amip-forcing/src
    make
}

lpj-guess () {
    cd ${BLDROOT}/${TAG}/sources/lpjg/build
    cmake .. -DCMAKE_Fortran_FLAGS="-I${HPCX_MPI_INSTALL_ROOT}/lib"
    make # Fails with int <---> MPI_Comm type errors...
}

# Install
install_all () {
    mkdir -p ${INSTALLROOT}/${TAG}/${REVNO}
    local exes=(
	      xios-2.5/bin/xios_server.exe
	      nemo-3.6/CONFIG/ORCA1L75_LIM3/BLD/bin/nemo.exe
	      ifs-36r4/bin/ifsmaster-ecconf
	      runoff-mapper/bin/runoff-mapper.exe
	      amip-forcing/bin/amip-forcing.exe
	      tm5mp/build/appl-tm5.x
	      oasis3-mct/util/lucia/lucia.exe
	      oasis3-mct/util/lucia/lucia
	      oasis3-mct/util/lucia/balance.gnu)
	  for exe in "${exes[@]}"; do
        cp -f ${BLDROOT}/${TAG}/sources/${exe} ${INSTALLROOT}/${TAG}/${REVNO}/
    done
    cp -f /appl/climate/bin/cdo ${INSTALLROOT}/${TAG}/${REVNO}/
}

# Create run directory and fix stuff

create_ece_run () {
    cd $RUNROOT
    mkdir -p ece-${TAG}-r${REVNO}
    \cp -r ${BLDROOT}/${TAG}/runtime/* ${RUNROOT}/ece-${TAG}-r${REVNO}/
    \cp ${thisdir}/${PLATFORM}.cfg.tmpl ${RUNROOT}/ece-${TAG}-r${REVNO}/classic/platform/
    \cp ${thisdir}/${PLATFORM}.xml ${RUNROOT}/ece-${TAG}-r${REVNO}/classic/platform/
    cd ${RUNROOT}/ece-${TAG}-r${REVNO}
    \cp classic/ece-esm.sh.tmpl classic/ece-ifs+nemo+tm5.sh.tmpl
    sed "s|THIS_NEEDS_TO_BE_CHANGED|${INSTALLROOT}/${TAG}/${REVNO}|" ${thisdir}/rundir.patch | patch -u -p0
    mkdir -p ${RUNROOT}/ece-${TAG}-r${REVNO}/tm5mp
    cd ${RUNROOT}/ece-${TAG}-r${REVNO}/tm5mp
    \cp -r ${BLDROOT}/${TAG}/sources/tm5mp/rc .
    \cp -r ${BLDROOT}/${TAG}/sources/tm5mp/bin .
    \cp -r ${BLDROOT}/${TAG}/sources/tm5mp/build .
    ln -s bin/pycasso_setup_tm5 setup_tm5
}


### Execute all functions if this script is not sourced ###

if ! ${sourced}; then
    updatesources
    ( module -t list 2>&1 ) > ${BLDROOT}/${TAG}/modules.log
    ( ecconfig       2>&1 ) > ${BLDROOT}/${TAG}/ecconf.log
    ( oasis          2>&1 ) > ${BLDROOT}/${TAG}/oasis.log    &
    wait
    ( lucia          2>&1 ) > ${BLDROOT}/${TAG}/lucia.log    &
    ( xios           2>&1 ) > ${BLDROOT}/${TAG}/xios.log &
    ( tm5            2>&1 ) > ${BLDROOT}/${TAG}/tm5.log  &
    wait
    ( oifs           2>&1 ) > ${BLDROOT}/${TAG}/ifs.log &
    ( nemo           2>&1 ) > ${BLDROOT}/${TAG}/nemo.log &
    ( runoff-mapper  2>&1 ) > ${BLDROOT}/${TAG}/runoff.log &
    wait
    ( amip-forcing   2>&1 ) > ${BLDROOT}/${TAG}/amipf.log &
    wait
    install_all
    create_ece_run
fi
