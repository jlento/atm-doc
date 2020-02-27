#!/bin/bash

# Install PALM 6.0
# 2020-02-27, juha.lento@csc.fi

puhti_palm_files="https://raw.githubusercontent.com/jlento/atm-doc/master/PALM/puhti.csc.fi"

eval "$(wget -O - $puhti_palm_files/env.sh)"

builddir=$TMPDIR
install_root=$(projappl)/palm

svn checkout --username NNN --password NNN https://palm.muk.uni-hannover.de/svn/palm/trunk $builddir/palm

wget -O $builddir/palm/INSTALL/ $puhti_palm_files/MAKE.inc.ifort.puhti

mkdir -p $install_root


# Build

cd $builddir/palm
PATH=$PWD/SCRIPTS:$PATH
palm_simple_build -b ifort.puhti
