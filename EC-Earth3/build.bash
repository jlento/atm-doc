#!/bin/bash

# EC-EARTH3
# =========
#
# Cray XC40, Cray compiler suite, sisu.csc.fi
# jukka-pekka.keskinen@helsinki.fi, juha.lento@csc.fi
# 2017-09-03

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
# File 'config-build-sisu-cray-craympi.xml' (with sisu-cray-craympi platform)



### Script stuff that needs to be executed first ###

[ "$0" != "$BASH_SOURCE" ] && sourced=true || sourced=false
${sourced} || set -e
thisdir=$(readlink -f $(dirname $BASH_SOURCE))



### Local/user defaults ###

: ${SVNUSER:=jukka-pekka.keskinen}
: ${BRANCH:=branches/development/2014/r1902-merge-new-components}
: ${REVNO:=4608} #leave blank to get the latest
: ${BLDROOT:=$TMPDIR/ece3}
: ${INSTALLROOT:=$USERAPPL/ece3}
: ${RUNROOT:=$WRKDIR}



### Environment setup ###

module use --append /appl/climate/modulefiles
module load cray-hdf5-parallel cray-netcdf-hdf5parallel grib_api/1.23.1 hdf/4.2.12 libemos/4.0.7



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
    local optional_revision="$1"
    [ "$optional_revision" ] && local revflag="-r $optional_revision"
    mkdir -p $BLDROOT
    cd $BLDROOT
    if [ -d "$BRANCH" ]; then
	cd $BRANCH
	svn update $revflag
    else
	svn --username $SVNUSER checkout $revflag https://svn.ec-earth.org/ecearth3/$BRANCH $BRANCH
    fi
}

ecconfig () {
    cd ${BLDROOT}/${BRANCH}/sources
    expand-variables ${thisdir}/config-build-sisu-cray-craympi.xml config-build.xml
    patch -p0 -u < ${thisdir}/ecconf.patch
    ./util/ec-conf/ec-conf --platform=sisu-cray-craympi config-build.xml
}

oasis () {
    cd ${BLDROOT}/${BRANCH}/sources/oasis3-mct/util/make_dir
    FCLIBS=" " make -f TopMakefileOasis3 BUILD_ARCH=ecconf
}

#lucia() {
#    cd ${BLDROOT}/${BRANCH}/sources/oasis3-mct/util/lucia
#    lucia -c
#}

xios () {
    cd ${BLDROOT}/${BRANCH}/sources/xios-2
    svn export http://forge.ipsl.jussieu.fr/ioserver/svn/XIOS/trunk/arch/arch-XC30_Cray.fcm arch/arch-ecconf.fcm
    sed -i -e 's/^%PROD_CFLAGS.*/%PROD_CFLAGS    -O2 -DBOOST_DISABLE_ASSERTS/' \
	   -e 's/^%PROD_FFLAGS.*/%PROD_FFLAGS    -O2 -J..\/inc/' arch/arch-ecconf.fcm
    ./make_xios --arch ecconf --job 8
}

nemo () {
    cd ${BLDROOT}/${BRANCH}/sources/nemo-3.6/CONFIG
    ./makenemo -n ORCA1L75_LIM3 -m ecconf
}

oifs () {
    cd ${BLDROOT}/${BRANCH}/sources/ifs-36r4

    # These are clear bugs...
    patch -f -p0 < ${thisdir}/ifs.patch

    make BUILD_ARCH=ecconf -j 8 lib
    make BUILD_ARCH=ecconf master

    # And here is something fishy going on with the build system...
    touch $(make BUILD_ARCH=ecconf master 2>&1 | grep -o '^[^:]*\.F90:' | tr -d ':' | sort -u)
    make BUILD_ARCH=ecconf -j 8 lib
    make BUILD_ARCH=ecconf master
    touch $(make BUILD_ARCH=ecconf master 2>&1 | grep -o '^[^:]*\.F90:' | tr -d ':' | sort -u)
    make BUILD_ARCH=ecconf -j 8 lib
    make BUILD_ARCH=ecconf master
    touch $(make BUILD_ARCH=ecconf master 2>&1 | grep -o '^[^:]*\.F90:' | tr -d ':' | sort -u)
    make BUILD_ARCH=ecconf -j 8 lib
    make BUILD_ARCH=ecconf master
}


