# EC-Earth 3.3.1.1 setup notes in puhti.csc.fi

juha.lento @ csc.fi, 2019-08-30


## Helper functions

There is a bunch of helper functions in [build.sh](build.sh). You can
simply source the script, and run only the functions you wish, or when
we get everything working perfectly, just run the whole script.


## Status

Hoping to use eccodes instead of grib-api, see [EC-Earth3 wiki
page](https://dev.ec-earth.org/projects/ecearth3/wiki/Using_eccodes_library).

Builds go through, except lpj-guess. LPJ-GUESS has issues with using
`int` instead of `MPI_Comm` C++ type for MPI communicator handles.

Functions `install_all` and `create_ece_run` are not adapted yet.


## Step by step

### Clone this repository

```console
git clone git@github.com:jlento/atm-doc.git
```

and change to EC-Earth 3.3.1.1 direcrtory

```console
cd atm-doc/EC-Earth3/3.3.1.1
```

### Import helper functions

```console
source build.sh
```

### Get the source

Find you ec-earth svn username and password. They need to be provided
at least the first time the sources are retrieved.

```console
updatesources
```


### Run ec-conf

### Check / modify configuration

Simply just create the configuration files with `ecconfig` from
[build.sh](build.sh),

```console
ecconfig
```

### Build model components

Run the build functions from [build.sh](build.sh), for example

```console
oasis
tm5
```
