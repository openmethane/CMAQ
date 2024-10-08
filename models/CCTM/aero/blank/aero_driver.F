
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
C $Header: /project/yoj/arc/CCTM/src/aero/aero5/aero_driver.F,v 1.11 2012/01/19 13:12:57 yoj Exp $

C what(1) key, module and SID; SCCS file; date and time of last delta:
C %W% %P% %G% %U%

C >>> 08/04/2000 Changes necessary to be able to read and process
C two different types of emissions files.
C the first type is the existing opperational PM2.5 & PM10 unspeciated
C file. The new file format has speciated emissions.
C >>> This version uses the FORTRAN 90 feature for runtime memory
C allocation.

C 1/12/99 David Wong at LM:
C   -- introduce new variable MY_NUMBLKS (eliminate NUMBLKS)
C   -- re-calculate NOXYZ accordingly
C FSB Updated for inclusion of surface area / second moment
C 25 Sep 00 (yoj) various bug fixes, cleanup to coding standards
C   Jeff - Dec 00 - move CGRID_MAP into f90 module
C FSB/Jeff - May 01 - optional emissions processing
C   Jerry Gipson - Jun 01 - added SOA linkages for saprc99
C   Bill Hutzell - Jun 01 - simplified CBLK mapping
C   Jerry Gipson - Jun 03 - modified for new soa treatment
C   Jerry Gipson - Aug 03 - removed SOA prod form alkenes & added
C       emission adjustment factors for ALK & TOL ( RADM2 & SAPRC99 only)
C   Shawn Roselle - Jan 04
C   - removed SOA from transported aerosol surface area
C   - fixed bug in calculation of wet parameters.  Previously, DRY aerosol
C      parameters were being written to the AERDIAG files and mislabeled
C      as WET.
C   Prakash Bhave - May 04
C   - changed AERODIAG species (added RH; removed M0 & M2dry)
C   Jeff Young - Jan 05 - dyn alloc
C   - establish both horizontal & vertical domain specifications in one module
c   Uma Shankar and Prakash Bhave - Jun 05
c   - added code to handle the following species: ANAI, ANAJ, ANAK, ACLI,
c     ACLJ, ACLK, ASO4K, AH2OK, ANO3K, and HCL; removed code for ASEAS
c   - removed obsolete MW variables
C   Prakash Bhave - Jul 05 - added PM25 mass-fraction calculations
C   Jeff Young - Feb 06 - trap fractional humidity above 0.005
C   Prakash Bhave - Apr 06 - added GAMMA_N2O5 to the AEROPROC call vector
C       and the aerosol diagnostic file
C   Prakash Bhave - May 06 - changed units of DG variables from m to um in
C       the aerosol diagnostic file as suggested by Dr. Bill Hutzell
C   Sergey Napelenok - Sep 07 - SOA updates
C   - added code to handle the following species: AALKJ, ATOL1J, ATOL2J,
C     ATOL3J, AXYL1J, AXYL2J, AXYL3J, ABNZ1J, ABNZ2J, ABNZ3J, AISO1J, AISO2J,
C     AISO3J, ATRP1J, ATRP2J, ASQTJ, AORGCJ, TOLNRXN, TOLHRXN, XYLNRXN,
C     XYLHRXN, BNZNRXN, BNZHRXN, ISOPRXN, and SESQRXN
C   - removed following species: AORGAI, AORGAJ, AORGBI, AORGBJ, OLIRXN,
C     CSLRXN, TOLRXN, XYLRXN
C   Prakash Bhave - Oct 07 - SOA updates
C   - added semi-volatile vapors to the CBLK array; moved ppm -> ug/m3 unit
C     conversion from the ORGAER subroutine to this program
C   - updated definition of DRY aerosol to include nonvolatile SOA species
C   - removed adjustment factors for TOLAER (SPTOL, RDTOL) because benzene is
C     now an explicit species so all of the reacted TOL can produce SOA
C   - removed code to handle TERPSP (obsolete); renamed TERPRXN as TRPRXN
C   David Wong - Jan 08 - rearranged calculation of dry 3rd moments to avoid
C      NaN on some compilers (using the M3SUBT variable)
C   Prakash Bhave - Jan 08 - updated MECHNAME check from AE4 to AE5
C   Golam Sarwar -  Mar 08 - added a heterogeneous reaction producing HONO
C   Jim Kelly - Apr 08 - coarse mode updates
C   - added code to account for new species (ANH4K & SRFCOR) and variable
C     coarse std. deviation
C   - removed MW coding now located in AERO_INFO.f
C   - added LIMIT_Sg flag for call to GETPAR
C   Jeff Young - Aug 10 - convert for Namelist redesign (replace include files)
C   Steve Howard - Mar 11 - Renamed met_data to aeromet_data
C   S.Roselle- Mar 11 - replaced I/O API include files with UTILIO_DEFN
C   David Wong - Aug 11 - put in twoway model implementation
C   David Wong - Oct 11 - extended the twoway implementation to handle finer
C                         time resolution
C:::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::
      SUBROUTINE AERO ( CGRID, JDATE, JTIME, TSTEP )

      USE GRID_CONF           ! horizontal & vertical domain specifications

      USE AERO_DATA           ! aero variable data
      USE PRECURSOR_DATA      ! gas phase aero precursor data
      USE SOA_DEFN            ! gas soa data
      USE AEROMET_DATA        ! air properties data, eg., T, P, RH includes CONST.EXT
      USE UTILIO_DEFN
      USE CGRID_SPCS

      IMPLICIT NONE

