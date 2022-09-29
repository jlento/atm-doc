#!/bin/ksh
set -ex
#-------------------------------------------------------------------------------
#    script to compile the MPI-M earth system model components
#-------------------------------------------------------------------------------
#
# setup definitions
#
vers=I01                 # model version (tag used in the executable name)
cplmod=mpiesm-s          # coupled model name: mpiesm-s     (jsbach3, cbalance, hd)
                         #                     mpiesm-s4    (jsbach4)
                         #                     mpiesm-as    (echam6)
                         #                     mpiesm-as4   (echam6 with jsbach4)
                         #                     mpiesm-asob  (mpiesm-1.2)
compiler=intel           # compiler to be used (nag/intel/gcc)
configure=yes            # yes: run configure - mandatory if running the first time model version $vers
automake=no              # yes: run automake, e.g. if dependencies changed  (only with configure=yes)
make_argument="-j 4"     # number of processes for make, 'clean' or 'distclean'
                         #   (make clean needs the modules, thus script is helpful)

#
#-- consitency check
#
if [[ ${cplmod} = mpiesm-asob && ${compiler} != intel ]]; then
  echo "  ERROR: Compilation of mpiesm-asob currently only works with the intel compiler"
  exit 1
fi

[[ $# > 0 && $1 = --disable-configure ]] && configure=no

#------------------
# find out machine
#------------------
machine=linux-x64        # linux PC
[[ $(uname -n | cut -c1-6) = mlogin  ]] && machine=mistral
scriptdir=$(dirname $0)
cd ${scriptdir}
mpiesmdir=$(pwd)


#
#-- generate build directory and go there
#
#build=build-${cplmod}-${vers}-tilia
build=build-${cplmod}-${vers}-birch
# irrig has also birch phenology, but is meant mainly for grass
#build=build-${cplmod}-${vers}-irrig
# below not needed??
##build=build-${cplmod}-${vers}-dry     # no irrig
##build=build-${cplmod}-${vers}-dryrbs  # no irrig
[[ -d ${build} ]] || mkdir ${build}
cd ${build}
[[ -d bin ]] || mkdir bin


#-------------------------
# Load the modules needed
#-------------------------

# file listing all modules (also needed at runtime)
#echo '#!/bin/ksh'                         > modules_${vers}
#echo '. ${MODULESHOME}/init/ksh'         >> modules_${vers}
#echo "module purge         || true" >> modules_${vers}
#echo 'module load intel/19.0.4 intel-mpi/18.0.5 hdf5/1.10.4-mpi netcdf netcdf-fortran' >> modules_${vers}
#echo 'module load intel/18.0.5 intel-mpi/18.0.5 hdf5/1.10.4-mpi netcdf netcdf-fortran' >> modules_${vers}
#echo 'module load intel/18.0.1 intelmpi/18.0.1 hdf5-par/1.10.2 netcdf4/4.6.1' >> modules_${vers}

#chmod 755 modules_${vers}
#. ./modules_${vers}

# make link with the mpiexec version (used in run scripts)
#if [[ -f $(which srun 2> /dev/null) ]]; then
#  [[ -L bin/mpiexec_${vers} ]] || ln -s $(which srun) bin/mpiexec_${vers}
#fi
cat > bin/mpiexec_${vers} <<'EOF'
#!/bin/bash
srun "$@"
EOF
chmod ug+xr bin/mpiexec_${vers}
cp -f bin/mpiexec_${vers} $PWD/bin/srun

#-------------
# Compilation
#-------------

if [[ ${configure} = yes ]] then
  cd ../src/echam
  if [[ ${cplmod} = mpiesm-as4 ||  ${cplmod} = mpiesm-s4 ]]; then
    cd src
    if [[ ! -d src_jsbach4 ]]; then
      git clone git@git.mpimet.mpg.de:jsbach.git src_jsbach4
      cd src_jsbach4
      git checkout jsbach4echam
      cd ..
    fi
    [[ -d src_dsl4jsb ]] || mkdir src_dsl4jsb
    src_jsbach4/scripts/dsl4jsb/dsl4jsb.py -p _dsl4jsb -k -d src_jsbach4/src -t src_dsl4jsb
    cd ..
  fi
  if [[ ${automake} = yes ]] then
    config/createMakefiles.pl
    [[ ${machine} = mistral ]] && module load autoconf/2.69 automake/1.14.1
    automake
  fi
  if [[ ! -f src/Makefile.am ]]; then
    # Makefile.am is not under version control in mpiesm-landveg and needs to be generated if not yet there.
    config/createMakefiles.pl
  fi
  cd ../../${build}
fi

#
#-- find out jsbach version: jsbach3 or jsbach4
#
if [[ $(echo ${cplmod} | grep 4) != "" ]] then
  jsbach_vers=jsb4
  enable_jsbvers="--enable-jsbach4"
else
  jsbach_vers=jsb3
  enable_jsbvers=""
fi

#
#-- configure the model version
#
if [[ ${configure} == yes ]]; then

  if [[ ${cplmod} = mpiesm-as ||  ${cplmod} = mpiesm-as4 ]] then
    # configuration for echam (including jsbach)

    case ${machine} in
      linux-x64 )
        ../src/echam/configure --with-fortran=${compiler} ${enable_jsbvers}
        ;;
      mistral )
        ../src/echam/configure --disable-shared --with-fortran=${compiler} --enable-cdi-pio ${enable_jsbvers}
        ;;
    esac

  elif [[ ${cplmod} = mpiesm-s ||  ${cplmod} = mpiesm-s4 ]] then
    # configuration for standalone versions of jsbach, cbalance and hd

    case ${machine} in
      linux-x64 )
        ../src/echam/configure --with-fortran=${compiler} --enable-jsbach-standalone ${enable_jsbvers}