tm5 () {
    cd ${BLDROOT}/${BRANCH}/sources/tm5mp
    # Patch tm5
    patch -p0 -u < ${thisdir}/tm5-cray.patch
    rm proj/cb05/boundary.F90.orig
    export PATH=${BLDROOT}/${BRANCH}/sources/util/makedepf90/bin:$PATH
    ./setup_tm5 -n -j 4 ecconfig-ecearth3.rc
}

runoff-mapper () {
    cd ${BLDROOT}/${BRANCH}/sources/runoff-mapper/src
    make
}

amip-forcing () {
    cd $EC3SOURCES/amip-forcing/src
    make
}

# Install
install_all () {
    cd $EC3SOURCES
    mkdir -p ${INSTALL_BIN}
    cp -f  \
	$EC3SOURCES/xios-2/bin/xios_server.exe \
	$EC3SOURCES/nemo-3.6/CONFIG/ORCA1L75_LIM3/BLD/bin/nemo.exe \
	$EC3SOURCES/ifs-36r4/bin/ifsmaster-ecconf \
	$EC3SOURCES/runoff-mapper/bin/runoff-mapper.exe \
	$EC3SOURCES/amip-forcing/bin/amip-forcing.exe \
	$EC3SOURCES/tm5mp/build/appl-tm5.x \
	/appl/climate/bin/cdo \
	$EC3SOURCES/oasis3-mct/util/lucia/lucia.exe \
	$EC3SOURCES/oasis3-mct/util/lucia/lucia \
	$EC3SOURCES/oasis3-mct/util/lucia/balance.gnu \
	${INSTALL_BIN}
}

# Create run directory and fix stuff

create_ece_run () {
    cd $WRKDIR
    mkdir -p $ECERUNTIME
    cp -fr $BDIR/$EC3/runtime/* $ECERUNTIME/
    cp -f $SCRIPTDIR/sisu.cfg.tmpl $ECERUNTIME/classic/platform/
    cd $ECERUNTIME
    cp classic/ece-esm.sh.tmpl classic/ece-ifs+nemo+tm5.sh.tmpl
    sed "s|THIS_NEEDS_TO_BE_CHANGED|${INSTALL_BIN}|" $SCRIPTDIR/rundir.patch | patch -u -p0
    mkdir -p $ECERUNTIME/tm5mp
    cd $ECERUNTIME/tm5mp
    cp -rf $EC3SOURCES/tm5mp/rc .
    cp -fr $EC3SOURCES/tm5mp/bin .
    cp -fr $EC3SOURCES/tm5mp/build .
    ln -s bin/pycasso_setup_tm5 setup_tm5
}

apply_ECE_mods() {
    cd $EC3SOURCES
    patch -u -p0 < $SCRIPTDIR/$1
}



### Execute the functions if this script is not sourced ###

if [ "$notsourced" ]; then

    updatesources

#    if [ $# -eq 1 ]; then
#	( apply_ECE_mods $1 2>&1 ) > $BDIR/$EC3/modifications.log
#    fi

    # { module list -t 2>&1 } > $BDIR/$EC3/modules.log
    # { ecconfig       2>&1 } > $BDIR/$EC3/ecconf.log
    # { oasis    2>&1 } > $BDIR/$EC3/oasis.log    &
    # wait
    # { compile_lucia    2>&1 } > $BDIR/$EC3/lucia.log    &
    # { xios     2>&1 } > $BDIR/$EC3/xios.log &
    # { tm5      2>&1 } > $BDIR/$EC3/tm5.log  &
    # wait
    # { oifs     2>&1 } > $BDIR/$EC3/ifs.log &
    # { nemo     2>&1 } > $BDIR/$EC3/nemo.log &
    # { runoff   2>&1 } > $BDIR/$EC3/runoff.log &
    # wait
    # { amipf    2>&1 } > $BDIR/$EC3/amipf.log &
    # wait
    # install_all
    # create_ece_run
fi
