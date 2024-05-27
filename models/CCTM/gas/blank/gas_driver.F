
!------------------------------------------------------------------------!
!  The Community Multiscale Air Quality (CMAQ) system software is in     !
!  continuous development by various groups and is based on information  !
!  from these groups: Federal Government employees, contractors working  !
!  within a United States Government contract, and non-Federal sources   !
!  including research institutions.  These groups give the Government    !
!  permission to use, prepare derivative works of, and distribute copies !
!  of their work in the CMAQ system to the public and to permit others   !
!  to do so.  The United States Environmental Protection Agency          !
!  therefore grants similar permission to use the CMAQ system software,  !
!  but users are requested to provide copies of derivative works or      !
!  products designed to operate in the CMAQ system to the United States  !
!  Government without restrictions as to use by others.  Software        !
!  that is used with the CMAQ system but distributed under the GNU       !
!  General Public License or the GNU Lesser General Public License is    !
!  subject to their copyright restrictions.                              !
!------------------------------------------------------------------------!

C RCS file, release, date & time of last delta, author, state, [and locker]
C $Header: /project/yoj/arc/CCTM/src/gas/ros3/rbdriver.F,v 1.7 2011/10/21 16:11:10 yoj Exp $

C what(1) key, module and SID; SCCS file; date and time of last delta:
C %W% %P% %G% %U%


       SUBROUTINE CHEM( CONC, JDATE, JTIME, TSTEP )

C**********************************************************************
C
C  Function: To control gas phase chemistry calculations performed by
C            the vectorized Rosenbrock solver
C
C  Preconditions: None
C
C  Key Subroutines/Functions Called: RBINIT
C                                    RBSPARSE
C                                    PHOT
C                                    CALCKS
C                                    RBSOLVER
C                                    FIND_DEGRADED
C                                    INIT_DEGRADE
C                                    FINAL_DEGRADE
C
C  Revision History: Prototype created by Jerry Gipson, August, 2004
C                    Based on the solver described by Sandu et al
C                    ( Atm. Env., Vol. 31, No. 20, 1997 ) and included
C                    in the Kinetic PreProcessor ( see for example 
C                    Sandu et al., At, Env., Vol. 37, 5097-5114, 
C                    2003). This code also incorporates efficiency
C                    concepts originally developed by M. Jacobson
C                    for SMVGEAR (Atm. Env., Vol 28, No 2, 1994).
C                    Adapted from Subroutine CHEM in CMAQ SMVGEAR
C
C                    31 Jan 05 J.Young: dyn alloc - establish both horizontal
C                    & vertical domain specifications in one module (GRID_CONF)
C                    29 Jul 05     WTH: Added IF blocks that call degrade 
C                                       routines if MECHNAME contains 'TX' 
C                                       substring.
C                    28 Jun 10 J.Young: convert for Namelist redesign
C                    29 Mar 11 S.Roselle: Replaced I/O API include files
C                               with UTILIO_DEFN
C                    31 Aug 11 B.Hutzell revised method that determines calling
C                              degrade routine
C                    29 Sep 11 D.Wong: incorporated twoway model implementation
C**********************************************************************

      USE SUBST_MODULES
      USE GRID_CONF             ! horizontal & vertical domain specifications
C     USE RBDATA                ! ROS3 solver data
      USE CGRID_SPCS            ! CGRID mechanism species
      USE UTILIO_DEFN

      IMPLICIT NONE 

C..Includes:

      INCLUDE SUBST_FILES_ID    ! CMAQ files
      INCLUDE SUBST_CONST       ! CMAQ constants
      INCLUDE SUBST_RXCMMN      ! Mechanism reaction common block
      INCLUDE SUBST_PACTL_ID    ! Process analysis control parameters
 
C..Arguments:

      REAL, POINTER :: CONC( :,:,:,: )  ! Concentrations

      INTEGER JDATE                     ! Current date (YYYYDDD)
      INTEGER JTIME                     ! Current time (HHMMSS)
      INTEGER TSTEP( 3 )                ! Time step vector (HHMMSS)

C..Parameters:

      INTEGER, PARAMETER :: IZERO = 0                ! Integer zero

      REAL,    PARAMETER :: CONCMIN = 1.0E-30        ! Minimum conc
      REAL,    PARAMETER :: CONCOFM = 1.0E+06        ! conc. of M = 1E+06 ppm
      REAL,    PARAMETER :: PA2ATM  = 1.0 / STDATMPA ! Pascal to atm conv fac

C..External Functions:

