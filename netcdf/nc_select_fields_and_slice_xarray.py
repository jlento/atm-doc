import xarray as xr

ds = xr.open_dataset("in.nc")
ds = ds[["UMEAN", "VMEAN", "WMEAN"]]
ds = ds.isel(west_east=slice(100,101))
ds.to_netcdf("out.nc")
