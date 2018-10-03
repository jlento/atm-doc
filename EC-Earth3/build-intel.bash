#!/bin/bash

# EC-EARTH3
# =========
#
# Cray XC40, Intel compiler suite, sisu.csc.fi
# jukka-pekka.keskinen@helsinki.fi, juha.lento@csc.fi
# 2017-09-03, 2017-09-21

# Usage
# -----
#
# Build everything automatically (Yeah, you wish):
#     bash install.bash
#
# Set up current environment and define functions for building components, and
# then run the component build functions interactively (Porting/debugging):
#     source install.bash

# Requires
# --------
# File 'config-build-sisu-cray-intel.xml' (with sisu-cray-intel platform)



### Script stuff that needs to be executed first ###

[[ "$0" != "${BASH_SOURCE}" ]] && sourced=true || sourced=false
${sourced} || set -e
thisdir=$(readlink -f $(dirname $BASH_SOURCE))



### Local/user defaults ###

: ${SVNUSER:=}
: ${BRANCH:=tags/3.2.3}
: ${REVNO:=} #leave blank to get the latest
: ${BLDROOT:=$TMPDIR/ece3}
: ${INSTALLROOT:=$USERAPPL/ece3}
: ${RUNROOT:=$WRKDIR}



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
#    local optional_revision="$1"
    optional_revision=$REVNO
    [ "$optional_revision" ] && local revflag="-r $optional_revision"
    mkdir -p $BLDROOT
    cd $BLDROOT
    if [ -d "$BRANCH" ]; then
	cd $BRANCH
	svn revert -R .
	svn status --no-ignore | grep -E '(^\?)|(^\I)' | sed -e 's/^. *//' | sed -e 's/\(.*\)/"\1"/' | xargs rm -rf
	[[ $REVNO -ne `svn info | grep 'Revision' | awk '{print $2}'` ]] && svn update $revflag
    else
	svn --username $SVNUSER checkout $revflag https://svn.ec-earth.org/ecearth3/$BRANCH $BRANCH
    fi
}

ecconfig () {
    cd ${BLDROOT}/${BRANCH}/sources
    expand-variables ${thisdir}/config-build-sisu-cray-intel.xml config-build.xml
    ./util/ec-conf/ec-conf --platform=sisu-cray-intel config-build.xml
}

oasis () {
    module swap craype-haswell craype-sandybridge
    cd ${BLDROOT}/${BRANCH}/sources/oasis3-mct/util/make_dir
    FCLIBS=" " make -f TopMakefileOasis3 BUILD_ARCH=ecconf
    module swap craype-sandybridge craype-haswell
}

lucia() {
    cd ${BLDROOT}/${BRANCH}/sources/oasis3-mct/util/lucia
    bash lucia -c
}

xios () {
    cd ${BLDROOT}/${BRANCH}/sources/xios-2
    ./make_xios --dev --arch ecconf --use_oasis oasis3_mct --netcdf_lib netcdf4_par --job 4
}

nemo () {
    cd ${BLDROOT}/${BRANCH}/sources/nemo-3.6/CONFIG
    ./makenemo -n ORCA1L75_LIM3 -m ecconf -j 4
    cd ${BLDROOT}/${BRANCH}/sources/nemo-3.6/CONFIG/ORCA1L75_LIM3/BLD/obj
    ar curv lib__fcm__nemo.a *.o
    ar d lib__fcm__nemo.a nemo.o
    mv lib__fcm__nemo.a ../lib
    cd ${BLDROOT}/${BRANCH}/sources/nemo-3.6/CONFIG/ORCA1L75_LIM3/BLD/bin
    ftn -o nemo.exe ../obj/nemo.o -L../lib -l__fcm__nemo -O2 -fp-model strict -r8 -L${BLDROOT}/${BRANCH}/sources/xios-2/lib -lxios -lstdc++ -L${BLDROOT}/${BRANCH}/sources/oasis3-mct/ecconf/lib -lpsmile.MPI1 -lmct -lmpeu -lscrip -lnetcdff -lnetcdf

}

oifs () {
    cd ${BLDROOT}/${BRANCH}/sources/ifs-36r4
    make BUILD_ARCH=ecconf -j 8 lib
    make BUILD_ARCH=ecconf master
}