C *** Includes:

      INCLUDE SUBST_RXCMMN    ! to get mech name
      INCLUDE SUBST_FILES_ID  ! file name parameters (req IOPARMS)
      INCLUDE SUBST_PACTL_ID  ! process analysis

C *** Arguments:

C *** CGRID is conc field (including gas and aerosol variables)
      REAL, POINTER :: CGRID( :,:,:,: )              !  concentrations
      INTEGER      JDATE        ! Current model date , coded YYYYDDD
      INTEGER      JTIME        ! Current model time , coded HHMMSS
      INTEGER      TSTEP( 3 )   ! time step vector (HHMMSS)
                                ! TSTEP(1) = local output step
                                ! TSTEP(2) = sciproc sync. step (chem)
                                ! TSTEP(3) = twoway model time step w.r.t. wrf time
                                !            step and wrf/cmaq call frequency

      INTEGER, SAVE :: LOGDEV             ! unit number for the log file

C *** Local Variables:

      CHARACTER( 16 ), SAVE :: PNAME = 'AERO_DRIVER'
      CHARACTER( 16 ) :: VNAME            ! variable name
      CHARACTER( 96 ) :: XMSG = ' '

      INTEGER   MDATE, MTIME, MSTEP  ! julian date, time and
                                     ! timestep in sec
      INTEGER   C, R, L, V, N        ! loop counters
      INTEGER   SPC                  ! species loop counter
      INTEGER   STRT, FINI           ! loop induction variables
      INTEGER   ALLOCSTAT            ! memory allocation status

      LOGICAL   LERROR               ! Error flag

C *** Grid Description
      REAL DX1                 ! Cell x-dimension
      REAL DX2                 ! Cell y-dimension
      INTEGER GXOFF, GYOFF     ! global origin offset from file
C for INTERPX
      INTEGER, SAVE :: STRTCOLMC3, ENDCOLMC3, STRTROWMC3, ENDROWMC3

C *** Variable to set time step for writing visibility file
      INTEGER, SAVE :: WSTEP  = 0   ! local write counter
      LOGICAL, SAVE :: WRITETIME = .FALSE. ! local write flag

C *** meteorological variables
      REAL PRES   ( NCOLS,NROWS,NLAYS )  ! Atmospheric pressure [ Pa ]
      REAL TA     ( NCOLS,NROWS,NLAYS )  ! Air temperature [ K ]
      REAL DENS   ( NCOLS,NROWS,NLAYS )  ! Air density [ kg/m**-3 ]
      REAL QV     ( NCOLS,NROWS,NLAYS )  ! Water vapor mixing ratio [ kg/kg ]

C *** variables computed and output but not carried in CGRID

