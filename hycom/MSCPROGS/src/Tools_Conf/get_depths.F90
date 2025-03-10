program main
  use m_io_hycom
  use m_io_direct
  use m_io_binary
  use m_get_mod_cnfg
  implicit none
  
  integer :: ios
  integer :: idm, jdm
  !integer, parameter:: idm=400, jdm=380
  character(len=8) :: cnfg='TP2a0.10'
  character(len=5) :: label

  real(kind=4) :: wmin,wmax
  real(kind=4), allocatable, dimension(:,:) :: var2d
  real(kind=8) :: dwmin,dwmax
  real(kind=8), allocatable, dimension(:,:) :: dvar2d
  character(len=512) :: fname, fname2

  character(len=5) :: str_idm, str_jdm
  
  !-- read dimension from b file
  fname='regional.grid.b'
  open(unit=10,file=fname, status='old', action='read')
  read(10,*) idm, label
  read(10,*) jdm, label
  close(10)  

  !-- allocate arrays

  allocate(var2d(idm,jdm))
  allocate(dvar2d(idm,jdm))

  !-- convert dimension to strings
  write(str_idm,'(i5)') idm
  write(str_jdm,'(i5)') jdm
  write(*,*) trim(label)//': '//trim(adjustl(str_idm))
  write(*,*) trim(label)//': '//trim(adjustl(str_jdm))

  !-- convert hycom model grid files to fortran direct binary file

  fname='regional.depth.a'
  call open_hycom_var2d(10,fname,idm,jdm,'old')
  call read_hycom_var2d(10,var2d,wmax,wmin,idm,jdm,1) ! depth
  call close_hycom_var2d(10)

  fname2='depths'//trim(adjustl(str_idm))//'x'//trim(adjustl(str_jdm))//'.uf'
  call open_dble_var2d(20,fname2,idm,jdm,'new')
  dvar2d = real(var2d, kind=8)  
  call write_dble_var2d(20,dvar2d,idm,jdm)    ! depth
  call close_file(20)

  !-- test reading hycom config file

  call open_dble_var2d(20,fname2,idm,jdm,'old')
  call read_dble_var2d(20,dvar2d,dwmax,dwmin,idm,jdm) ! depth
  call close_file(20)

  write(*,*) 'Config file: '//TRIM(fname2)//' is ready.'

end program main

