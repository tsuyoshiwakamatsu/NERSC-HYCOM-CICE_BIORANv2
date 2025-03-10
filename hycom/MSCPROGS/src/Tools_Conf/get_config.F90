program main
  use m_io_hycom
  use m_io_direct
  use m_get_mod_cnfg
  implicit none
  
  integer :: ios
  integer, parameter:: idm=400, jdm=380
  character(len=8) :: cnfg='TP2a0.10'

  real(kind=4) :: wmin,wmax
  real(kind=4), dimension(idm,jdm) :: var2d
  character(len=512) :: fname, fname2

  real(kind=4) :: mindx, meandx
  real(kind=4), dimension(idm,jdm) :: modlon, modlat, depths

  !-- read model configuration

  !call get_mod_cnfg(modlon,modlat,depths,mindx,meandx,idm,jdm)

  !-- convert hycom model grid files to fortran direct binary file

  fname2='./TMP/config_'//cnfg//'.dat'
  call open_direct_sngl_var2d(20,fname2,idm,jdm,'new')

  fname='../config/'//cnfg//'/topo/regional.depth.a'
  call open_hycom_var2d(10,fname,idm,jdm,'old')
  call read_hycom_var2d(10,var2d,wmax,wmin,idm,jdm,1) ! depth
  call write_direct_sngl_var2d(20,var2d,idm,jdm,1)    ! depth
  call close_hycom_var2d(10)

  fname='../config/'//cnfg//'/topo/regional.grid.a'
  call open_hycom_var2d(10,fname,idm,jdm,'old')
  call read_hycom_var2d(10,var2d,wmax,wmin,idm,jdm,1) ! plon
  call write_direct_sngl_var2d(20,var2d,idm,jdm,2)    ! plon
  call read_hycom_var2d(10,var2d,wmax,wmin,idm,jdm,2) ! plat
  call write_direct_sngl_var2d(20,var2d,idm,jdm,3)    ! plat
  call close_hycom_var2d(10)

  call close_direct_var2d(20)

  !-- test reading hycom config file

  call open_direct_sngl_var2d(20,fname2,idm,jdm,'old')
  call read_direct_sngl_var2d(20,var2d,wmax,wmin,idm,jdm,1) ! depth
  call read_direct_sngl_var2d(20,var2d,wmax,wmin,idm,jdm,2) ! plon
  call read_direct_sngl_var2d(20,var2d,wmax,wmin,idm,jdm,3) ! plat
  call close_direct_var2d(20)

  write(*,*) 'Config file: '//TRIM(fname2)//' is ready.'

end program main