C *** visibility variables
      INTEGER, PARAMETER :: N_AE_VIS_SPC = 4
      INTEGER, PARAMETER :: IDCVW1 = 1 ! visual range in deciview (Mie)
      INTEGER, PARAMETER :: IBEXT1 = 2 ! extinction [ 1/km ] (Mie)
      INTEGER, PARAMETER :: IDCVW2 = 3 ! visual range in deciview (Reconst)
      INTEGER, PARAMETER :: IBEXT2 = 4 ! extinction [ 1/km ] (Reconst)
      REAL VIS_SPC( NCOLS,NROWS,N_AE_VIS_SPC ) ! Visual range information

C *** aerosol size distribution variables
      REAL DIAM_SPC( NCOLS,NROWS,NLAYS,23 )

C *** atmospheric properties
      REAL XLM             ! atmospheric mean free path [ m ]
      REAL AMU             ! atmospheric dynamic viscosity [ kg/m s ]

C *** N2O5 heterogeneous reaction probability [ ]
      REAL GAMMA_N2O5      ! computed in SUBROUTINE EQL3

C *** mass fraction of each mode less than 2.5um aerodynamic diameter
      REAL PM25( N_MODE )  ! fine fractions

C *** visual range information
      REAL BLKDCV1         ! block deciview (Mie)
      REAL BLKEXT1         ! block extinction [ km**-1 ] (Mie)

      REAL BLKDCV2         ! block deciview (Reconstructed)
      REAL BLKEXT2         ! block extinction [ km**-1 ] (Reconstructed)

C *** other internal aerosol variables
      INTEGER IND                         ! index to be used with INDEX1

C *** synchronization time step [ s ]
      REAL DT

C *** variables to set up for "dry transport "
      REAL M3_WET, M3_DRY   ! third moment with and without water
      REAL M2_WET, M2_DRY   ! second moment with and without water
      REAL M3SUBT           ! temp variable for dry 3rd moment calcs

C *** flag to include water in the 3rd moment calculation
      LOGICAL, PARAMETER :: M3_WET_FLAG = .FALSE.

C *** if LIMIT_Sg = T, atkn & accum std. dev. are not changed by GETPAR
      LOGICAL, PARAMETER :: LIMIT_Sg = .FALSE.

C *** variables aerosol diagnostic file flag
      INTEGER      STATUS            ! ENV... status
      CHARACTER( 80 ) :: VARDESC     ! environment variable description

C *** environment variable for AERDIAG file
      CHARACTER( 16 ), SAVE :: CTM_AERDIAG = 'CTM_AERDIAG'

C *** flag for AERDIAG file [F], default
      LOGICAL, SAVE :: AERDIAG

C *** first pass flag
      LOGICAL, SAVE :: FIRSTIME = .TRUE.

C *** ratio of molecular weights of water vapor to dry air = 0.622015
      REAL, PARAMETER :: EPSWATER = MWWAT / MWAIR

C *** dry moment factor
      REAL, PARAMETER :: TWOTHIRDS = 2.0 / 3.0

      LOGICAL :: TIME_TO_CALL_FEEDBACK_WRITE
      LOGICAL, SAVE :: CMAQ_WRF_FEEDBACK

C *** Statement Function **************
      REAL ESATL ! arithmetic statement function for vapor pressure [Pa]
      REAL TT
C *** Coefficients for the equation, ESATL defining saturation vapor pressure
      REAL, PARAMETER :: AL = 610.94
      REAL, PARAMETER :: BL = 17.625
      REAL, PARAMETER :: CL = 243.04

      INTEGER, SAVE :: O3

C *** values of AL, BL, and CL are from:
C     Alduchov and Eskridge, "Improved Magnus Form Approximations of
C                            Saturation Vapor Pressure,"
C                            Jour. of Applied Meteorology, vol. 35,
C                            pp 601-609, April, 1996.

      ESATL( TT ) = AL * EXP( BL * ( TT - 273.15 ) / ( TT - 273.15 + CL ) )

C *** End Statement Function  ********

      logical, save :: now = .true.

#ifdef twoway
      INTERFACE
        SUBROUTINE FEEDBACK_WRITE (C, R, L, CGRID_DATA, O3_VALUE, JDATE, JTIME)
          REAL, INTENT(IN) :: CGRID_DATA(:), O3_VALUE
          INTEGER, INTENT(IN) :: C, R, L, JDATE, JTIME
        END SUBROUTINE FEEDBACK_WRITE
      END INTERFACE
