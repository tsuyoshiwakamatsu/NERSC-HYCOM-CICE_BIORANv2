! File:        m_io_direct.F90
!
! Created:     Novermber 2018
!
! Author:      T.Wakamatsu (tsuyoshi.wakamatsu@nersc.no)
!
! Purpose:     I/O module for FORTRAN direct access file in 2D
!
! History:     Double precision options added [Mar 2025] 
!
module m_io_direct
  
  implicit none
  integer, parameter :: STRLEN = 512
  logical, parameter, private :: VERBOSE = .false.

  integer, private :: ncall

contains 

  subroutine open_direct_sngl_var2d(nop,fname,idm,jdm,status)
  implicit none

  integer, intent(in) :: nop, idm, jdm
  character(len=STRLEN), intent(in) :: fname
  character(len=*), intent(in) :: status
  character(len=10) :: act, stat
  
  logical :: exa = .true.
  integer :: ios, nrecl

  nrecl = 4*idm*jdm

  inquire(file=TRIM(fname),exist=exa)

  stat = status

  if (TRIM(status) == 'old' ) then
     act = 'read'
     if ( .not. exa ) then
       print *,'Failed to open: ',TRIM(fname)
       stop
     endif
  else if (TRIM(status) == 'new' ) then
     act = 'write'
     if ( exa ) then
       stat = 'replace'
     endif
  endif     

  print *,'Open to '//TRIM(act)//': '//TRIM(fname)
  open(nop,file=TRIM(fname),form='unformatted',status=TRIM(stat),access='direct',recl=nrecl,action=TRIM(act),iostat=ios)

  if( ios .ne. 0 ) then
    print *,'ERROR, iostat = ',INT2(ios)
    stop
  endif

  ncall = 0

  end subroutine open_direct_sngl_var2d

  subroutine open_direct_dble_var2d(nop,fname,idm,jdm,status)
  implicit none

  integer, intent(in) :: nop, idm, jdm
  character(len=STRLEN), intent(in) :: fname
  character(len=*), intent(in) :: status
  character(len=10) :: act, stat
  
  logical :: exa = .true.
  integer :: ios, nrecl

  nrecl = 8*idm*jdm

  inquire(file=TRIM(fname),exist=exa)

  stat = status

  if (TRIM(status) == 'old' ) then
     act = 'read'
     if ( .not. exa ) then
       print *,'Failed to open: ',TRIM(fname)
       stop
     endif
  else if (TRIM(status) == 'new' ) then
     act = 'write'
     if ( exa ) then
       stat = 'replace'
     endif
  endif     

  print *,'Open to '//TRIM(act)//': '//TRIM(fname)
  open(nop,file=TRIM(fname),form='unformatted',status=TRIM(stat),access='direct',recl=nrecl,action=TRIM(act),iostat=ios)

  if( ios .ne. 0 ) then
    print *,'ERROR, iostat = ',INT2(ios)
    stop
  endif

  ncall = 0

  end subroutine open_direct_dble_var2d

  subroutine close_direct_var2d(nop)
    implicit none
    integer, intent(in) :: nop
    logical :: openedq
    character(len=STRLEN) :: fname
    
    inquire(unit=nop, opened=openedq, name=fname)

    if (openedq) then
      print *, 'Close: ',TRIM(fname)
      close(nop)
    else
      print *, 'I/O unit: ',INT2(nop),'not connected'
      stop
    endif

    ncall = 0

  end subroutine close_direct_var2d
    
  subroutine read_direct_sngl_var2d(nop,var2d,wmax,wmin,idm,jdm,iarec)
  implicit none

  integer, intent(in) :: nop, idm, jdm, iarec
  real(kind=4), dimension(idm,jdm), intent(out) :: var2d
  real(kind=4), intent(out) :: wmax, wmin

  integer :: ios, i, j
    !
    ! spval  = data void marker, 2^100 or about 1.2676506e30
    !
  real(kind=4), parameter :: spval=2.0**100

  read(nop,rec=iarec,iostat=ios) var2d

  if( ios .ne. 0 ) then
    print *,'ERROR, iostat = ',INT2(ios)
    stop
  endif
  
  wmin =  spval 
  wmax = -spval 

  do j= 1,jdm
    do i= 1,idm
      if (var2d(i,j).ne.spval) then
        wmin = min( wmin, var2d(i,j) )
        wmax = max( wmax, var2d(i,j) )
      endif
    enddo
  enddo

  ncall = ncall + 1

  if(ncall == 1) then
    print *, '     (idm,jdm):',INT2(SHAPE(var2d))
  endif

  print *, '  var2d(50,50):',SNGL(var2d(50,50))
  print *, '  varmax      :',SNGL(wmax)
  print *, '  varmin      :',SNGL(wmin)

  end subroutine read_direct_sngl_var2d

  subroutine read_direct_dble_var2d(nop,var2d,wmax,wmin,idm,jdm,iarec)
  implicit none

  integer, intent(in) :: nop, idm, jdm, iarec
  real(kind=8), dimension(idm,jdm), intent(out) :: var2d
  real(kind=8), intent(out) :: wmax, wmin

  integer :: ios, i, j
    !
    ! spval  = data void marker, 2^100 or about 1.2676506e30
    !
  real(kind=8), parameter :: spval=2.0**100

  read(nop,rec=iarec,iostat=ios) var2d

  if( ios .ne. 0 ) then
    print *,'ERROR, iostat = ',INT2(ios)
    stop
  endif
  
  wmin =  spval 
  wmax = -spval 

  do j= 1,jdm
    do i= 1,idm
      if (var2d(i,j).ne.spval) then
        wmin = min( wmin, var2d(i,j) )
        wmax = max( wmax, var2d(i,j) )
      endif
    enddo
  enddo

  ncall = ncall + 1

  if(ncall == 1) then
    print *, '     (idm,jdm):',INT2(SHAPE(var2d))
  endif

  print *, '  var2d(50,50):',SNGL(var2d(50,50))
  print *, '  varmax      :',SNGL(wmax)
  print *, '  varmin      :',SNGL(wmin)

  end subroutine read_direct_dble_var2d

  subroutine write_direct_sngl_var2d(nop,var2d,idm,jdm,iarec)
  implicit none

  integer, intent(in) :: nop, idm, jdm, iarec
  real(kind=4), dimension(idm,jdm), intent(in) :: var2d
  real(kind=4) :: wmax, wmin

  integer :: ios, i, j
    !
    ! spval  = data void marker, 2^100 or about 1.2676506e30
    !
  real(kind=4), parameter :: spval=2.0**100

  write(nop,rec=iarec,iostat=ios) var2d

  if( ios .ne. 0 ) then
    print *,'ERROR, iostat = ',INT2(ios)
    stop
  endif
  
  if ( VERBOSE ) then

    wmin =  spval 
    wmax = -spval 

    do j= 1,jdm
      do i= 1,idm
        if (var2d(i,j).ne.spval) then
          wmin = min( wmin, var2d(i,j) )
          wmax = max( wmax, var2d(i,j) )
        endif
      enddo
    enddo

    ncall = ncall + 1

    if(ncall == 1) then
      print *, '     (idm,jdm):',INT2(SHAPE(var2d))
    endif

    print *, '  var2d(50,50):',SNGL(var2d(50,50))
    print *, '  varmax      :',SNGL(wmax)
    print *, '  varmin      :',SNGL(wmin)

  endif

  end subroutine write_direct_sngl_var2d

  subroutine write_direct_dble_var2d(nop,var2d,idm,jdm,iarec)
  implicit none

  integer, intent(in) :: nop, idm, jdm, iarec
  real(kind=8), dimension(idm,jdm), intent(in) :: var2d
  real(kind=8) :: wmax, wmin

  integer :: ios, i, j
    !
    ! spval  = data void marker, 2^100 or about 1.2676506e30
    !
  real(kind=8), parameter :: spval=2.0**100

  write(nop,rec=iarec,iostat=ios) var2d

  if( ios .ne. 0 ) then
    print *,'ERROR, iostat = ',INT2(ios)
    stop
  endif
  
  if ( VERBOSE ) then

    wmin =  spval 
    wmax = -spval 

    do j= 1,jdm
      do i= 1,idm
        if (var2d(i,j).ne.spval) then
          wmin = min( wmin, var2d(i,j) )
          wmax = max( wmax, var2d(i,j) )
        endif
      enddo
    enddo

    ncall = ncall + 1

    if(ncall == 1) then
      print *, '     (idm,jdm):',INT2(SHAPE(var2d))
    endif

    print *, '  var2d(50,50):',SNGL(var2d(50,50))
    print *, '  varmax      :',SNGL(wmax)
    print *, '  varmin      :',SNGL(wmin)

  endif

  end subroutine write_direct_dble_var2d

end module  m_io_direct
