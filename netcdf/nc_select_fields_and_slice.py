#!/usr/bin/env python
import numpy as np
import netCDF4 as nc

ds_in = nc.Dataset("in.nc", mode="r")
ds_out = nc.Dataset("out.nc", mode="w")

# Create output file dimensions
_ = ds_out.createDimension("Time", None)
_ = ds_out.createDimension("bottom_top", ds_in.dimensions["bottom_top"].size)
_ = ds_out.createDimension("south_north", ds_in.dimensions["south_north"].size)
_ = ds_out.createDimension("west_east", 1)

# Create output variables
_ = ds_out.createVariable("UMEAN", "f4", ("Time", "bottom_top", "south_north", "west_east"))
_ = ds_out.createVariable("VMEAN", "f4", ("Time", "bottom_top", "south_north", "west_east"))
_ = ds_out.createVariable("WMEAN", "f4", ("Time", "bottom_top", "south_north", "west_east"))

for t in range(ds_in.dimensions["Time"].size):
    for s in ["UMEAN", "VMEAN", "WMEAN"]:
        ds_out.variables[s][t,:,:,:] = ds_in.variables[s][t,:,:,100:101]

ds_in.close()
ds_out.close()