#endif

C ------------------ begin body of AERO_DRIVER -------------------------

      IF ( FIRSTIME ) THEN
         FIRSTIME = .FALSE.
         LOGDEV = INIT3()

#ifdef twoway
! -- this is for twoway
         VNAME = 'O3'
         N = INDEX1( VNAME, N_GC_CONC, GC_CONC )
         IF ( N .NE. 0 ) THEN
            O3 = GC_STRT - 1 + GC_CONC_MAP( N )
         ELSE
            XMSG = 'Could not find ' // VNAME // 'in gas chem aerosol table'
            CALL M3EXIT ( PNAME, JDATE, JTIME, XMSG, XSTAT3 )
         END IF
#endif

C *** Get aerosol diagnostic file flag.
         AERDIAG = .FALSE.         ! default
         VARDESC = 'Flag for writing the aerosol diagnostic file'
         AERDIAG = ENVYN( CTM_AERDIAG, VARDESC, AERDIAG, STATUS )
         IF ( STATUS .NE. 0 ) WRITE( LOGDEV, '(5X, A)' ) VARDESC
         IF ( STATUS .EQ. 1 ) THEN
            XMSG = 'Environment variable improperly formatted'
            CALL M3EXIT( PNAME, JDATE, JTIME, XMSG, XSTAT2 )
         ELSE IF ( STATUS .EQ. -1 ) THEN
            XMSG = 'Environment variable set, but empty ... Using default:'
            WRITE( LOGDEV, '(5X, A, I9)' ) XMSG, JTIME
         ELSE IF ( STATUS .EQ. -2 ) THEN
            XMSG = 'Environment variable not set ... Using default:'
            WRITE( LOGDEV, '(5X, A, I9)' ) XMSG, JTIME
         END IF

C *** Open the met files.
         IF ( .NOT. OPEN3( MET_CRO_3D, FSREAD3, PNAME ) ) THEN
            XMSG = 'Could not open  MET_CRO_3D  file '
            CALL M3EXIT ( PNAME, JDATE, JTIME, XMSG, XSTAT1 )
         END IF

         IF ( .NOT. OPEN3( MET_CRO_2D, FSREAD3, PNAME ) ) THEN
            XMSG = 'Could not open  MET_CRO_2D file '
            CALL M3EXIT ( PNAME, JDATE, JTIME, XMSG, XSTAT1 )
         END IF

C *** Set up file structure for visibility file. It has two variables,
C     visual range in deciview units (dimensionless) and extinction in
C     units of (1/km) and is for layer 1 only.
         IF ( MYPE .EQ. 0 ) CALL OPVIS ( JDATE, JTIME, TSTEP( 1 ) )

C *** Open the aerosol parameters file (diameters and standard deviations).
         IF ( AERDIAG .AND. MYPE .EQ. 0 )
     &      CALL OPDIAM ( JDATE, JTIME, TSTEP( 1 ) )

C *** Get domain decomp info from the MET_CRO_3D file
         CALL SUBHFILE ( MET_CRO_3D, GXOFF, GYOFF,
     &                   STRTCOLMC3, ENDCOLMC3, STRTROWMC3, ENDROWMC3 )

#ifdef twoway
         CMAQ_WRF_FEEDBACK = ENVYN( 'CMAQ_WRF_FEEDBACK', ' ', .FALSE., STATUS )
         IF ( STATUS .EQ. 1 ) THEN
            PRINT *, 'Environment variable improperly formatted'
            STOP
         ELSE IF ( STATUS .EQ. -1 ) THEN
            PRINT *, 'Environment variable set, but empty ... Using default:'
         ELSE IF ( STATUS .EQ. -2 ) THEN
            PRINT *, 'Environment variable not set ... Using default:'
         END IF
#endif

      END IF    ! FIRSTIME

      MDATE  = JDATE
      MTIME  = JTIME
      MSTEP = TIME2SEC( TSTEP( 2 ) )
      CALL NEXTIME ( MDATE, MTIME, SEC2TIME( MSTEP / 2 ) )

      WSTEP = WSTEP + TIME2SEC( TSTEP( 2 ) )
      IF ( WSTEP .GE. TIME2SEC( TSTEP( 1 ) ) ) WRITETIME = .TRUE.