tm5 () {
    cd ${BLDROOT}/${BRANCH}/sources/tm5mp
    # patch -u -p0 < $thisdir/tm5.patch
    export PATH=${BLDROOT}/${BRANCH}/sources/util/makedepf90/bin:$PATH
    ./setup_tm5 -n -j 4 ecconfig-ecearth3.rc
}

runoff-mapper () {
    cd ${BLDROOT}/${BRANCH}/sources/runoff-mapper/src
    make
}

amip-forcing () {
    cd ${BLDROOT}/${BRANCH}/sources/amip-forcing/src
    make
}

# Install
install_all () {
    mkdir -p ${INSTALLROOT}/${BRANCH}/${REVNO}
    cp -f  \
	${BLDROOT}/${BRANCH}/sources/xios-2/bin/xios_server.exe \
	${BLDROOT}/${BRANCH}/sources/nemo-3.6/CONFIG/ORCA1L75_LIM3/BLD/bin/nemo.exe \
	${BLDROOT}/${BRANCH}/sources/ifs-36r4/bin/ifsmaster-ecconf \
	${BLDROOT}/${BRANCH}/sources/runoff-mapper/bin/runoff-mapper.exe \
	${BLDROOT}/${BRANCH}/sources/amip-forcing/bin/amip-forcing.exe \
	${BLDROOT}/${BRANCH}/sources/tm5mp/build/appl-tm5.x \
	/appl/climate/bin/cdo \
	${BLDROOT}/${BRANCH}/sources/oasis3-mct/util/lucia/lucia.exe \
	${BLDROOT}/${BRANCH}/sources/oasis3-mct/util/lucia/lucia \
	${BLDROOT}/${BRANCH}/sources/oasis3-mct/util/lucia/balance.gnu \
	${INSTALLROOT}/${BRANCH}/${REVNO}
}

# Create run directory and fix stuff

create_ece_run () {
    cd $RUNROOT
    mkdir -p ece-${BRANCH}-r${REVNO}
    cp -fr ${BLDROOT}/${BRANCH}/runtime/* ${RUNROOT}/ece-${BRANCH}-r${REVNO}/
    cp -f ${thisdir}/sisu.cfg.tmpl ${RUNROOT}/ece-${BRANCH}-r${REVNO}/classic/platform/
    cd ${RUNROOT}/ece-${BRANCH}-r${REVNO}
    cp classic/ece-esm.sh.tmpl classic/ece-ifs+nemo+tm5.sh.tmpl
    sed "s|THIS_NEEDS_TO_BE_CHANGED|${INSTALLROOT}/${BRANCH}/${REVNO}|" ${thisdir}/rundir.patch | patch -u -p0
    mkdir -p ${RUNROOT}/ece-${BRANCH}-r${REVNO}/tm5mp
    cd ${RUNROOT}/ece-${BRANCH}-r${REVNO}/tm5mp
    cp -rf ${BLDROOT}/${BRANCH}/sources/tm5mp/rc .
    cp -fr ${BLDROOT}/${BRANCH}/sources/tm5mp/bin .
    cp -fr ${BLDROOT}/${BRANCH}/sources/tm5mp/build .
    ln -s bin/pycasso_setup_tm5 setup_tm5
}


### Execute the functions if this script is not sourced ###



if ! $sourced; then
    updatesources
    ( module list -t 2>&1 ) > ${BLDROOT}/${BRANCH}/modules.log
    ( ecconfig       2>&1 ) > ${BLDROOT}/${BRANCH}/ecconf.log
    ( oasis          2>&1 ) > ${BLDROOT}/${BRANCH}/oasis.log    &
    wait
    ( lucia          2>&1 ) > ${BLDROOT}/${BRANCH}/lucia.log    &
    ( xios           2>&1 ) > ${BLDROOT}/${BRANCH}/xios.log &
    ( tm5            2>&1 ) > ${BLDROOT}/${BRANCH}/tm5.log  &
    wait
    ( oifs           2>&1 ) > ${BLDROOT}/${BRANCH}/ifs.log &
    ( nemo           2>&1 ) > ${BLDROOT}/${BRANCH}/nemo.log &
    ( runoff-mapper  2>&1 ) > ${BLDROOT}/${BRANCH}/runoff.log &
    wait
    ( amip-forcing   2>&1 ) > ${BLDROOT}/${BRANCH}/amipf.log &
    wait
    install_all
    create_ece_run
fi
