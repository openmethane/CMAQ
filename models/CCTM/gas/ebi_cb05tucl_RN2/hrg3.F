
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
C $Header: /project/yoj/arc/CCTM/src/gas/ebi_cb05tucl/hrg3.F,v 1.2 2011/10/21 16:10:53 yoj Exp $

C what(1) key, module and SID; SCCS file; date and time of last delta:
C %W% %P% %G% %U%

       SUBROUTINE HRG3( DTC )

C**********************************************************************
C
C  FUNCTION:  To solve for the concentration of C2O3 and PAN
C
C  PRECONDITIONS: For the CB05TUCL family of mechanisms
C
C  KEY SUBROUTINES/FUNCTIONS CALLED: None
C
C  REVISION HISTORY: Created by EBI solver program, Jan. 21, 2011
C
C**********************************************************************
      USE HRDATA

      IMPLICIT NONE

C..INCLUDES:  NONE

C..ARGUMENTS:
      REAL DTC              ! Time step


C..PARAMETERS: NONE


C..EXTERNAL FUNCTIONS: NONE


C..SAVED LOCAL VARIABLES:
      CHARACTER( 16 ), SAVE  :: PNAME = 'HRG3'      ! Program name


C..SCRATCH LOCAL VARIABLES:
      REAL   A, B, C, Q   ! Quadratic equation terms
      REAL   CMN          ! Temp scalar
      REAL   L8           ! Loss of CCO_O2
      REAL   L9           ! Loss of PAN
      REAL   P8           ! Production of CCO_O2

      REAL   K8_8         ! Kc2o3+c2o3 * delta t
      REAL   R8_9         ! Kpan-->c2o3 * delta t
      REAL   R9_8         ! Kc2o3+no2-->pan * [NO2] * delta t

C**********************************************************************


c..Production of C2O3 (except from PAN )
      P8 =           RXRAT(  83 )      ! ALD2+O=C2O3+OH
     &    +          RXRAT(  84 )      ! ALD2+OH=C2O3
     &    +          RXRAT(  85 )      ! ALD2+NO3=C2O3+HNO3
     &    +          RXRAT(  95 )      ! PACD+OH=C2O3
     &    +          RXRAT( 155 )      ! OH+MGLY=C2O3+XO2
     &    +          RXRAT( 156 )      ! MGLY=C2O3+HO2+CO
     &    +  0.210 * RXRAT( 161 )      ! OH+ISPD=0.21*C2O3+...
     &    +  0.114 * RXRAT( 162 )      ! O3+ISPD=0.114*C2O3+...
     &    +  0.967 * RXRAT( 164 )      ! ISPD=0.967*C2O3+0.067*ALD2+...
     &    +          RXRAT( 191 )      ! CL+ALD2=C2O3+HCL

c..Loss frequency of C2O3 ( not including C2O3 + C2O3 )
      L8 =           RKI(  87 ) * YC( NO      )   ! C2O3+NO=MEO2+NO2
     &    +          RKI(  88 ) * YC( NO2     )   ! C2O3+NO2=PAN
     &    +          RKI(  91 ) * YC( HO2     )   ! C2O3+HO2=...
     &    +          RKI(  92 ) * YC( MEO2    )   ! C2O3+MEO2=...
     &    +          RKI(  93 ) * YC( XO2     )   ! C2O3+XO2=...
     &    +          RKI( 111 ) * YC( CXO3    )   ! C2O3+CXO3=MEO2+...

c..Loss frequency of PAN
      L9 =           RKI(  89 )                   ! PAN=C2O3+NO2
     &    +          RKI(  90 )                   ! PAN=C2O3+NO2

c..K8_8, R8_9, and R9_8 terms
      K8_8  = RKI(  94 ) * DTC

      R8_9  = ( RKI(  89 )
     &      +   RKI(  90 ) ) * DTC 

      R9_8  = ( RKI(  88 ) * YC( NO2 ) ) * DTC 

c..Solution of quadratic equation to get C2O3 & PAN
      CMN = 1.0 + L9 * DTC
      A = 2.0 * K8_8 * CMN
      B = CMN * ( 1.0 + L8 * DTC ) - R8_9 * R9_8
      C = CMN * ( YC0( C2O3 ) + P8 * DTC ) +  R8_9 * YC0( PAN )

      Q = -0.5 * ( B + SIGN( 1.0, B ) * SQRT( B * B + 4.0 * A * C ) )

      YCP( C2O3 ) = MAX( Q / A , -C / Q  )

      YCP( PAN ) = ( YC0( PAN ) +  R9_8 * YCP( C2O3 ) ) / CMN

      RETURN

      END
