
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
C $Header: /project/yoj/arc/CCTM/src/gas/ebi_cb05tucl/hrinit.F,v 1.3 2011/10/21 16:10:53 yoj Exp $

C what(1) key, module and SID; SCCS file; date and time of last delta:
C %W% %P% %G% %U%

C:::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::
      SUBROUTINE HRINIT

C-----------------------------------------------------------------------
C  Function: To initialize species tolerances, arrays, and indices
C
C  Preconditions: For the CB05TUCL family of mechanisms
C
C  Return Values: None
C
C  Key Subroutines/Functions Called: None
C
C  Revision History: Created by EBI solver program, Jan. 21, 2011
C   21 Jun 10 J.Young: convert for Namelist redesign
C   29 Mar 11 S.Roselle: Replaced I/O API include files with UTILIO_DEFN
C-----------------------------------------------------------------------

      USE CGRID_SPCS, ONLY: N_GC_SPC   ! CGRID mechanism species
      USE UTILIO_DEFN
      USE HRDATA

      IMPLICIT NONE

C.....Includes:
      INCLUDE SUBST_RXCMMN    ! Mechanism reaction common block

C.....Arguments: NONE

C.....Parameters: NONE

C.....External Functions:
      INTEGER  FINDEX         ! Finds location of a number in a list

C.....Saved Variables:
      CHARACTER( 16 ), SAVE  ::  PNAME = 'HRINIT'   ! Program name

C.....Local Variables:
      CHARACTER( 132 ) :: MSG = ' '       ! Log message

      INTEGER IND             ! Species index
      INTEGER N               ! Loop index
      INTEGER IOS             ! Allocate error status

C-----------------------------------------------------------------------

      N_SPEC = N_GC_SPC
      N_RXNS = NRXNS
      N_SPCL_RKS =   0

      ALLOCATE( RKI( NRXNS ),
     &          RXRAT( NRXNS ),
     &          RTOL( N_SPEC),
     &          YC(   N_SPEC),
     &          YC0(  N_SPEC),
     &          YCP(  N_SPEC),
     &          PROD( N_SPEC),
     &          LOSS( N_SPEC),
     &          PNEG( N_SPEC), STAT = IOS )
      IF ( IOS .NE. 0 ) THEN
         MSG = 'Error allocating RKI, RXRAT, RTOL, YC, YC0, YCP, PROD, LOSS, or PNEG'
         CALL M3EXIT( PNAME, 0, 0, MSG, XSTAT1 )
      END IF

      NING1 = 4
      NING2 = 4

cccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccc
c  Set species indices and pointers
cccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccc
      NO2      =   1
      NO       =   2
      O        =   3
      O3       =   4
      NO3      =   5
      O1D      =   6
      OH       =   7
      HO2      =   8
      N2O5     =   9
      HNO3     =  10
      HONO     =  11
      PNA      =  12
      H2O2     =  13
      XO2      =  14
      XO2N     =  15
      NTR      =  16
      ROOH     =  17
      FORM     =  18
      ALD2     =  19
      ALDX     =  20
      PAR      =  21
      CO       =  22
      MEO2     =  23
      MEPX     =  24
      MEOH     =  25
      HCO3     =  26
      FACD     =  27
      C2O3     =  28
      PAN      =  29
      PACD     =  30
      AACD     =  31
      CXO3     =  32
      PANX     =  33
      ROR      =  34
      OLE      =  35
      ETH      =  36
      IOLE     =  37
      TOL      =  38
      CRES     =  39
      TO2      =  40
      TOLRO2   =  41
      OPEN     =  42
      MGLY     =  43
      CRO      =  44
      CAT1     =  45
      CRON     =  46
      CRNO     =  47
      CRN2     =  48
      CRPX     =  49
      OPO3     =  50
      CAO2     =  51
      OPAN     =  52
      XYL      =  53
      XYLRO2   =  54
      ISOP     =  55
      ISPD     =  56
      ISOPRXN  =  57
      TERP     =  58
      TRPRXN   =  59
      SO2      =  60
      SULF     =  61
      SULRXN   =  62
      ETOH     =  63
      ETHA     =  64
      RN       =  65
      CL2      =  66
      CL       =  67
      HOCL     =  68
      CLO      =  69
      FMCL     =  70
      HCL      =  71
      TOLNRXN  =  72
      TOLHRXN  =  73
      XYLNRXN  =  74
      XYLHRXN  =  75
      BENZENE  =  76
      BENZRO2  =  77
      BNZNRXN  =  78
      BNZHRXN  =  79
      SESQ     =  80
      SESQRXN  =  81

