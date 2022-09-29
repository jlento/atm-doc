# JSBACH build notes for puhti.csc.fi
#
# 2022-09-29, juha.lento@csc.fi

# These notes are for the tarball jsbach3.tar.gz from Leif @ FMI.
# Files 'env.sh' and 'landveg-compile-puhti.ksh' are from this repository.
# You need to 'env.sh' at least a bit, but hopefully not the file
# 'landveg-compile-puhti.ksh'.

cd $TMPDIR
tar xf $PROJAPPL/jsbach3.tar.gz
cd mpiesm-landveg

source env-puhti.sh
./landveg-compile-puhti.ksh