C..Local Variables:

      LOGICAL, SAVE :: LFIRST = .TRUE. ! Flag for first call to this subroutine
      LOGICAL, SAVE :: LIRRBLK         ! Flag for IRR to be done for block

      INTEGER, SAVE :: LOGDEV          ! Unit number of output log
      INTEGER, SAVE :: NOXYZ           ! Total number of grid cells

      REAL,    SAVE :: AIRFC           ! Factor to convert gms air to ppm
      REAL,    SAVE :: MAOMV           ! Mol Wt of air over Mol Wt of water
!     REAL,    SAVE :: CONV( NLAYS )   ! Volumetric emis conv facs

      CHARACTER(  16 ) :: PNAME = 'RBDRIVER' ! Procedure name
      CHARACTER(  16 ) :: VNAME              ! Name of I/O API data variable
      CHARACTER( 144 ) :: MSG                ! Message text
     
      INTEGER C, R, L, S      ! Loop indices
      INTEGER ALLOCSTAT       ! Allocate status code
      INTEGER OFFSET          ! Starting cell number of a block
      INTEGER NCSP            ! Mech no: 1=gas/day 2=gas/night
      INTEGER BLK             ! Loop index for block of cells
      INTEGER CELLNUM         ! Cell number 
      INTEGER COL             ! Column index
      INTEGER IPAR            ! Pointer for cell sort routine
      INTEGER IRVAL           ! Pointer for cell sort routine
      INTEGER IRXN            ! Reaction number
      INTEGER ISP             ! Species index
      INTEGER ISPOLD          ! Species number in original order
      INTEGER ISPNEW          ! Species number in new sorted order 
      INTEGER ITMSTEP         ! Chemistry integration interval (sec)   
      INTEGER JPAR            ! Pointer for cell sort routine
      INTEGER JREORD          ! Index holder for sort routine
      INTEGER LEV             ! Layer index
      INTEGER LVAL            ! Pointer for cell sort routine
      INTEGER MIDDATE         ! Date at time step midpoint
      INTEGER MIDTIME         ! Time at time step midpoint
      INTEGER NCELL           ! Index for number of cells
      INTEGER NDARK           ! Number of layer 1 cells in darkness
      INTEGER NIRRCLS         ! No. of cells in block for IRR
      INTEGER NPH             ! Index for number of phot. rxns in PHOT
      INTEGER NRX             ! Index for number of reactions
      INTEGER ROW             ! Row index
      INTEGER SPC             ! Species loop index
      INTEGER VAR             ! Variable number on I/O API file

      INTEGER :: IRRCELL( BLKSIZE )   ! Cell No. of an IRR cell

C for INTERPX
      INTEGER     GXOFF, GYOFF                 ! global origin offset from file
      INTEGER, SAVE :: STRTCOLMC3, ENDCOLMC3, STRTROWMC3, ENDROWMC3
      INTEGER, SAVE :: STRTCOLEM1, ENDCOLEM1, STRTROWEM1, ENDROWEM1
 
      REAL CHEMSTEP                            ! Chem integration interval (min)
      REAL VALLOW                              ! Value holder for sort routine
      
      REAL :: DENSA_J( NCOLS,NROWS,NLAYS )      ! Cell density (Kg/m**3)
      REAL :: DENS   ( NCOLS,NROWS,NLAYS )      ! Cell density (Kg/m**3)
      REAL :: PRES   ( NCOLS,NROWS,NLAYS )      ! Cell pressure (Pa)
      REAL :: QV     ( NCOLS,NROWS,NLAYS )      ! Cell water vapor (Kg/Kg air)
      REAL :: TA     ( NCOLS,NROWS,NLAYS )      ! Cell temperature (K)

!     REAL :: RJBLK( BLKSIZE,NPHOTAB )           ! J-values for each cell in 
                                               ! a block

      REAL :: RJ( NCOLS,NROWS,NLAYS,NPHOTAB )  ! J-values for each cell      
!     REAL, ALLOCATABLE, SAVE :: RJ( :,:,:,: )  ! J-values for each cell      

#ifdef rbstats

      CHARACTER( 16 ), SAVE              :: CTM_RBSTATS_1 = 'CTM_RBSTATS_1' 
      CHARACTER( 16 ), ALLOCATABLE, SAVE :: VSTATS( : )        !

      INTEGER, SAVE                      :: WSTEP = 0     
      INTEGER, ALLOCATABLE, SAVE         :: STAT_SUM( :,:,:,: )
      INTEGER  EDATE, ETIME

      REAL                               :: STATOUT( NCOLS,NROWS,NLAYS )

#endif

C**********************************************************************

      IF ( N_GC_SPC .EQ. 0 ) THEN
         CALL M3MESG( '*** WARNING: Gas-Chemistry processing bypassed!' )
         RETURN
      END IF

ccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccc
c  On first call, do nothing in particular...
ccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccc
      IF ( LFIRST ) THEN
         LFIRST = .FALSE.
         LOGDEV = INIT3( )

      END IF      ! First call

      END