# --with-hdf5=${HDF5_INSTALL_ROOT}
        ;;
      mistral )
        ../src/echam/configure --disable-shared --with-fortran=${compiler} --enable-jsbach-standalone ${enable_jsbvers}
        ;;
    esac

  elif [[ ${cplmod} = mpiesm-asob ]] then
    # configuration of the ESM: echam6, jsbach3, mpiom, hamocc

    cd ${mpiesmdir}
    ./configure

  else
    echo "setup for ${cplmod} not yet supported"
    exit
  fi
elif [[ ${cplmod} = mpiesm-asob ]] then
  cd ${mpiesmdir}
fi

#
#-- do the compilation
#

# Avoid write error with parallel make (only available with make version >= 4)
[[ $(make --version | awk 'NR==1{split($NF,v,"."); printf("%1d", v[1])}') > 3 ]] && \
    make_argument="${make_argument} --output-sync=target" || \
    echo -e "\033[0;31mYou're using make version < 4 with $make_argument ... if make aborts with write error, just restart it to continue (or use fewer processes)!\033[0m"

# Avoid modification printing in case echam Makefile.am is under version control
if [[ ${jsbach_vers} == jsb3  && \
        $(svn status ${mpiesmdir}/src/echam/src/Makefile.am | grep ^M) != "" ]]; then
    echo -en "\033[0;31m WARNING: src/echam/src/Makefile.am is modified. This leads to a modified (M) source code revision stamp: "
    svnversion  ${mpiesmdir}/src/echam/src/
    echo -e "   which you do not want to have in any serious simulation. \033[0m"
    echo " - If you are not aware of any changes, revert Makefile.am ('svn revert src/echam/src/Makefile.am')" 
    echo "   and set 'automake=no' in the upper section of this script."   
    echo " - If you are aware of changes and do not mind the modification stamp, ignore this message and"
    echo "   delete 'exit 1' below."
    echo " - If you are aware of changes and want to use this executable for a serious simulation, think about"
    echo "   committing your changes, perhaps to a private branch."
    exit 1
fi

make ${make_argument}
make install

#
#-- mv executable(s) to the bin directory
#
if [[ ${cplmod} = mpiesm-asob ]] then
  cd ${mpiesmdir}/${build}
fi

echo ""

if [[ ${cplmod} = mpiesm-s ]] then

  [[ -x  src/jsbach3 ]] || exit 1
  mv src/jsbach3  bin/jsbach3_${vers}.x
  mv src/cbalance bin/cbalance_${vers}.x
  mv src/hd       bin/hd_${vers}.x
  echo "Executables: "
  echo "   $(pwd)/bin/jsbach3_${vers}.x"
  echo "   $(pwd)/bin/cbalance_${vers}.x"
  echo "   $(pwd)/bin/hd_${vers}.x"

elif [[ ${cplmod} = mpiesm-s4 ]] then

  [[ -x  src/jsbach4 ]] || exit 1
  mv src/jsbach4  bin/jsbach4_${vers}.x
  echo "Executables: "
  echo "   $(pwd)/bin/jsbach4_${vers}.x"

elif [[ ${cplmod} = mpiesm-as ||  ${cplmod} = mpiesm-as4 ]] then

  [[ -x  src/echam6 ]] || exit 1
  mv src/echam6   bin/echam6_${vers}.x
  echo "Executable: "
  echo "   $(pwd)/bin/echam6_${vers}.x"

elif [[ ${cplmod} = mpiesm-asob ]] then

  [[ -x ../src/echam/src/echam6 ]] || exit 1
  mv ../src/echam/src/echam6  bin/echam6_${vers}.x
  mv ../src/mpiom/bin/mpiom.x bin/mpiom_${vers}.x
  echo "Executables: "
  echo "   $(pwd)/bin/echam6_${vers}.x"
  echo "   $(pwd)/bin/mpiom_${vers}.x"

fi
echo""