C *** Set floating point synchronization time step:
      DT = FLOAT( MSTEP ) ! set time step in seconds

C *** Get Meteorological Variables

C *** pressure [Pa]
      VNAME = 'PRES'
      IF ( .NOT. INTERPX( MET_CRO_3D, VNAME, PNAME,
     &                    STRTCOLMC3,ENDCOLMC3, STRTROWMC3,ENDROWMC3, 1,NLAYS,
     &                    MDATE, MTIME, PRES ) ) THEN
         XMSG = 'Could not interpolate '// TRIM( VNAME ) // ' from MET_CRO_3D '
         CALL M3EXIT ( PNAME, MDATE, MTIME, XMSG, XSTAT1 )
      END IF

C *** temperature [K]
      VNAME = 'TA'
      IF ( .NOT. INTERPX( MET_CRO_3D, VNAME, PNAME,
     &                    STRTCOLMC3,ENDCOLMC3, STRTROWMC3,ENDROWMC3, 1,NLAYS,
     &                    MDATE, MTIME, TA ) ) THEN
         XMSG = 'Could not interpolate '// TRIM( VNAME ) // ' from MET_CRO_3D '
         CALL M3EXIT ( PNAME, MDATE, MTIME, XMSG, XSTAT1 )
      END IF

C *** specific humidity [g H2O/g air]
      VNAME = 'QV'
      IF ( .NOT. INTERPX( MET_CRO_3D, VNAME, PNAME,
     &                    STRTCOLMC3,ENDCOLMC3, STRTROWMC3,ENDROWMC3, 1,NLAYS,
     &                    MDATE, MTIME, QV ) ) THEN
         XMSG = 'Could not interpolate '// TRIM( VNAME ) // ' from MET_CRO_3D '
         CALL M3EXIT ( PNAME, JDATE, JTIME, XMSG, XSTAT1 )
      END IF

C *** air density [kg/m3]
      VNAME = 'DENS'
      IF ( .NOT. INTERPX( MET_CRO_3D, VNAME, PNAME,
     &                    STRTCOLMC3,ENDCOLMC3, STRTROWMC3,ENDROWMC3, 1,NLAYS,
     &                    MDATE, MTIME, DENS ) ) THEN
         XMSG = 'Could not interpolate '// TRIM( VNAME ) // ' from MET_CRO_3D '
         CALL M3EXIT ( PNAME, MDATE, MTIME, XMSG, XSTAT1 )
      END IF

#ifdef twoway
! call FEEDBACK_WRITE when JTIME is mulitple of WRF time step
      IF ( CMAQ_WRF_FEEDBACK ) THEN
         IF ( MOD( TIME2SEC(MOD( JTIME, 10000 )), TIME2SEC(TSTEP( 3 )) ) .EQ. 0 ) THEN
            TIME_TO_CALL_FEEDBACK_WRITE = .TRUE.
         ELSE
            TIME_TO_CALL_FEEDBACK_WRITE = .FALSE.
         END IF
      END IF
#endif

