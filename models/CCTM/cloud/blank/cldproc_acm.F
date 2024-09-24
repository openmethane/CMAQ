
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
C $Header: /project/work/rep/arc/CCTM/src/cloud/cloud_acm_ae6/cldproc_acm.F,v 1.6 2011/10/21 16:10:23 yoj Exp $

C what(1) key, module and SID; SCCS file; date and time of last delta:
C %W% %P% %G% %U%

C:::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::
      SUBROUTINE CLDPROC ( CGRID, JDATE, JTIME, TSTEP )

C-----------------------------------------------------------------------
C
C  FUNCTION:  RADM/ACM and Resolved cloud process driver
C
C  PRECONDITIONS REQUIRED:
C       Dates and times represented YYYYDDD:HHMMSS.
C
C  REVISION  HISTORY:
C      Date   Who             What
C    -------- ---             -----------------------------------------
C     11/21/00 J. Young       enable appending timesteps to wetdep1 and wetdep2
C     3/01/98 S.Roselle       modified to output 2 wet deposition files
C     8/12/97 S.Roselle       added conversion of cgrid units to mol/mol units
C     6/14/94 Dongming Hwang  configuration management prototype
C     Dec 00  J. Young        move CGRID_MAP into f90 module
C     Sep 01  J. Young        Dyn Alloc - Use HGRD_DEFN
C     Jan 05  J. Young        dyn alloc - establish both horizontal & vertical
C                             domain specifications in one module
C     May 05  J. Pleim        Replaced RADMcld with RADMacmcld
C     6/08/05 S.Roselle       added new cloud diagnostic variables
C     7/21/09 D. Wong         fixed parallel bug in opening WET_DEP_2
C     Oct 10  J.Young         convert for Namelist redesign
C     3/01/11 S.Roselle       replaced I/O API include files with UTILIO_DEFN
C     5/11/11 D.Wong:         incorporated twoway model implementation
C     02Aug12 S.Roselle:      instrumented to output transmissivity for 
C                             convective and resolved clouds

C-----------------------------------------------------------------------

      USE GRID_CONF           ! horizontal & vertical domain specifications
      USE CGRID_SPCS          ! CGRID mechanism species
      USE UTILIO_DEFN

      IMPLICIT NONE

C...........INCLUDES

      INCLUDE SUBST_CONST            ! constants
      INCLUDE SUBST_FILES_ID         ! file name parameters

      CHARACTER( 120 ) :: XMSG = ' ' ! exit status message string

C...........PARAMETERS

C # of wet deposition species
      INTEGER, SAVE :: N_SPC_WDEP

      REAL, PARAMETER :: CNV1 = MWAIR * 1.0E-9
      REAL, PARAMETER :: CNV1I = 1.0 / CNV1
      REAL, PARAMETER :: CNV2 = MWAIR * 1.0E-3
      REAL, PARAMETER :: CNV2I = 1.0 / CNV2
!     REAL, PARAMETER :: CNV3 = MWAIR * 1.0E+3 / AVO  ! -> ppmV
!     REAL, PARAMETER :: CNV3 = CNV2 / AVO            ! -> mol/mol
      REAL, PARAMETER :: CNV3 = CNV2                  ! -> #/mol
      REAL, PARAMETER :: CNV3I = 1.0 / CNV3

C...........ARGUMENTS

!     REAL          CGRID( NCOLS, NROWS, NLAYS, * )  ! concentrations
!     REAL       :: CGRID( :,:,:,: )                 ! concentrations
      REAL, POINTER :: CGRID( :,:,:,: )                 ! concentrations
      INTEGER       JDATE            ! current model date, coded YYYYDDD
      INTEGER       JTIME            ! current model time, coded HHMMSS
      INTEGER       TSTEP( 3 )       ! model time step, coded HHMMSS

C...........Local Variables

      LOGICAL, SAVE :: FIRSTIME = .TRUE. ! flag for first pass thru

      LOGICAL, SAVE :: CLD_DIAG          ! flag to output cloud diagnostic files

      CHARACTER( 16 ), SAVE :: PNAME = 'CLDPROC' ! driver program name
      CHARACTER( 16 ) :: VNAME            ! input variable name list

      INTEGER       COL              ! column subscript indices
      INTEGER       FINI             ! ending position
      INTEGER       ICLDTYPE         ! 1: raining, 2: either CNP or PFW
      INTEGER       L                ! loop counter
      INTEGER       LAY              ! layer subscript indices
      INTEGER       MDATE            ! middle of this time step
      INTEGER       MTIME            ! middle of this time step
      INTEGER       NDATE            ! middle of this time step
      INTEGER       NTIME            ! middle of this time step
      INTEGER, SAVE :: NNAE          ! number of #/m3 species
      INTEGER, SAVE :: NQAE          ! number of ug/m3 species
      INTEGER, SAVE :: NSAE          ! number of m2/m3 species
      INTEGER       ROW              ! row subscript indices
      INTEGER       SPC              ! species subscript indices
      INTEGER       STRT             ! starting position
      INTEGER       STATUS           !  ENVINT status
      INTEGER       VAR              ! variable subscript indices
      INTEGER       ALLOCSTAT
      INTEGER, ALLOCATABLE, SAVE :: WDEP_MAP( : ) ! wet deposition map to CGRID
      INTEGER, ALLOCATABLE, SAVE :: QAE( : ) ! CGRID pointer to ug/m3 species
      INTEGER, ALLOCATABLE, SAVE :: NAE( : ) ! CGRID pointer to #/m3 species
      INTEGER, ALLOCATABLE, SAVE :: SAE( : ) ! CGRID pointer to m2/m3 species

      INTEGER, SAVE :: LOGDEV           ! output log unit number


!     REAL          DENS    ( NCOLS,NROWS,NLAYS ) ! air density (kg/m3)
!     REAL          CONV_DEP( NCOLS,NROWS,N_SPC_WDEP+8 ) ! convective wdep only
!     REAL          TOT_DEP ( NCOLS,NROWS,N_SPC_WDEP+1 ) ! total wdep
      REAL, ALLOCATABLE, SAVE :: DENS    ( :,:,: ) ! air density (kg/m3)
      REAL, ALLOCATABLE, SAVE :: CONV_DEP( :,:,: ) ! convective wdep only
      REAL, ALLOCATABLE, SAVE :: TOT_DEP ( :,:,: ) ! total wdep
      REAL, ALLOCATABLE, SAVE :: RESTRANS( :,: )
      REAL, ALLOCATABLE, SAVE :: SUBTRANS( :,:,: )

      REAL FAC                       ! temp conversion factor
      REAL CCMIN

      INTEGER      GXOFF, GYOFF              ! global origin offset from file
C for INTERPX
      INTEGER, SAVE :: STRTCOLMC3, ENDCOLMC3, STRTROWMC3, ENDROWMC3

C...........EXTERNAL FUNCTIONS

C-----------------------------------------------------------------------
C   begin body of subroutine  CLDPROC

C...Initialization

      IF ( FIRSTIME ) THEN
        LOGDEV = INIT3()
        FIRSTIME = .FALSE.

C...first check to make sure that some species in CGRID were specified
C...for output in the wet deposition array, otherwise notify the user
C...and return

      END IF   ! FIRSTIME


      RETURN

      END
