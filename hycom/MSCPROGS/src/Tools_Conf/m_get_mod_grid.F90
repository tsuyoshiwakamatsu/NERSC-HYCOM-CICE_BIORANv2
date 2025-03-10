! File:        m_get_mod_cnfg.F90
!
! Created:     Novermber 2018
!
! Author:      T.Wakamatsu (tsuyoshi.wakamatsu@nersc.no)
!
! Purpose:     Read hycom model grid and depth data
!
! Description: This file is designed based on the NERSC hycom utility:
!
!                hycom/MSCPROGS/src/Nersclib/mod_grid.F90
!
!              Read modlon, modlat and depths from hycom configuration files:
!
!                regional.grid.a
!                regional.depth.a
!
!              Note the two utility modules need to be linked at its compilation. See make.inc.
!
! History:     
!
module m_get_mod_cnfg
  
  implicit none
  logical, parameter, private :: VERBOSE = .false.

  integer :: iarec, ios
  real(kind=4), allocatable :: w(:)

contains 

subroutine get_mod_cnfg(modlon,modlat,depths,mindx,meandx,nx,ny)
   implicit none

   integer,                intent(in)  :: nx,ny
   real, dimension(nx,ny), intent(out) :: modlon, modlat, depths
   real,                   intent(out) :: mindx, meandx

   real,    dimension(:,:), allocatable :: var2D, scpy, scpx

   logical :: exa, exa2
   integer :: nop=67, ios, nrecl
   real :: xmax, xmin

   !!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!
   ! Read position from model files

   inquire(file='regional.grid.a',exist=exa)

   if (exa) then
     write(*,*) 'Load grid positions from file: regional.grid.a'

     allocate(var2D(nx,ny))
     allocate(mask (nx,ny)) 

     nrecl=4*size(var2D)

     open(unit=nop+1000, file='regional.grid.a', &
     &     form='unformatted', status='old', &
     &     access='direct', recl=nrecl, action='read', iostat=ios)

     read(unit=nop+1000, rec=1, iostat=ios) modlon
     read(unit=nop+1000, rec=2, iostat=ios) modlat
     read(unit=nop+1000, rec=10,iostat=ios) scpx
     read(unit=nop+1000, rec=11,iostat=ios) scpy

     close(unit=nop+1000)

     if (master) write(*,*) 'nrecl=', nrecl, ' [get_mod_grid]' 
     if (master) write(*,*) 'ios  =', ios, ' [get_mod_grid]' 

     !call zaiopf('regional.grid.a','old',nop)
     !call zaiord(var2D,mask,.false.,xmin,xmax,nop); modlon=var2D ! 1 plon: longitude at p-grid 
     !call zaiord(var2D,mask,.false.,xmin,xmax,nop); modlat=var2D ! 2 plat: latitude  at p-grid
     !call zaiord(var2D,mask,.false.,xmin,xmax,nop)               ! 3 qlon: longitude at q-grid (vorticity) 
     !call zaiord(var2D,mask,.false.,xmin,xmax,nop)               ! 4 qlat: latitude  at q-grid (vorticity)
     !call zaiord(var2D,mask,.false.,xmin,xmax,nop)               ! 5 ulon: longitude at u-grid 
     !call zaiord(var2D,mask,.false.,xmin,xmax,nop)               ! 6 ulat: latitude  at u-grid
     !call zaiord(var2D,mask,.false.,xmin,xmax,nop)               ! 7 vlon: longitude at v-grid 
     !call zaiord(var2D,mask,.false.,xmin,xmax,nop)               ! 8 vlat: latitude  at v-grid
     !call zaiord(var2D,mask,.false.,xmin,xmax,nop)               ! 9 pang: rotation angle of x-grid direction rel to local lat line
     !call zaiord(var2D,mask,.false.,xmin,xmax,nop); scpx=var2D   !10 scpx: zonal grid distance at p-point
     !call zaiord(var2D,mask,.false.,xmin,xmax,nop); scpy=var2D   !11 scpy: meridional grid distance at p-point
     !call zaiord(var2D,mask,.false.,xmin,xmax,nop)               !12 scqx: zonal grid distance at q-point (vorticity)
     !call zaiord(var2D,mask,.false.,xmin,xmax,nop)               !13 scqy: meridional grid distance at q-point
     !call zaiord(var2D,mask,.false.,xmin,xmax,nop)               !14 scux: zonal grid distance at u-point
     !call zaiord(var2D,mask,.false.,xmin,xmax,nop)               !15 scuy: meridional grid distance at u-point
     !call zaiord(var2D,mask,.false.,xmin,xmax,nop)               !16 scvx: zonal grid distance at v-point
     !call zaiord(var2D,mask,.false.,xmin,xmax,nop)               !17 scvy: meridional grid distance at v-point
     !call zaiord(var2D,mask,.false.,xmin,xmax,nop)               !18 cori: Coriolis parameter at q-point
     !call zaiord(var2D,mask,.false.,xmin,xmax,nop)               !19 pasp: v-grid aspect ratios for diffusion (=scpx/scpy)
     !call zaiocl(nop)
   else
     if (master) write(*,*) 'ERROR: regional.grid.a is not present [get_mod_grid]' 
     stop
   endif

   !!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!
   ! Read depths from model files

   inquire(file='regional.depth.a',exist=exa2)

   if (exa2) then
     if (master .and. VERBOSE) write(*,*) 'Load depths from file: regional.depth.a'

     open(unit=nop+1000, file='regional.depth.a', &
     &     form='unformatted', status='old', &
     &     access='direct', recl=nrecl, action='read', iostat=ios)

     read(unit=nop+1000, rec=1, iostat=ios) depths

     close(unit=nop+1000)

     !call zaiopf('regional.depth.a','old',nop)
     !call zaiord(depths,mask,.false.,xmin,xmax,nop)
     !call zaiocl(nop)
   else
     if (master) write(*,*) 'ERROR: regional.depth.a is not present [get_mod_grid]' 
     stop
   endif

   !!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!
   ! Check grid size

   mindx  = min(real(minval(scpx)), real(minval(scpy)))
   meandx = sum(scpx, mask = depths > 1.0d0 .and. depths < 1.0d25) / real(count(depths > 1.0d0 .and. depths < 1.0d25))
   if (master .and. VERBOSE) then
    print *,'MINIMUM grid size from scpx/scpy : ',mindx
    print *,'   MEAN grid size from scpx/scpy : ',meandx
   end if

   ! Safety check ..
   if (mindx<2000.) then
      if (master .and. VERBOSE) then
         print *,'min grid size lower than safety threshold - fix if you want'
         print *,'(get_mod_grid)'
      end if
      stop
   end if

   ! Safety check .. This one is not that critical so the value is set high
   if (mindx>500000.) then
      if (master .and. VERBOSE) then
         print *,'min grid size higher than safety threshold - fix if you want'
         print *,'(get_mod_grid)'
      end if
      stop
   end if

