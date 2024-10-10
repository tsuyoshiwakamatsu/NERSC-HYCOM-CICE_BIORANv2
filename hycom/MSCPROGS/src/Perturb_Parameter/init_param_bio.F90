program main
   !
   ! Usage: ./init_param_bio $nens $perr $styp
   !
   ! Note: mem000 : default value
   !       mem001-: perturbed values
   !
   ! History:
   !  [2019.04] Now access command line arguments with native Fortran procedure (F2003 and later) !TW
   !  [2020.06] 1. list of variables under type gen_params is expanded
   !            2. selection of TYPE [ORIG/OPTIM] is removed
   !            3. Di and PARLIST are nonlonger read

   implicit none 
   
   type gen_params 
        character(len=30) :: pnam
        real              :: pval, pmin, pmax
   end type gen_params

   integer(kind=4), parameter :: npar= 17
   type(gen_params)           :: bio(npar)

   integer(kind=4)   :: narg       ! number of command line arguments
   integer(kind=4)   :: nens, perr
   character(len=10) :: styp

   integer(kind=4)    :: ip,ie
   real               :: pstd
   real               :: rng(1)
   real, allocatable  :: prm(:,:)
   character(len=255) :: filename
   character(len=10)  :: tmpchar,tmp1,tmp2,tmp3,tmp4
   character(len=20)  :: str_num, str_par

   !--- define parameter set

   bio( 1)%pnam = "muPl"       ; bio( 1)%pmin = 0.82 ; bio( 1)%pmax = 1.53 ! growth rate for Pl            [1/day]
   bio( 2)%pnam = "muPs"       ; bio( 2)%pmin = 0.74 ; bio( 2)%pmax = 1.38 ! growth rate for Ps            [1/day]
   bio( 3)%pnam = "muCocco"    ; bio( 3)%pmin = 0.8  ; bio( 3)%pmax = 1.49 ! growth rate for Cocco         [1/day]
   bio( 4)%pnam = "GrZlP"      ; bio( 4)%pmin = 0.7  ; bio( 4)%pmax = 1.3  ! Grazing rate of Zl on Phyto   [1/day]
   bio( 5)%pnam = "GrZsP"      ; bio( 5)%pmin = 0.7  ; bio( 5)%pmax = 1.3  ! Grazing rate of Zs on Phyto   [1/day]
   bio( 6)%pnam = "GrZlCocco"  ; bio( 6)%pmin = 0.7  ; bio( 6)%pmax = 1.3  ! Grazing rate of Zl on Cocco   [1/day]
   bio( 7)%pnam = "GrZsCocco"  ; bio( 7)%pmin = 0.7  ; bio( 7)%pmax = 1.3  ! Grazing rate of Zs on Cocco   [1/day]
   bio( 8)%pnam = "alfaPl"     ; bio( 8)%pmin = 0.04 ; bio( 8)%pmax = 0.07 ! Pl initial slope P-I curve    [mmol N m2/(mg Chl day W)]
   bio( 9)%pnam = "alfaPs"     ; bio( 9)%pmin = 0.03 ; bio( 9)%pmax = 0.05 ! Ps initial slope P-I curve    [mmol N m2/(mg Chl day W)]
   bio(10)%pnam = "alphaCocco" ; bio(10)%pmin = 0.02 ; bio(10)%pmax = 0.04 ! Cocco initial slope P-I curve [mmol N m2/(mg Chl day W)]
   bio(11)%pnam = "mZl"        ; bio(11)%pmin = 0.07 ; bio(11)%pmax = 0.13 ! Zl mortality rate             [1/day]
   bio(12)%pnam = "mZs"        ; bio(12)%pmin = 0.08 ; bio(12)%pmax = 0.14 ! Zs mortality rate             [1/day]
   bio(13)%pnam = "sinkOPAL"   ; bio(13)%pmin = 3.5  ; bio(13)%pmax = 6.5  ! OPAL sinking rate             [m/day]
   bio(14)%pnam = "sinkDiaD"   ; bio(14)%pmin = 2.53 ; bio(14)%pmax = 4.7  ! Detritus originating from Diatom sinking rate     [m/day]
   bio(15)%pnam = "sinkFlaD"   ; bio(15)%pmin = 0.57 ; bio(15)%pmax = 1.05 ! Detritus originating from Flagellates sinking rat [m/day]
   bio(16)%pnam = "sinkCoccoD" ; bio(16)%pmin = 5.27 ; bio(16)%pmax = 9.79 ! Detritus originating from Cocco sinking rate      [m/day]
   bio(17)%pnam = "sinkMicD"   ; bio(17)%pmin = 1.56 ; bio(17)%pmax = 2.89 ! Detritus originating from microzoo sinking rate   [m/day]

   !--- set default parameter values

   bio( 1)%pval = 1.177 ! muPl
   bio( 2)%pval = 1.059 ! muPs
   bio( 3)%pval = 1.145 ! muCocco
   bio( 4)%pval = 1.000 ! GrZlP
   bio( 5)%pval = 1.000 ! GrZsP
   bio( 6)%pval = 1.000 ! GrZlCocco
   bio( 7)%pval = 1.000 ! GrZsCocco
   bio( 8)%pval = 0.053 ! alfaPl
   bio( 9)%pval = 0.036 ! alfaPs
   bio(10)%pval = 0.027 ! alphaCocco
   bio(11)%pval = 0.099 ! mZl
   bio(12)%pval = 0.11  ! mZs
   bio(13)%pval = 5.000 ! sinkOPAL
   bio(14)%pval = 3.618 ! sinkDiaD
   bio(15)%pval = 0.808 ! sinkFlaD
   bio(16)%pval = 7.529 ! sinkCoccoD
   bio(17)%pval = 2.224 ! sinkMicD

   !--- read the command line arguments

   narg = command_argument_count()  ! number of the command line arguments

   if ( narg.lt.3 ) then 
      write ( *,'(a)' ) "Usage: Ensemble size, Error size [%], Sampling method [NORM/LOGN]"
      print *,"Error: reading environment variables"
      stop 
   endif

   call get_command_argument(1,tmpchar) ; read(tmpchar,'(i3)') nens
   call get_command_argument(2,tmpchar) ; read(tmpchar,'(i3)') perr
   call get_command_argument(3,styp) 

   write ( *,'(a,i3)' ) "Ensemble size                 : ", nens
   write ( *,'(a,i3)' ) "Initial parameter variance [%]: ", perr
   write ( *,'(a,a4)' ) "Sampling method [NORM or LOGN]: ", TRIM(styp)

   write ( *,'(a)' ) "PARAMETERS:"
   do ip = 1,npar
      write ( *,'(x,a)' ) "-"//TRIM(bio(ip)%pnam)
   enddo

   !--- generate sets of perturbed parameters

   allocate( prm(0:nens,npar) )
   
   prm(0,:) = bio(:)%pval

   if (nens == 1) then
      prm(1,:) = bio(:)%pval
   else      
      call set_random_seed ! set a seed for random number generator

      do ie = 1, nens
         do ip = 1,npar
            call random(rng(1),1)
                  
            if ( styp.eq."LOGN" ) then
               print *,"Error: sampling method:"//TRIM(styp)//" not supported yet"
               stop 
               !prm(ie,ip) = bio(ip)%pval*exp(0.01*perr*rng(1))
            elseif ( styp.eq."NORM" ) then 
               pstd = 0.01*perr*bio(ip)%pval
               prm(ie,ip) = max( 0.0, bio(ip)%pval + pstd*rng(1) )
            else
               print *,"Error: sampling method:"//TRIM(styp)//" not supported"
               stop 
            endif
                  
            if (prm(ie,ip).gt.bio(ip)%pmax) then
               prm(ie,ip) = bio(ip)%pmax
            elseif (prm(ie,ip).lt.bio(ip)%pmin) then
               prm(ie,ip) = bio(ip)%pmin
            endif
            !print *, rng(1), bio(ip)%pval, bio(ip)%pmin, bio(ip)%pmax, prm(ie,ip)
         enddo
      enddo
   endif

   do ie = 0,nens
      write( tmp1,'(i0.3)' ) ie
      filename="Parameter_bio_mem"//trim(adjustl(tmp1))//".txt"  

      open( unit=10,file=filename,status='new',form='formatted' )
      do ip = 1,npar
        write(str_par,'(a10)') bio(ip)%pnam
        write(str_num,'(f9.5)') prm(ie,ip)
        write(10,'(a,a1,1x,a)') TRIM(str_par),":",ADJUSTL(str_num)
        !write(10,'(a4,1x,a1,1x,f7.3)') bio(ip)%pnam,"=",prm(ie,ip)
      enddo
      close( unit=10 )
   enddo

   ! store parameter ensemble in column wise

   write(tmp2,'(i3)') npar
   tmp3 = '('//trim(adjustl(tmp2))//'f10.5)'
   
   open( unit=10,file='Parameter_bio_mem_all.txt',status='replace' )
   do ie = 0,nens 
      write( 10,tmp3 ) ( prm(ie,ip), ip = 1,npar )
   enddo
   close( unit=10 )
   
end program main

subroutine set_random_seed 
   implicit none
   integer :: i, n, clock
   integer, dimension(:), allocatable :: seed
          
   call random_seed(size = n)
   allocate(seed(n))
          
   call system_clock(count=clock)
          
   seed = clock + 37 * (/ (i - 1, i = 1, n) /)
   call random_seed(put = seed)
   deallocate(seed)
end subroutine set_random_seed

subroutine random(work1,n)
!
!  Returns a vector of normally distributed (variance=1,mean=0) random value
!  generated with the Box-Muller transformation
!
   implicit none
   integer, intent(in)  :: n
   real,    intent(out) :: work1(n)
   real,    allocatable :: work2(:)
   real,    parameter   :: pi=3.141592653589

   allocate (work2(n))

   call random_number(work1)
   call random_number(work2)
   work1= sqrt(-2.0*log(work1))*cos(2.0*pi*work2)

   deallocate(work2)
end subroutine random
