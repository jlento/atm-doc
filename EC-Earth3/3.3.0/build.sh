#!/bin/bash

# EC-EARTH3
# =========
#
# Cray XC40, Intel compiler suite, sisu.csc.fi
# jukka-pekka.keskinen@helsinki.fi, juha.lento@csc.fi
# 2017-09-03, 2017-09-21, 2019-02-27

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
    csc-sisu-cray-intel.xml
    sisu.cfg.tmpl
    sisu.xml

It may look like the script is doing nothing, if it works :) That's
because the output of the build functions is redirected to files
in ${BLDROOT}/${TAG}/*.log. Just open another terminal and monitor the
log files. Something like

    ls -ltr ${BLDROOT}/${TAG}/*.log

"


### Local/user defaults ###

: ${TAG:=3.3.0}
: ${BLDROOT:=$TMPDIR/ece3}
: ${INSTALLROOT:=$USERAPPL/ece3}
: ${RUNROOT:=$WRKDIR}
# : ${REVNO:=6611}


### Some general bash scripting stuff ###

# Check if this script is sourced or run interactively

[[ "$0" != "${BASH_SOURCE}" ]] && sourced=true || sourced=false
${sourced} || set -e

# The directory of this script and auxiliary files

thisdir=$(readlink -f $(dirname $BASH_SOURCE))


### Environment setup ###

module use --append /appl/climate/modulefiles
module swap PrgEnv-cray PrgEnv-intel
module load cray-netcdf-hdf5parallel udunits hdf grib_api/1.17.0 gribex svn


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
}

ecconfig () {
    cd ${BLDROOT}/${TAG}/sources
    expand-variables \
        ${thisdir}/csc-sisu-cray-intel.xml \
        platform/csc-sisu-cray-intel.xml
    expand-variables \
        ${thisdir}/config-build.xml \
        config-build.xml
    ./util/ec-conf/ec-conf --platform=csc-sisu-cray-intel config-build.xml
}

oasis () {
    module swap craype-haswell craype-sandybridge
    cd ${BLDROOT}/${TAG}/sources/oasis3-mct/util/make_dir
    FCLIBS=" " make -f TopMakefileOasis3 BUILD_ARCH=ecconf
    module swap craype-sandybridge craype-haswell
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
    cd ${BLDROOT}/${TAG}/sources/nemo-3.6/CONFIG/ORCA1L75_LIM3/BLD/obj
    ar curv lib__fcm__nemo.a *.o
    ar d lib__fcm__nemo.a nemo.o
    mv lib__fcm__nemo.a ../lib
    cd ${BLDROOT}/${TAG}/sources/nemo-3.6/CONFIG/ORCA1L75_LIM3/BLD/bin
    ftn -o nemo.exe ../obj/nemo.o -L../lib -l__fcm__nemo -O2 -fp-model strict -r8 -L${BLDROOT}/${TAG}/sources/xios-2.5/lib -lxios -lstdc++ -L${BLDROOT}/${TAG}/sources/oasis3-mct/ecconf/lib -lpsmile.MPI1 -lmct -lmpeu -lscrip -lnetcdff -lnetcdf

}

oifs () {
    cd ${BLDROOT}/${TAG}/sources/ifs-36r4
    make BUILD_ARCH=ecconf -j 8 lib
    make BUILD_ARCH=ecconf master
}


tm5 () {
    cd ${BLDROOT}/${TAG}/sources/tm5mp
    # patch -u -p0 < $thisdir/tm5.patch
    export PATH=${BLDROOT}/${TAG}/sources/util/makedepf90/bin:$PATH
    ./setup_tm5 -n -j 4 ecconfig-ecearth3.rc
}

runoff-mapper () {
    cd ${BLDROOT}/${TAG}/sources/runoff-mapper/src
    make
}

amip-forcing () {
    cd ${BLDROOT}/${TAG}/sources/amip-forcing/src
    make
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
    \cp ${thisdir}/sisu.cfg.tmpl ${RUNROOT}/ece-${TAG}-r${REVNO}/classic/platform/
    \cp ${thisdir}/sisu.xml ${RUNROOT}/ece-${TAG}-r${REVNO}/classic/platform/
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


### Execute the functions if this script is not sourced ###



if ! ${sourced}; then
    updatesources
    ( module list -t 2>&1 ) > ${BLDROOT}/${TAG}/modules.log
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