end subroutine  get_mod_cnfg

subroutine open_hycom_var2d(nop,fname,idm,jdm)
  implicit none

  integer, intent(in) :: nop, idm, jdm
  character(len=STRLN), intent(in) :: fname

  logical :: exa
  integer :: n2drec, nrecl

  n2drec = ((idm*jdm+4095)/4096)*4096
  allocate( w(n2drec) )
  inquire(iolength=nrecl) w

  inquire(file=TRIM(fname),exist=exa)

  if ( exa ) then
    open(nop,file=TRIM(fname),form='unformatted',status='old',access='direct',recl=nrecl,action='read',iostat=ios)
  else
    print *,'Can not find',TRIM(fname)
    stop
  endif

  iarec = 0

end subroutine open_hycom_var2d

subroutine read_hycom_var2d(nop,var2d,idm,jdm)
  implicit none

  integer, intent(in) :: nop, idm, jdm
  real(kind=4), dimension(idm,jd), intent(out) :: var2d

  integer :: i, j
  real(kind=4), parameter :: spval=2.0**100

  iarec = iarec + 1

  read(nop,rec=1,iostat=ios) w

  wmin =  spval 
  wmax = -spval 

  do j= 1,jdm
    do i= 1,idm
      if (w(i+(j-1)*idm).ne.spval) then
        wmin = min( wmin, w(i+(j-1)*idm) )
        wmax = max( wmax, w(i+(j-1)*idm) )
      endif
      var2d(i,j) = w(i+(j-1)*idm)
    enddo
  enddo

  print *, 'h(50,50):',SNGL(var2d(50,50))
  print *, 'wmax    :',SNGL(wmax)
  print *, 'wmin    :',SNGL(wmin)

end subroutine read_hycom_var2d

subroutine close_hycom_var2d(nop)
  implicit none
  integer, intent(in) :: nop

  close(nop,iostat=ios)

  deallocate(w)

end subroutine close_hycom_var2d

end module  m_get_mod_cnfg
