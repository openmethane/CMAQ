
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
C $Header: /project/yoj/arc/CCTM/src/gas/ebi_cb05tucl/hrg1.F,v 1.3 2011/10/21 16:10:52 yoj Exp $

C what(1) key, module and SID; SCCS file; date and time of last delta:
C %W% %P% %G% %U%

       SUBROUTINE HRG1( DTC )

C**********************************************************************
C
C  FUNCTION: To solve for the concentration of NO2, NO, O3, and O3P
C            algebraically.
C
C  PRECONDITIONS: For the CB05TUCL family of mechanisms
C
C  KEY SUBROUTINES/FUNCTIONS CALLED: None
C
C  REVISION HISTORY: Created by EBI solver program, Sept. 12, 2011
C
C**********************************************************************
      USE HRDATA

      IMPLICIT NONE


C..INCLUDES: None


C..ARGUMENTS:
      REAL DTC                      ! Time step


C..PARAMETERS: None


C..EXTERNAL FUNCTIONS: NONE


C..SAVED LOCAL VARIABLES:
      CHARACTER( 16 ), SAVE  :: PNAME = 'HRG1'   ! Prgram Name


C..SCRATCH LOCAL VARIABLES:
      REAL O1D_S               ! sum of O1D loss frequencies
      REAL O3P_S               ! stoich coeff for O3P from O1D

      REAL EXN_S               ! sum of NO2EX loss frequencies
      REAL NO2_S               ! stoich coeff for NO2 from NO2EX


      REAL R1_2                ! production term for NO from NO2
      REAL R2_1                ! production term for NO2 from NO
      REAL P1, P2, P3, P12     ! production terms for NO, NO2, O3, & O3P
      REAL L1, L2, L3, L12     ! loss terms for NO, NO2, O3, O3P
      REAL L1_INV, L2_INV,
     &     L3_INV, L12_INV     ! inverse of loss terms

      REAL T1, T2, T3, T4, T5  ! intermerdiate terms
      REAL F1, F2, F3          ! intermerdiate terms
      REAL A, B, C             ! coefficients for quadratic equation
      REAL Q, XX, S1, S2       ! intermerdiate terms

      REAL RK1, RK2, RK3       ! rate constants

      REAL PO3                 ! temp variable for O3

C**********************************************************************


cccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccc
c  O1D Section
c    1) sum of the rate constants for all O1D loss reactions
c    2) get fractional yield of O3P from O1D loss
cccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccc
      O1D_S =           RKI(  10 )                   ! O1D=O
     &       +          RKI(  11 )                   ! O1D=2*OH
     &       +          RKI(  38 )                   ! O1D=OH+HO2

      O3P_S =           RKI(  10 )                   ! O1D=O

      O3P_S  = O3P_S / O1D_S


cccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccc
c  NO Section
c    R1_2 = production of NO from NO2 ( rates of form k[NO2][x] )
c           except NO2+NO3=NO+NO2 (it is treated as if it were NO3=NO )
c    P1 =   remaining NO production terms
c    L1 =   loss of NO (except rxns producing NO2 - they are in R2_1)
cccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccc
      R1_2 =           RKI(   1 )                   ! NO2=NO+O
     &      +          RKI(   4 ) * YC( O       )   ! NO2+O=NO
     &      +  0.200 * RKI( 172 ) * YC( ISOP    )   ! NO2+ISOP=0.2*NO+...
      R1_2  = R1_2 * DTC


      P1 =           RXRAT(  15 )      ! NO3=NO
     &    +          RXRAT(  17 )      ! NO2+NO3=NO+NO2
     &    +          RXRAT(  25 )      ! HONO=NO+OH
     &    +          RXRAT(  27 )      ! HONO+HONO=NO+NO2
      P1    = YC0( NO ) + P1 * DTC


      L1 =           RKI(  23 ) * YC( NO2     )   ! NO+NO2=2*HONO
     &    +          RKI(  24 ) * YC( OH      )   ! NO+OH=HONO
     &    +          RKI(  55 ) * YC( XO2N    )   ! NO+XO2N=NTR
     &    +  0.140 * RKI( 129 ) * YC( TO2     )   ! NO+TO2=0.86*NO2+...
     &    +  0.140 * RKI( 149 ) * YC( CAO2    )   ! NO+CAO2=0.86*NO2+...
      L1    = 1.0 + L1 * DTC


cccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccc
c  NO2 Section
c    R2_1 = production of NO2 from NO ( rates of form k[NO][x] )
c            a)  NO+O3=NO2 not included
c            b)  NO+NO3=2NO2 ( 1/2 of NO2 formation rate included )
c            c)  NO3+NO2=NO+NO2 is not included for NO2
c    P2 =  remaining NO2 production terms 
c            a)  NO+O3=NO2 not included
c            b)  NO+NO3=2NO2 (1/2 of NO2 formation rate included )
c    L2 = loss of NO2 (except rxns producing NO2 - they are in R1_2)
cccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccc
      R2_1 =           RKI(   6 ) * YC( O       )   ! NO+O=NO2
     &      +          RKI(  16 ) * YC( NO3     )   ! NO+NO3=2*NO2
     &      +  2.000 * RKI(  22 ) * YC( NO      )   ! NO+NO=2*NO2
     &      +          RKI(  30 ) * YC( HO2     )   ! NO+HO2=NO2+OH
     &      +          RKI(  54 ) * YC( XO2     )   ! NO+XO2=NO2
     &      +          RKI(  67 ) * YC( MEO2    )   ! NO+MEO2=NO2+HO2+FORM
     &      +          RKI(  80 ) * YC( HCO3    )   ! NO+HCO3=NO2+FACD+HO2
     &      +          RKI(  87 ) * YC( C2O3    )   ! NO+C2O3=NO2+MEO2
     &      +          RKI( 102 ) * YC( CXO3    )   ! NO+CXO3=NO2+ALD2+...
     &      +  0.860 * RKI( 129 ) * YC( TO2     )   ! NO+TO2=0.86*NO2+...
     &      +          RKI( 139 ) * YC( CRN2    )   ! NO+CRN2=NO2+CRNO
     &      +  0.860 * RKI( 149 ) * YC( CAO2    )   ! NO+CAO2=0.86*NO2+...
     &      +          RKI( 151 ) * YC( OPO3    )   ! NO+OPO3=NO2+XO2+...
     &      +          RKI( 179 ) * YC( CLO     )   ! NO+CLO=NO2+CL
      R2_1  = R2_1 * DTC


      P2 =           RXRAT(  14 )      ! NO3=NO2+O
     &    +          RXRAT(  16 )      ! NO+NO3=2*NO2
     &    +          RXRAT(  21 )      ! N2O5=NO2+NO3
     &    +          RXRAT(  26 )      ! OH+HONO=NO2
     &    +          RXRAT(  27 )      ! HONO+HONO=NO2+NO
     &    +          RXRAT(  32 )      ! PNA=NO2+HO2
     &    +          RXRAT(  33 )      ! OH+PNA=NO2
     &    +          RXRAT(  46 )      ! NO3+O=NO2
     &    +          RXRAT(  47 )      ! NO3+OH=NO2+HO2
     &    +          RXRAT(  49 )      ! NO3+O3=NO2
     &    +  2.000 * RXRAT(  50 )      ! NO3+NO3=2*NO2
     &    +  0.610 * RXRAT(  51 )      ! PNA=0.61*NO2+0.61*HO2+...
     &    +          RXRAT(  52 )      ! HNO3=NO2+OH
     &    +          RXRAT(  53 )      ! N2O5=NO2+NO3
     &    +          RXRAT(  62 )      ! NTR=NO2+HO2+0.33*FORM+...
     &    +          RXRAT(  89 )      ! PAN=NO2+C2O3
     &    +          RXRAT(  90 )      ! PAN=NO2+C2O3
     &    +          RXRAT( 104 )      ! PANX=NO2+CXO3
     &    +          RXRAT( 105 )      ! PANX=NO2+CXO3
     &    +          RXRAT( 106 )      ! PANX+OH=NO2+ALD2
     &    +          RXRAT( 119 )      ! NO3+OLE=NO2+FORM+...
     &    +          RXRAT( 123 )      ! NO3+ETH=NO2+XO2+2*FORM
     &    +          RXRAT( 127 )      ! IOLE+NO3=NO2+...
     &    +          RXRAT( 153 )      ! OPAN=NO2+OPO3
     &    +  0.200 * RXRAT( 160 )      ! NO3+ISOP=0.2*NO2+...
     &    +  0.470 * RXRAT( 168 )      ! TERP+NO3=0.47*NO2+...
      P2 = YC0( NO2 ) + P2 * DTC


      L2 =           RKI(   5 ) * YC( O       )   ! NO2+O=NO3
     &    +          RKI(   7 ) * YC( O3      )   ! NO2+O3=NO3
     &    +          RKI(  18 ) * YC( NO3     )   ! NO2+NO3=N2O5
     &    +          RKI(  23 ) * YC( NO      )   ! NO2+NO=2*HONO
     &    +          RKI(  28 ) * YC( OH      )   ! NO2+OH=HNO3
     &    +          RKI(  31 ) * YC( HO2     )   ! NO2+HO2=PNA
     &    +          RKI(  88 ) * YC( C2O3    )   ! NO2+C2O3=PAN
     &    +          RKI( 103 ) * YC( CXO3    )   ! NO2+CXO3=PANX
     &    +          RKI( 115 ) * YC( ROR     )   ! NO2+ROR=NTR
     &    +          RKI( 133 ) * YC( CRO     )   ! NO2+CRO=CRON
     &    +          RKI( 137 ) * YC( CRNO    )   ! NO2+CRNO=2*NTR
     &    +          RKI( 152 ) * YC( OPO3    )   ! NO2+OPO3=OPAN
     &    +  0.800 * RKI( 172 ) * YC( ISOP    )   ! NO2+ISOP=0.2*NO+...
      L2     = 1.0 + L2 * DTC


cccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccc
c  O3 Section
c    P3 = production of O3 except O+O2=O3
c    L3 =   loss terms for O3 except NO+O3=NO2
cccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccc
      P3 =   0.200 * RXRAT(  91 )      ! C2O3+HO2=0.2*O3+...
     &    +  0.200 * RXRAT( 107 )      ! CXO3+HO2=0.2*O3+...
      P3 = YC0( O3 ) + P3 * DTC


      L3 =           RKI(   7 ) * YC( NO2     )   ! O3+NO2=NO3
     &    +          RKI(   8 )                   ! O3=O
     &    +          RKI(   9 )                   ! O3=O1D
     &    +          RKI(  12 ) * YC( OH      )   ! O3+OH=HO2
     &    +          RKI(  13 ) * YC( HO2     )   ! O3+HO2=OH
     &    +          RKI(  49 ) * YC( NO3     )   ! O3+NO3=NO2
     &    +          RKI( 118 ) * YC( OLE     )   ! O3+OLE=0.18*ALD2+...
     &    +          RKI( 122 ) * YC( ETH     )   ! O3+ETH=FORM+...
     &    +          RKI( 126 ) * YC( IOLE    )   ! O3+IOLE=...
     &    +          RKI( 138 ) * YC( CRNO    )   ! O3+CRNO=CRN2
     &    +          RKI( 145 ) * YC( OPEN    )   ! O3+OPEN=...
     &    +          RKI( 159 ) * YC( ISOP    )   ! O3+ISOP=...
     &    +          RKI( 162 ) * YC( ISPD    )   ! O3+ISPD=...
     &    +          RKI( 167 ) * YC( TERP    )   ! O3+TERP=0.57*OH+...
     &    +          RKI( 177 ) * YC( CL      )   ! O3+CL=CLO
      L3    = 1.0 + L3 * DTC


cccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccc
c  O3P Section 
c    P12 = production of O3P except NO2+hv=O3P (J1)
c    L12 = loss terms
cccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccc
      P12 =           RXRAT(   8 )      ! O3=O
     &     +  O3P_S * RXRAT(   9 )      ! O3=O1D
     &     +          RXRAT(  14 )      ! NO3=O+NO2
     &     +          RXRAT(  41 )      ! OH+OH=O
     &     +  0.500 * RXRAT( 126 )      ! IOLE+O3=0.5*O+...
      P12 = YC0( O ) + P12 * DTC


      L12 =           RKI(   2 )                   ! O=O3
     &     +          RKI(   4 ) * YC( NO2     )   ! O+NO2=NO
     &     +          RKI(   5 ) * YC( NO2     )   ! O+NO2=NO3
     &     +          RKI(   6 ) * YC( NO      )   ! O+NO=NO2
     &     +          RKI(  40 ) * YC( OH      )   ! O+OH=HO2
     &     +          RKI(  44 ) * YC( HO2     )   ! O+HO2=OH
     &     +          RKI(  45 ) * YC( H2O2    )   ! O+H2O2=OH+HO2
     &     +          RKI(  46 ) * YC( NO3     )   ! O+NO3=NO2
     &     +          RKI(  76 ) * YC( FORM    )   ! O+FORM=OH+HO2+CO
     &     +          RKI(  83 ) * YC( ALD2    )   ! O+ALD2=C2O3+OH
     &     +          RKI(  98 ) * YC( ALDX    )   ! O+ALDX=CXO3+OH
     &     +          RKI( 116 ) * YC( OLE     )   ! O+OLE=0.2*ALD2+...
     &     +          RKI( 120 ) * YC( ETH     )   ! O+ETH=FORM+1.7*HO2+CO+...
     &     +          RKI( 124 ) * YC( IOLE    )   ! O+IOLE=1.24*ALD2+...
     &     +          RKI( 157 ) * YC( ISOP    )   ! O+ISOP=0.75*ISPD+...
     &     +          RKI( 165 ) * YC( TERP    )   ! O+TERP=0.15*ALDX+...
      L12   = 1.0 + L12 * DTC

ccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccc
c  Solution section
ccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccc

c..compute reciprocal of loss terms
      L1_INV  = 1.0 / L1
      L2_INV  = 1.0 / L2
      L3_INV  = 1.0 / L3
      L12_INV = 1.0 / L12

c..compute specific k*delta t terms
      RK1 = RKI(   1 ) * DTC            ! J1    (NO2+hv=NO+O3P)
      RK2 = RKI(   2 ) * DTC            ! J2    (O3P+O2=O3)
      RK3 = RKI(   3 ) * DTC            ! k1_3  (NO+O3=NO2)

c..compute terms that are used to calulate a,b & c
      T1 = RK1  * L2_INV                ! J1   / ( 1.0 + Lno2 * dt )
      T2 = R1_2 * L2_INV                ! r1,2 / ( 1.0 + Lno2 * dt)
      T3 = R2_1 * L1_INV                ! r2,1 / ( 1.0 + Lno  * dt)
      T4 = RK2  * L12_INV               ! J2   / ( 1.0 + Lo3p * dt )
      T5 = T3   * P1 - T2 * P2          ! T3 * Pno - T2 * Pno2

      F1 = 1.0 + T2 + T3                ! factor in calculating a & b
      F2 = T1 * T4                      ! factor in calculating a & b
      F3 = L3 * L1 + RK3 * P1           ! (1 + Lo3 * dt) (1 + lno * dt )
                                        ! + k1,3 * dt * Pno

      PO3 = P3 + P12 * T4

      A = RK3 * ( F1  - F2 )

      B = F1 * F3 +  RK3 * ( F2 * ( P2 - P1 ) + PO3 +  T5 )

      C = RK3 * P1 * ( PO3 + P2 * F2 ) + F3 * T5

      Q = -0.5 * ( B + SIGN( 1.0, B ) * SQRT( B * B - 4.0 * A * C ) )

      XX = MAX( Q / A , C / Q  )


ccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccc
c  Species solutions
c       [NO]   = ( P1 + x ) / ( 1 + L1 )
c       [NO2]  = ( P2 - x ) / ( 1 + L2 )
c       [O3 ]  = ( P3 + Ko3p->O3 ) / (1 + K1,3 * [NO] + L3 )
c       [O3P]  = ( P12 + J1 * [NO2] ) / ( 1 + L12 )
c       [O1D2] = ( Ko3->o1d * [O3] ) / ( O1D_DNM )
ccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccc
      YCP( NO ) = MAX( 0.0, ( P1 + XX ) * L1_INV )

      YCP( NO2 ) = MAX( 0.0, ( P2 - XX ) * L2_INV )

      S1 = P12 + RK1 * YCP( NO2 )

      S2 = T4 * S1

      YCP( O3 ) = ( P3 + S2 ) / ( L3 + RK3 * YCP( NO ) )

      YCP( O ) = S1 * L12_INV

      YCP( O1D ) = RKI( 9 ) * YCP( O3 ) / O1D_S

      RETURN

      END


