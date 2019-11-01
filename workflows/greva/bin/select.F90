! Reads individual fitnesses from stdin and prints out the selected
! parent indices (start from 0) to stdout.
!
! Build: gfortran -o select select.f90
!
! Use: ./select < fitnesses.dat > parents.dat
!
! Probability of choosing an individual is linearly proportional to it's
! fitness. It is easy to change in read_cumulative_sum(), for example.

program select
  implicit none

  integer, parameter :: m = 2048  ! Maximum array size

  integer :: n         ! Number of individuals
  real    :: s(m)      ! Cumulative sum of fitnesses

  call read_cumulative_sum(n, s)
  call write_sample_indices(n, s)

contains

  subroutine read_cumulative_sum(n, s)
    integer, intent(out) :: n
    real, intent(out)    :: s(:)
    real                 :: f, sf
    n = 0
    sf = 0
    do
       read(UNIT = *, FMT = *, END = 11) f
       n = n + 1
       if (n > m) then
          error stop 22
       end if
       sf = sf + f
       s(n) = sf
    end do
11  continue
  end subroutine read_cumulative_sum

  subroutine write_sample_indices(n, s)
    integer, intent(in) :: n
    real, intent(in)    :: s(:)
    real, allocatable   :: r(:)
    integer             :: i
    allocate(r(n))
#if defined __GFORTRAN__ || defined __INTEL_COMPILER
    call random_seed()
#else
#error Use GNU or Intel Fortran compiler
#endif
    call random_number(r)
    do i = 1, n
       write(*,'(I0)') linear_search(n, r(i)*s(n), s)
    end do
  end subroutine write_sample_indices

  function linear_search(n, v, s) result(i)
    integer, intent(in) :: n
    real, intent(in)    :: v
    real, intent(in)    :: s(:)
    integer             :: i
    i = 0
    do
       if (v .le. s(i+1)) exit
       i = i + 1
       if (i .gt. n) error stop 33
    end do
  end function linear_search

end program select
