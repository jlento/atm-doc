program process
  use mpi
  implicit none
  integer :: rank, ntasks, ierror
  character(len=256) :: infile, outfile, fieldname
  integer:: a, inunit, outunit
  call mpi_init(ierror)
  call mpi_comm_size(MPI_COMM_WORLD, ntasks, ierror)
  call mpi_comm_rank(MPI_COMM_WORLD, rank, ierror)
  if (rank == 0) then
     call get_command_argument(1, infile)
     call get_command_argument(2, outfile)
     print *, "Files:", infile, outfile
     open(newunit = inunit, file = infile)
     open(newunit = outunit, file = outfile, status = 'new')
     read(inunit, *) fieldname, a
     write(outunit, *) "Parameter and ntasks: ", a, ntasks
     close(inunit)
     close(outunit)
  end if
  call mpi_finalize(ierror)
end program process
