#!/bin/bash

# Install PALM 6.0 in puhti.csc.fi
# 2020-02-27, juha.lento@csc.fi

: ${PROJECT:?Please set PROJECT environment variable}

puhti_palm_files="https://raw.githubusercontent.com/jlento/atm-doc/master/PALM/puhti.csc.fi"

eval "$(wget -O - $puhti_palm_files/env.sh)"

builddir=$TMPDIR
installdir=/projappl/$PROJECT/palm

svn checkout --username NNN --password NNN https://palm.muk.uni-hannover.de/svn/palm/trunk $builddir/palm

wget -O $builddir/palm/INSTALL/MAKE.inc.ifort.puhti $puhti_palm_files/MAKE.inc.ifort.puhti


# Build

cd $builddir/palm
PATH=$PWD/SCRIPTS:$PATH
palm_simple_build -b ifort.puhti


# Install

mkdir -p $installdir/bin
cp $builddir/BUILD_ifort.puhti/palm $installdir/bin/


# Test

cp -r $builddir/palm/TESTS/cases/example_cbl /scratch/$PROJECT/
cd /scratch/$PROJECT/example_cbl
ln -s INPUT/example_cbl_p3d PARIN
srun -A $PROJECT -p test -n 4 $installdir/bin/palm < case_config.yml
diff -a -y -W $COLUMNS RUN_CONTROL MONITORING/example_cbl_rc | less


# The test using a batch file

cat > job.sh <<EOF 
#!/bin/bash
#SBATCH -A $PROJECT
#SBATCH -n 4
#SBATCH -p test

eval "$(wget -O - $puhti_palm_files/env.sh)"
cd /scratch/$PROJECT/example_cbl
srun $installdir/bin/palm < case_config.yml
EOF

sbatch job.sh
