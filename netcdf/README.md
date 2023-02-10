# Some netcdf examples

There are many tools for working with netcdf files, such as `cdo`. However,
sometimes it may be preferrably to work with the netcdf files more directly with
the routines from the netcdf library, or specialised Python packages. Netcdf
library routines have bindings for many languages, C, Fortran, Python, etc.

The key to efficient working with netcdf files is to understand in which order
the data is in the netcdf file, and then read and write the data in that order.
Netcdf has multiple data formats, but for practical purposes one can assume
"Classic" NetCDF file format,
https://docs.unidata.ucar.edu/nug/current/file_structure_and_performance.html .

```
+---------------------------------------------------------------------------+
| Header block
| ============
| - dimensions, attributes, etc
| - fixed size
|
| METADATA
+---------------------------------------------------------------------------+
| Data block 1
| ============
| - variable data for variables with fixed dimensions
| - each variable is contiguous
| - fixed size
|
| VARIABLE 1 (all data for this variable)
| VARIABLE 2 (all data for this variable)
| ...
+----------------------------------------------------------------------------+
| Data block 2
| ============
| - variable data for variables with one unlimited size dimension
| - each record (usually time step) in the unlimited dimension is contiguous
| - this block can grow (it is easy to append to a file)
|
| 1ST RECORD: VARIABLE 1 (Time=1), VARIABLE 2 (Time=1), ...
| 2ND RECORD: VARIABLE 1 (Time=2), VARIABLE 2 (Time=2), ...
| ...
|
```

The goal is to scan the data once from the beginning of the file to
the end. No hopping back and forth in the file. We can think of our program as a
filter, through which we pass the netcdf file. In many (most) cases our filter's
"width" is much smaller than the whole dataset, and we avoid reading the whole
file into memory.

# Select fields and a slice

In this example we would like to extract variables UMEAN, VMEAN and WMEAN from
the file `in.nc`, select a thin slice from those variables, and write the result
to the file `out.nc`.

## Using cdo

```console
$ cdo -selname,UMEAN,VMEAN,WMEAN -selindexbox,100,100,0,1000 in.nc out.nc
```

Unfortunately, if the input file is large, let's say 13GB, and has many
variables, the cdo command may be very slow (may take hours). We are not doing
any computations, only extracting data, so we know this operation should not
take long. This would be a good place to look for alternative solutions.

## Using Python xarray

Python xarray is probably the best thing to try next. As an added benefit, MetPy
and PyART use xarray data structures, and Dask integration makes parallelisation
easy. Also, with OpeNDAP remote datasets, xarray does lazy loading of only the
data one needs, not the whole dataset. For example,

```python
ds = xr.open_dataset("https://thredds.met.no/thredds/dodsC/mepslatest/meps_det_2_5km_20230210T09Z.ncml")
```

The xarray example is in file `nc_select_fields_and_slice_xarray.py`. It's
runtime for a 13GB test file (not included) is the same order as the more
explicit stream processing of the next two implementations.

## Python and Fortran with netcdf library calls

Let's first see how the data is arranged in the file. First, we check the
dimensions of the variables, and the sizes of the dimensions:

```console
$ ncdump -h in.nc | grep ' [UVW]MEAN('
	float UMEAN(Time, bottom_top, south_north, west_east) ;
	float VMEAN(Time, bottom_top, south_north, west_east) ;
	float WMEAN(Time, bottom_top, south_north, west_east) ;
$ ncdump -h in.nc | grep -A 5 dimensions:
dimensions:
	Time = UNLIMITED ; // (9 currently)
	DateStrLen = 19 ;
	west_east = 201 ;
	south_north = 1001 ;
	bottom_top = 139 ;
    
```

This looks like the most common case, there is a time series of variables. The
unlimited Time dimension is the "slowest" changing, i.e. first all the
variables, that have unlimited dimension, are in the file for the first time
step, then the second time step, etc. This suggests that when we read in the
data, we should loop over the Time dimension in the outermost loop. Inside the
time loop, we can loop over the variables, in the order they appear in the
ncdump output. There is no need to write any deeper loops over the dimensions,
as a slice of the data is specified in the netcdf library call itself.

Both "quick script" implementations, `nc_select_fields_and_slice.py` and
`nc_select_fields_and_slice.f90`, in Python and in Fortran 90, respectively,
perform about as fast. With the 13GB test file (not included) the runtimes on
Lustre are under 20 seconds, and on local disc under 10 seconds.

NOTE for Fortran users: In Fortran the most significant index, the index that
changes slowest, is the last index in multi-dimensional array. This is opposite
compared to C, `ncdump -h` command output, or Python, where the first index is
the most significant, and runs slowest. In practice, you need to reverse the
order of indices in Fortran, compared to C, and other languages/programs that
use the C like convention.
