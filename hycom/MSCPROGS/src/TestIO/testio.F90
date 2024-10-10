program testio
    use mod_xc
    use mod_za
    use mod_parameters
    use mod_hycomfile_io
    implicit none
    character(len=80) :: infile,ftype,outfile

    integer :: nop, ios
    integer :: id
    real :: value
    character(len=40) :: name, file

    character(len=80) :: ctitle(4)
    integer :: iversn, iexpt, yrflag,lidm,ljdm,lkdm, dmonth
    integer :: start_iyear
    integer :: start_iday
    integer :: iyear = 0
    integer :: iday  = 0
    integer :: ihour = 0
    integer :: count = 0
    real*8  :: fyear_loc = 0
   
    file='data.txt'

100 format(I4, F8.2, A)
116 format (a80/a80/a80/a80/ &
       i5,4x,'''iversn'' = hycom version number x10'/  &
       i5,4x,'''iexpt '' = experiment number x10'/  &
       i5,4x,'''yrflag'' = days in year flag'/  &
       i5,4x,'''idm   '' = longitudinal array size'/  &
       i5,4x,'''jdm   '' = latitudinal  array size'/  &
       i5,4x,'''kdm   '' = Vertical     array size'/  &
       i5,4x,'''syear '' = Year of integration start '/  &
       i5,4x,'''sday  '' = Day of integration start'/  &
       i5,4x,'''dyear '' = Year of this dump      '/  &
       i5,4x,'''dday  '' = Day of this dump     '/  &
       i5,4x,'''count '' = Ensemble counter       ')
    
    nop=10
    open(nop,file=trim(file),status='old', action='read', iostat=ios)
    if (ios /= 0) then
        print *, 'Error opening file: '//trim(file)
        stop
    else
        print *, 'Open file: '//trim(file)
    endif   

    read(nop, 100, iostat=ios) id, value, name
    print *, 'ID:', id, ' Value:', value, ' Name:', trim(name)
    
    close(nop)

    file='data/001/archm.2016_155_12.b'
    
    nop=777
    open(nop,file=trim(file),status='old', action='read', iostat=ios)
    if (ios /= 0) then
        print *, 'Error opening file: '//trim(file)
        stop
    else
        print *, 'Open file: '//trim(file)
    endif   

    !read(nop,116) ctitle,iversn
    read(nop,116) ctitle,iversn,iexpt,yrflag, &
         lidm,ljdm,lkdm,start_iyear,start_iday ,  &
         iyear,iday,count ,
         ihour=12 ,
         fyear_loc = iyear + min((iday + ihour)/365.,1.)
         
    print *, ctitle(1)
    print *, ctitle(2)
    print *, ctitle(3)
    print *, ctitle(4)
    print *, 'iversn: ',iversn
    
    close(nop)

end program testio
  