c..Allocate and define ebi species
      N_EBISP  =  68
      ALLOCATE( EBISP( N_EBISP ), STAT = IOS ) 
      IF ( IOS .NE. 0 ) THEN
         MSG = 'Error allocating EBISP'
         CALL M3EXIT( PNAME, 0, 0, MSG, XSTAT1 )
      END IF

      EBISP(   1 ) = HNO3
      EBISP(   2 ) = H2O2
      EBISP(   3 ) = XO2
      EBISP(   4 ) = XO2N
      EBISP(   5 ) = NTR
      EBISP(   6 ) = ROOH
      EBISP(   7 ) = FORM
      EBISP(   8 ) = ALD2
      EBISP(   9 ) = ALDX
      EBISP(  10 ) = PAR
      EBISP(  11 ) = CO
      EBISP(  12 ) = MEO2
      EBISP(  13 ) = MEPX
      EBISP(  14 ) = MEOH
      EBISP(  15 ) = HCO3
      EBISP(  16 ) = FACD
      EBISP(  17 ) = PACD
      EBISP(  18 ) = AACD
      EBISP(  19 ) = CXO3
      EBISP(  20 ) = PANX
      EBISP(  21 ) = ROR
      EBISP(  22 ) = OLE
      EBISP(  23 ) = ETH
      EBISP(  24 ) = IOLE
      EBISP(  25 ) = TOL
      EBISP(  26 ) = CRES
      EBISP(  27 ) = TO2
      EBISP(  28 ) = TOLRO2
      EBISP(  29 ) = OPEN
      EBISP(  30 ) = MGLY
      EBISP(  31 ) = CRO
      EBISP(  32 ) = CAT1
      EBISP(  33 ) = CRON
      EBISP(  34 ) = CRNO
      EBISP(  35 ) = CRN2
      EBISP(  36 ) = CRPX
      EBISP(  37 ) = OPO3
      EBISP(  38 ) = CAO2
      EBISP(  39 ) = OPAN
      EBISP(  40 ) = XYL
      EBISP(  41 ) = XYLRO2
      EBISP(  42 ) = ISOP
      EBISP(  43 ) = ISPD
      EBISP(  44 ) = ISOPRXN
      EBISP(  45 ) = TERP
      EBISP(  46 ) = TRPRXN
      EBISP(  47 ) = SO2
      EBISP(  48 ) = SULF
      EBISP(  49 ) = SULRXN
      EBISP(  50 ) = ETOH
      EBISP(  51 ) = ETHA
      EBISP(  52 ) = RN
      EBISP(  53 ) = CL2
      EBISP(  54 ) = CL
      EBISP(  55 ) = HOCL
      EBISP(  56 ) = CLO
      EBISP(  57 ) = FMCL
      EBISP(  58 ) = HCL
      EBISP(  59 ) = TOLNRXN
      EBISP(  60 ) = TOLHRXN
      EBISP(  61 ) = XYLNRXN
      EBISP(  62 ) = XYLHRXN
      EBISP(  63 ) = BENZENE
      EBISP(  64 ) = BENZRO2
      EBISP(  65 ) = BNZNRXN
      EBISP(  66 ) = BNZHRXN
      EBISP(  67 ) = SESQ
      EBISP(  68 ) = SESQRXN


cccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccc
c  Set species tolerances
cccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccc
      RTOL( NO2     ) = 1.0E-03
      RTOL( NO      ) = 1.0E-03
      RTOL( O       ) = 1.0E+00
      RTOL( O3      ) = 1.0E-03
      RTOL( NO3     ) = 1.0E-03
      RTOL( O1D     ) = 1.0E+00
      RTOL( OH      ) = 1.0E-03
      RTOL( HO2     ) = 1.0E-03
      RTOL( N2O5    ) = 1.0E-03
      RTOL( HNO3    ) = 1.0E-03
      RTOL( HONO    ) = 1.0E-03
      RTOL( PNA     ) = 1.0E-03
      RTOL( H2O2    ) = 1.0E-03
      RTOL( XO2     ) = 1.0E-03
      RTOL( XO2N    ) = 1.0E-03
      RTOL( NTR     ) = 1.0E+00
      RTOL( ROOH    ) = 1.0E-03
      RTOL( FORM    ) = 1.0E-03
      RTOL( ALD2    ) = 1.0E-03
      RTOL( ALDX    ) = 1.0E-03
      RTOL( PAR     ) = 1.0E-03
      RTOL( CO      ) = 1.0E-03
      RTOL( MEO2    ) = 1.0E-03
      RTOL( MEPX    ) = 1.0E-03
      RTOL( MEOH    ) = 1.0E-03
      RTOL( HCO3    ) = 1.0E+00
      RTOL( FACD    ) = 1.0E-03
      RTOL( C2O3    ) = 1.0E-03
      RTOL( PAN     ) = 1.0E-03
      RTOL( PACD    ) = 1.0E-03
      RTOL( AACD    ) = 1.0E-03
      RTOL( CXO3    ) = 1.0E-03
      RTOL( PANX    ) = 1.0E-03
      RTOL( ROR     ) = 1.0E-03
      RTOL( OLE     ) = 1.0E-03
      RTOL( ETH     ) = 1.0E-03
      RTOL( IOLE    ) = 1.0E-03
      RTOL( TOL     ) = 1.0E-03
      RTOL( CRES    ) = 1.0E-03
      RTOL( TO2     ) = 1.0E-03
      RTOL( TOLRO2  ) = 1.0E-03
      RTOL( OPEN    ) = 1.0E-03
      RTOL( MGLY    ) = 1.0E-03
      RTOL( CRO     ) = 1.0E-03
      RTOL( CAT1    ) = 1.0E-03
      RTOL( CRON    ) = 1.0E-03
      RTOL( CRNO    ) = 1.0E-03
      RTOL( CRN2    ) = 1.0E-03
      RTOL( CRPX    ) = 1.0E-03
      RTOL( OPO3    ) = 1.0E-03
      RTOL( CAO2    ) = 1.0E-03
      RTOL( OPAN    ) = 1.0E-03
      RTOL( XYL     ) = 1.0E-03
      RTOL( XYLRO2  ) = 1.0E-03
      RTOL( ISOP    ) = 1.0E-03
      RTOL( ISPD    ) = 1.0E-03
      RTOL( ISOPRXN ) = 1.0E+00
      RTOL( TERP    ) = 1.0E-03
      RTOL( TRPRXN  ) = 1.0E+00
      RTOL( SO2     ) = 1.0E-03
      RTOL( SULF    ) = 1.0E+00
      RTOL( SULRXN  ) = 1.0E+00
      RTOL( ETOH    ) = 1.0E-03
      RTOL( ETHA    ) = 1.0E-03
      RTOL( RN      ) = 1.0E-03
      RTOL( CL2     ) = 1.0E-03
      RTOL( CL      ) = 1.0E-03
      RTOL( HOCL    ) = 1.0E-03
      RTOL( CLO     ) = 1.0E-03
      RTOL( FMCL    ) = 1.0E-03
      RTOL( HCL     ) = 1.0E-03
      RTOL( TOLNRXN ) = 1.0E+00
      RTOL( TOLHRXN ) = 1.0E+00
      RTOL( XYLNRXN ) = 1.0E+00
      RTOL( XYLHRXN ) = 1.0E+00
      RTOL( BENZENE ) = 1.0E-03
      RTOL( BENZRO2 ) = 1.0E-03
      RTOL( BNZNRXN ) = 1.0E+00
      RTOL( BNZHRXN ) = 1.0E+00
      RTOL( SESQ    ) = 1.0E-03
      RTOL( SESQRXN ) = 1.0E+00

      RETURN
      END
