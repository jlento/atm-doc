# Building EC-Earth3 in Cray XC40 at CSC

Notes and comments on building coupled climate model EC-Earth3 in the
configuration used for CMIP6 AerChemMIP experiment in Cray XC40, sisu.csc.fi.


## Using Intel compiler suite

Check first the subdirectory with the latest tag number, for example [3.3.0].
The script `build.sh` should build the tagged version without modifications.
Read first the "usage" from the start of the script.

[3.3.0]: (3.3.0)


# Old build instructions

The current build process using Intel and Cray compiler suites is documented in the files [build-intel.bash](build-intel.bash) and [build.bash](build.bash), respectively.


Build notes, Cray compiler suite
-----------------------------------------------------

- Branch: branches/development/2014/r1902-merge-new-components
- revision 4608

Some of these comments/fixes apply to the trunk, and may be irrelevant.

This branch should be merged to trunk?


### External libraries


```
cray-hdf5-parallel
cray-netcdf-hdf5parallel
grib_api/1.23.1
hdf/4.2.12
libemos/4.0.7
```

NOTE: Ancient and unsupported library gribex is too broken. The
same(?) subroutines can be found from an old version of (also
depricated) libemos.


### config-build.xml

For Cray compiler suite in sisu.csc.fi in file `config-build-sisu-cray-craympi.xml`.


### XIOS-2

The template for XIOS-2 `arch/arch-ecconf.fcm` is
unfinished/broken/missing placeholders. The file `http://forge.ipsl.jussieu.fr/ioserver/svn/XIOS/trunk/arch/arch-XC30_Cray.fcm` is used here as a starting point, with the following changes (should be templated in EC-Earth build?):

```
sed -i -e 's/^%PROD_CFLAGS.*/%PROD_CFLAGS    -O2 -DBOOST_DISABLE_ASSERTS/' \
	   -e 's/^%PROD_FFLAGS.*/%PROD_FFLAGS    -O2 -J..\/inc/'
```


### IFS

The used old version of IFS has two clear bugs that need to be fixed before Cray compiler agrees to compile it. Suggested fixes are in `ifs.pathc`.

Also, the build system(?) assigns the same name/number to some DRHOOK symbols in different object files, which causes problems at the linking stage. A dirty fix is to recompile the object files that contain duplicated symbol names:

```
make BUILD_ARCH=ecconf -j 8 lib
make BUILD_ARCH=ecconf master
touch $(make BUILD_ARCH=ecconf master | grep -o '^[^:]*\.F90:' | tr -d ':' | sort -u)
make BUILD_ARCH=ecconf master
```


### TM5

Cray compiler throws an internal compiler error for `epischeme.F90` at `-O2` optimization level. Dirty fix (should actually be fixed in the TM5 build configuration):

```
./setup_tm5 -n -j 4 ecconfig-ecearth3.rc
cd build
ftn -c -o ebischeme.o -h flex_mp=strict -h noomp -sreal64 -N 1023 -O1 -I/tmp/jlento/ece3/trunk/sources/oasis3-mct/ecconf/build/lib/psmile.MPI1 -I/opt/cray/netcdf-hdf5parallel/4.4.1/CRAY/8.3/include -I/opt/cray/hdf5-parallel/1.10.0.1/CRAY/8.3/include  ebischeme.F90
cd -
./setup_tm5 -j 4 ecconfig-ecearth3.rc

```
