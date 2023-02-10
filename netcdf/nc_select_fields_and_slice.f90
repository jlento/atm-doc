  ! : || module load netcdf-fortran && $FC -cpp -ffree-line-length-none -I $NETCDF_FORTRAN_INSTALL_ROOT/include -lnetcdff $0 && exec ./a.out "$@"

  ! 2023-02-03, juha.lento@csc.fi
  !
  ! Minimum effort

#define CHECK(istat) if ((istat) /= nf90_noerr) then; \
  write(error_unit,'(a," (",i0,"): ",a)') \
  __FILE__ , __LINE__ , trim(nf90_strerror((istat))); \
  stop 1; \
end if

program nc
  use iso_fortran_env
  use netcdf
  implicit none

  ! "cdo command arguments" - could be read as actual command line arguments
  ! (lazy)
  character(len=*), parameter :: in = 'in.nc'
  character(len=*), parameter :: out = 'out.nc'
  integer, parameter :: nfield = 3
  character(len=5), parameter :: field_name(nfield) = &
       ['UMEAN', 'VMEAN', 'WMEAN']
  integer, parameter :: slice(4) = [100,100,0,1000]

  ! Dimensions - could be read from the input file (lazy)
  character(12), parameter :: dim_name(4) = &
       [character(len=12) :: 'west_east', 'south_north', 'bottom_top', 'Time'] 
  integer, parameter :: ndim_in(4) = [201, 1001, 139, 9]
  integer, parameter :: ndim_out(4) = &
       [slice(2) - slice(1) + 1, slice(4) - slice(3) + 1, 139, 9]

  ! Regular "work" variable defs
  integer :: i, j, istat
  integer :: ncid_in, varid_in(nfield)
  integer :: ncid_out, varid_out(nfield), dimid_out(4)
  real :: data(ndim_out(1), ndim_out(2), ndim_out(3), 1) = 0

  ! Open input file and read variable ids for the fields
  istat = nf90_open(in, NF90_NOWRITE, ncid_in)
  CHECK(istat)
  do i = 1, nfield
     istat = nf90_inq_varid(ncid_in, field_name(i), varid_in(i))
     CHECK(istat)
  end do

  ! Open output file and create dimensions and variables
  istat = nf90_create(out, NF90_WRITE, ncid_out)
  do i = 1, 4
     istat = nf90_def_dim(ncid_out, dim_name(i), ndim_out(i), dimid_out(i))
     CHECK(istat)
  end do
  do i = 1, nfield
     istat = nf90_def_var(ncid_out, field_name(i), NF90_REAL, dimid_out, &
          varid_out(i))
     CHECK(istat)
  end do
  istat = nf90_enddef(ncid_out)
  CHECK(istat)

  ! Copy the slice from the output to input, the actual work
  do i = 1, ndim_in(4)
     do j = 1, nfield
        istat = nf90_get_var(ncid_in, varid_in(j), data, &
             start = [slice(1) + 1, slice(3) + 1, 1, i], &
             count = [ndim_out(1), ndim_out(2), ndim_out(3), 1])
        CHECK(istat)
        istat = nf90_put_var(ncid_out, varid_out(j), data, &
             start = [1, 1, 1, i], &
             count = [ndim_out(1), ndim_out(2), ndim_out(3), 1])
        CHECK(istat)
     end do
  end do

  ! Close files
  istat = nf90_close(ncid_in)
  CHECK(istat)
  istat = nf90_close(ncid_out)
  CHECK(istat)

end program nc