c$$$C --------------------- Begin loops over grid cells --------------------------
c$$$
c$$$C *** initialize conc arrays
c$$$
c$$$      DO L = 1, NLAYS
c$$$         DO R = 1, MY_NROWS
c$$$            DO C = 1, MY_NCOLS
c$$$
c$$$C *** Grid cell meteorological data.
c$$$               AIRTEMP  = TA   ( C,R,L )
c$$$               AIRPRES  = PRES ( C,R,L )   ! Note pascals
c$$$               AIRQV    = QV   ( C,R,L )
c$$$               AIRDENS  = DENS ( C,R,L )
c$$$               H2OSATVP = ESATL( AIRTEMP )
c$$$               H2OVP    = AIRPRES * AIRQV / ( EPSWATER  + AIRQV )
c$$$               AIRRH    = MAX( 0.005, MIN( 0.99, H2OVP / H2OSATVP ) )
c$$$
c$$$C *** Extract grid cell concentrations of aero species from CGRID
c$$$C     into aerospc_conc in aero_data module (set minimum)
c$$$               CALL EXTRACT_AERO( CGRID( C,R,L,: ), .TRUE. )
c$$$
c$$$C *** Extract grid cell concentrations of gas precursors from CGRID (ppm)
c$$$C     into precursr_conc in precursor_data
c$$$               CALL EXTRACT_PRECURSOR( CGRID( C,R,L,: ) )
c$$$
c$$$C *** Calculate SO4RATE stored in module
c$$$               SO4RATE = PRECURSOR_CONC( SULPRD_IDX ) / DT
c$$$
c$$$C *** Extract soa concentrations from CGRID
c$$$               CALL EXTRACT_SOA( CGRID( C,R,L,: ) )
c$$$
c$$$C *** Aerosol process routines
c$$$               CALL AEROPROC( DT, C, R, L, GAMMA_N2O5 )
c$$$
c$$$C *** Update aerosol variables conc back into CGRID (set minimum)
c$$$               CALL UPDATE_AERO( CGRID( C,R,L,: ), .TRUE. )
c$$$
c$$$C *** Update precursor variables conc back into CGRID
c$$$               CALL UPDATE_PRECURSOR( CGRID( C,R,L,: ) )
c$$$
c$$$C *** Update gas soa concentrations back to CGRID
c$$$               CALL UPDATE_SOA( CGRID( C,R,L,: ) )
c$$$
c$$$C *** Calculate volume fraction of each mode < 2.5um aerodynamic diameter
c$$$               DO N = 1, N_MODE
c$$$                  CALL INLET25 ( AEROMODE_DIAM( N ), AEROMODE_SDEV( N ),
c$$$     &                           AEROMODE_DENS( N ), PM25( N ) )
c$$$               END DO
c$$$
c$$$C *** Write aerosol extinction coefficients and deciviews to visibility
c$$$C     diagnostic array (lowest vertical layer only)
c$$$
c$$$               IF ( WRITETIME .AND. L .EQ. 1 ) THEN
c$$$
c$$$                  CALL GETVISBY( BLKDCV1, BLKEXT1, BLKDCV2, BLKEXT2 )
c$$$
c$$$                  VIS_SPC( C,R,IDCVW1 ) = BLKDCV1  ! Mie visual range [deciview]
c$$$                  VIS_SPC( C,R,IBEXT1 ) = BLKEXT1  ! Mie aero extinction [1/km]
c$$$                  VIS_SPC( C,R,IDCVW2 ) = BLKDCV2  ! Reconstructed visual range [deciview]
c$$$                  VIS_SPC( C,R,IBEXT2 ) = BLKEXT2  ! Reconstructed aero extinction [1/km]
c$$$
c$$$               END IF
c$$$
c$$$C *** Write wet diameters, 2nd, and 3rd moments to aerosol diagnostic array
c$$$C     This assumes that GETPAR was last called with M3_WET_FLAG = .TRUE.
c$$$               IF ( WRITETIME .AND. AERDIAG ) THEN
c$$$                  DIAM_SPC( C,R,L, 7 ) = AEROMODE_DIAM( 1 ) * 1.0E6  ! wet i-mode diam.
c$$$                  DIAM_SPC( C,R,L, 8 ) = AEROMODE_DIAM( 2 ) * 1.0E6  ! wet j-mode diam.
c$$$                  DIAM_SPC( C,R,L, 9 ) = AEROMODE_DIAM( 3 ) * 1.0E6  ! wet k-mode diam.
c$$$                  DIAM_SPC( C,R,L,10 ) = MOMENT2_CONC( 1 )    ! wet i-mode 2nd moment
c$$$                  DIAM_SPC( C,R,L,11 ) = MOMENT2_CONC( 2 )    ! wet j-mode 2nd moment
c$$$                  DIAM_SPC( C,R,L,12 ) = MOMENT2_CONC( 3 )    ! wet k-mode 2nd moment
c$$$                  DIAM_SPC( C,R,L,16 ) = MOMENT3_CONC( 1 )    ! wet i-mode 3rd moment
c$$$                  DIAM_SPC( C,R,L,17 ) = MOMENT3_CONC( 2 )    ! wet j-mode 3rd moment
c$$$                  DIAM_SPC( C,R,L,18 ) = MOMENT3_CONC( 3 )    ! wet k-mode 3rd moment
c$$$                  DIAM_SPC( C,R,L,20 ) = PM25( 1 )            ! i-mode fine fraction
c$$$                  DIAM_SPC( C,R,L,21 ) = PM25( 2 )            ! j-mode fine fraction
c$$$                  DIAM_SPC( C,R,L,22 ) = PM25( 3 )            ! coarse-mode fine fraction
c$$$                  DIAM_SPC( C,R,L,23 ) = GAMMA_N2O5           ! N2O5 heterorxn probability
c$$$               END IF   ! WRITETIME .AND. AERDIAG
c$$$
c$$$C *** Calculate 2nd and 3rd moments of the "dry" aerosol distribution
c$$$C     NOTE! "dry" aerosol excludes both H2O and SOA  (Jan 2004 --SJR)
c$$$C     EXCEPT!  nonvolatile SOA is part of dry aerosol (Oct 2007 --PVB)
c$$$
c$$$C     Aitken mode
c$$$               M3_WET = MOMENT3_CONC( 1 )
c$$$               M3SUBT = ( 1.0E-9 * F6PI / AEROSPC( AH2O_IDX )%DENSITY )
c$$$     &                * AEROSPC_CONC( AH2O_IDX,1 )
c$$$               M3_DRY = M3_WET - M3SUBT
c$$$               M2_WET = MOMENT2_CONC( 1 )
c$$$               M2_DRY = M2_WET * ( M3_DRY / M3_WET ) ** TWOTHIRDS
c$$$
c$$$               MOMENT3_CONC( 1 ) = MAX( CONMIN, M3_DRY )
c$$$               MOMENT2_CONC( 1 ) = MAX( CONMIN, M2_DRY )
c$$$
c$$$C     accumulation mode
c$$$               M3_WET = MOMENT3_CONC( 2 )
c$$$
c$$$               M3SUBT = ( 1.0E-9 * F6PI / AEROSPC( AH2O_IDX )%DENSITY )
c$$$     &                * AEROSPC_CONC( AH2O_IDX,2 )
c$$$               DO SPC = 1, N_VAPOR
c$$$                  M3SUBT = M3SUBT
c$$$     &                   + ( 1.0E-9 * F6PI / AEROSPC( APOC_IDX )%DENSITY )
c$$$     &                   * AEROSPC_CONC( SOA_AEROMAP( SPC ),2 )
c$$$               END DO
c$$$
c$$$               M3_DRY = M3_WET - M3SUBT
c$$$               M2_WET = MOMENT2_CONC( 2 )
c$$$               M2_DRY = M2_WET * ( M3_DRY / M3_WET ) ** TWOTHIRDS
c$$$
c$$$               MOMENT3_CONC( 2 ) = MAX( CONMIN, M3_DRY )
c$$$               MOMENT2_CONC( 2 ) = MAX( CONMIN, M2_DRY )
c$$$
c$$$C     coarse mode
c$$$               M3_WET = MOMENT3_CONC(3)
c$$$               M3SUBT = ( 1.0E-9 * F6PI / AEROSPC( AH2O_IDX )%DENSITY )
c$$$     &                * AEROSPC_CONC( AH2O_IDX,3 )
c$$$               M3_DRY = M3_WET - M3SUBT
c$$$               M2_WET = MOMENT2_CONC( 3 )
c$$$               M2_DRY = M2_WET * ( M3_DRY / M3_WET ) ** TWOTHIRDS
c$$$
c$$$               MOMENT3_CONC( 3 ) = MAX( CONMIN, M3_DRY )
c$$$               MOMENT2_CONC( 3 ) = MAX( CONMIN, M2_DRY )
c$$$
c$$$C *** Calculate geometric mean diameters and standard deviations of the
c$$$C     "dry" size distribution
c$$$               CALL GETPAR( M3_WET_FLAG, LIMIT_Sg )
c$$$
c$$$C *** Write dry aerosol distribution parameters to aerosol diagnostic array
c$$$               IF ( WRITETIME .AND. AERDIAG ) THEN
c$$$                  DIAM_SPC( C,R,L, 1 ) = EXP( AEROMODE_SDEV( 1 ) )
c$$$                  DIAM_SPC( C,R,L, 2 ) = EXP( AEROMODE_SDEV( 2 ) )
c$$$                  DIAM_SPC( C,R,L, 3 ) = EXP( AEROMODE_SDEV( 3 ) )
c$$$                  DIAM_SPC( C,R,L, 4 ) = AEROMODE_DIAM( 1 ) * 1.0E6  ! dry i-mode diam.
c$$$                  DIAM_SPC( C,R,L, 5 ) = AEROMODE_DIAM( 2 ) * 1.0E6  ! dry j-mode diam.
c$$$                  DIAM_SPC( C,R,L, 6 ) = AEROMODE_DIAM( 3 ) * 1.0e6  ! dry k-mode diam.
c$$$                  DIAM_SPC( C,R,L,13 ) = MOMENT3_CONC( 1 )    ! dry i-mode 3rd moment
c$$$                  DIAM_SPC( C,R,L,14 ) = MOMENT3_CONC( 2 )    ! dry j-mode 3rd moment
c$$$                  DIAM_SPC( C,R,L,15 ) = MOMENT3_CONC( 3 )    ! dry k-mode 3rd moment
c$$$                  DIAM_SPC( C,R,L,19 ) = AIRRH                ! relative humidity
c$$$               END IF   ! WRITETIME .AND. AERDIAG
c$$$
c$$$C *** Calculate aerosol surface area from the dry 2nd moment.  Dry value is
c$$$C     used in transport routines.  Put aeroSrf values back to CGRID
c$$$               DO N = 1, N_MODE
c$$$                  V = AEROSRF_MAP( N )
c$$$                  CGRID( C,R,L,V ) = PI * MOMENT2_CONC( N )
c$$$               END DO
c$$$
c$$$#ifdef twoway
c$$$               IF ( CMAQ_WRF_FEEDBACK ) THEN
c$$$                  IF ( TIME_TO_CALL_FEEDBACK_WRITE ) THEN
c$$$                     CALL FEEDBACK_WRITE ( C, R, L, CGRID(C,R,L,:), CGRID(C,R,L,O3),
c$$$!    &                                     aeromode_diam, aeromode_sdev, jdate, jtime)
c$$$     &                                     JDATE, JTIME )
c$$$                  END IF
c$$$               END IF
c$$$#endif
c$$$
c$$$            END DO ! loop on MY_COLS
c$$$         END DO ! loop on MY_ROWS
c$$$      END DO ! loop on NLAYS
c$$$
c$$$C *** If last call this hour, write visibility information.
c$$$      IF ( WRITETIME ) THEN
c$$$         MDATE = JDATE
c$$$         MTIME = JTIME
c$$$         CALL NEXTIME ( MDATE, MTIME, TSTEP( 2 ) )
c$$$         WSTEP = 0
c$$$         WRITETIME = .FALSE.
c$$$
c$$$         IF ( .NOT. WRITE3( CTM_VIS_1, ALLVAR3,
c$$$     &                      MDATE, MTIME, VIS_SPC ) ) THEN
c$$$            XMSG = 'Could not write ' // CTM_VIS_1 // ' file'
c$$$            CALL M3EXIT ( PNAME, MDATE, MTIME, XMSG, XSTAT1 )
c$$$         END IF
c$$$
c$$$         WRITE( LOGDEV, '( /5X, 3( A, :, 1X ), I8, ":", I6.6 )' )
c$$$     &                  'Timestep written to', CTM_VIS_1,
c$$$     &                  'for date and time', MDATE, MTIME
c$$$
c$$$C *** Write data to the aerosol diagnostic file.
c$$$         IF ( AERDIAG ) THEN
c$$$
c$$$            IF ( .NOT. WRITE3( CTM_DIAM_1, ALLVAR3,
c$$$     &                         MDATE, MTIME, DIAM_SPC ) ) THEN
c$$$               XMSG = 'Could not write ' // CTM_DIAM_1 // ' file'
c$$$               CALL M3EXIT ( PNAME, MDATE, MTIME, XMSG, XSTAT1 )
c$$$            END IF
c$$$
c$$$            WRITE( LOGDEV, '( /5X, 3( A, :, 1X ), I8, ":", I6.6 )' )
c$$$     &                     'Timestep written to', CTM_DIAM_1,
c$$$     &                     'for date and time', MDATE, MTIME
c$$$
c$$$         END IF
c$$$
c$$$      END IF

      RETURN
      END
