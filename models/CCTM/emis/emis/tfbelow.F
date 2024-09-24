
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
C $Header: /project/yoj/arc/CCTM/src/emis/emis/tfbelow.F,v 1.3 2011/10/21 16:10:48 yoj Exp $

C:::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::
      subroutine tfbelow ( jdate, jtime, uland, tfb )

C-----------------------------------------------------------------------
C Description:
C   Extracts selected landuse types from BELD01 and BELD03 and merges
C   the selections into a dust-related landuse array (ULAND).
C   Optionally, reads 3 gridded crop calendar file and calculates an
C   erodible agriculture land fraction.
C   Applies a predetermined removal fraction in and below canopy to
C   ULAND and determines a transport factor (TFB) for this regime.
 
C Subroutines and Functions Called:
C      OPEN3, INTERPX, XTRACT3, M3EXIT

C Revison History:
C  Jun 2009 D. Tong
C  Jan 2011 J. Young: mods for inline wind-blown dust module
C  Apr 2011 S.Roselle: replaced I/O API include files with UTILIO_DEFN
C  Jul 2011 J.Young: pad vnmld for uniform string lengths
C-----------------------------------------------------------------------

      use hgrd_defn           ! horizontal domain specifications
      use utilio_defn

      implicit none

C Includes:
      include SUBST_FILES_ID  ! file name parameters
      include SUBST_CONST     ! physical and mathematical constants

C Arguments:
      integer, intent( in )  :: jdate      ! current model date, coded YYYYDDD
      integer, intent( in )  :: jtime      ! current model time, coded HHMMSS
      real,    intent( out ) :: uland( :,:,: )  ! 4 landtypes fraction 
      real,    intent( out ) :: tfb  ( :,: ) ! dust transport factor from
                                             ! flow into canopy
 
      character(  16 ) :: pname = 'TFBELOW'
!     character(  16 ) :: hname = 'RAINMAP'
      character( 128 ) :: xmsg = ' '

!     integer, parameter :: nlutyp = 21   ! number of landuse types
!!!!!!! 12 km missing 'AGRICULTURE'
      integer, parameter :: nlutyp = 20   ! number of landuse types
      integer, parameter :: nlutyp_usgs = 24   ! number of landuse types in the USGS database

      character( 16 ) :: vnmld( nlutyp ) =
     &  (/ 'USGS_urban      ',   ! 1  LUFRAC_01: Urban Land                                      
     $     'USGS_drycrop    ',   ! 2  LUFRAC_02: Dryland Cropland and Pasture, LUFRAC_04: Mixed Dryland and Irrigated Cropland and Pasture,                    
     $     'USGS_irrcrop    ',   ! 3  LUFRAC_03: Irrigated Cropland and Pasture                  
     $     'USGS_cropgrass  ',   ! 4  LUFRAC_05: Cropland-Grassland Mosaic                       
     $     'USGS_cropwdlnd  ',   ! 5  LUFRAC_06: Cropland-Woodland Mosaic                        
     $     'USGS_grassland  ',   ! 6  LUFRAC_07: Grassland                                       
     $     'USGS_shrubland  ',   ! 7  LUFRAC_08: Shrubland                                       
     $     'USGS_shrubgrass ',   ! 8  LUFRAC_09: Mixed Shrubland-Grassland                       
     $     'USGS_savanna    ',   ! 9  LUFRAC_10: Savannah                                        
     $     'USGS_decidforest',   ! 10 LUFRAC_11: Deciduous Broadleaf Forest,
     $     'USGS_evbrdleaf  ',   ! 11 LUFRAC_13: Evergreen Broadleaf Forest,
     $     'USGS_coniferfor ',   ! 12 LUFRAC_12: Deciduous Needleleaf Forest, LUFRAC_14: Evergreen Needleleaf Forest
     $     'USGS_mxforest   ',   ! 13 LUFRAC_15: Mixed Forest                                    
     $     'USGS_water      ',   ! 14 LUFRAC_16: Water                                           
     $     'USGS_wetwoods   ',   ! 15 LUFRAC_17: Herbaceous Wetland, LUFRAC_18: Wooded Wetland
     $     'USGS_sprsbarren ',   ! 16 LUFRAC_19: Barren or Sparsely Vegetated                    
     $     'USGS_woodtundr  ',   ! 17 LUFRAC_21: Wooded Tundra                                   
     $     'USGS_mxtundra   ',   ! 18 LUFRAC_22: Mixed Tundra, LUFRAC_20: Herbaceous Tundra, LUFRAC_23: Bare Ground Tundra
     $     'USGS_snowice    ',   ! 19 LUFRAC_24: Snow or Ice                                     
     $     'FOREST          ' /) ! 20                       
                                   
      character( 16 )    :: vnmld_usgs
      integer, parameter :: nusgs = 24
! map from USGS to ULAND categories, length = 24
      integer            :: id_usgs(nusgs) = (/3, 2, 2, 2, 2, 2, 2, 1, 2, 2, 4, 4, 4, 4, 4, 1, 4, 4, 1, 1, 2, 1, 1, 1/)
! map from USGS to BEIS3 categories
! (/1,2,3,2,4,5,6,7,8,9,10,12,11,12,13,14,15,15,16,18,17,18,18,19/) ! length = 24
! map from BEIS3 categories to ULAND categories
! (/3, 2, 2, 2, 2, 2, 1, 2, 2, 4, 4, 4, 4, 1, 4, 1, 2, 1, 1, 4/)    ! length = 20
                                  
                                  

      real   :: lut( ncols,nrows ) ! landuse type fraction

C uland merging:
C                                        water & barren surrounding
C        uland( c,r,1 ) = lut( c,r,7 )   'USGS_shrubland'
c                       + lut( c,r,14 )  'USGS_water'
c                       + lut( c,r,16 )  'USGS_sprsbarren'
c                       + lut( c,r,18 )  'USGS_mxtundra'
c                       + lut( c,r,19 )  'USGS_snowice'
c                                        grass surrounding
c        uland( c,r,2 ) = lut( c,r,6 )   'USGS_grassland'
c                       + lut( c,r,8 )   'USGS_shrubgrass'
c                       + lut( c,r,9 )   'USGS_savanna'
c                       + lut( c,r,17 )  'USGS_woodtundr'
c                                        crop surrounding
c                       + lut( c,r,2 )   'USGS_drycrop'
c                       + lut( c,r,3 )   'USGS_irrcrop'
c                       + lut( c,r,4 )   'USGS_cropgrass'
c                       + lut( c,r,5 )   'USGS_cropwdlnd'
c                       + lut( c,r,20 )  'agriculture' (beld3)
c                                        building surrounding
c        uland( c,r,3 ) = lut( c,r,1 )   'USGS_urban'
c                                        forest surrounding
c        uland( c,r,4 ) = lut( c,r,10 )  'USGS_decidforest'
c                       + lut( c,r,11 )  'USGS_evbrdleaf'
c                       + lut( c,r,12 )  'USGS_coniferfor'
c                       + lut( c,r,13 )  'USGS_mxforest'
c                       + lut( c,r,15 )  'USGS_wetwoods'
c                       + lut( c,r,21 )  'forest' (beld3)

!     real, allocatable :: rainf( :,: )         ! annual rainfall in inchs
      real              :: ufc  ! total weighted removal fraction for each cell
      real              :: tland

      integer :: i, j, c, r

      real   :: fw( 4 ) = ! removal fraction in and below canopy
     &         (/ 0.0,    ! water
     &            0.10,   ! grass&crop
     &            0.50,   ! building
     &            0.95 /) ! forest

!     real    :: fc( 4,2 ) = ! removal fraction in and below canopy
!    &      (/ 0.0, 0.10, 0.15, 0.20,   ! agriculture source dust
!    &         0.0, 0.30, 0.75, 0.90 /) ! road and construction source dust

      integer  gxoff, gyoff             ! global origin offset from file
      integer, save :: strtcol_01, endcol_01, strtrow_01, endrow_01

C Get domain window info
      call subhfile ( grid_cro_2d, gxoff, gyoff,
     &     strtcol_01, endcol_01, strtrow_01, endrow_01 )

C Get desert land (fraction) data
      do i = 1, nusgs
         write(vnmld_usgs,'(A,I0.2)') 'LUFRAC_',i
         if ( .not. interpx( grid_cro_2d, vnmld_usgs, pname,
     &        strtcol_01,endcol_01, strtrow_01,endrow_01, 1,1,
     &        jdate, jtime, lut ) ) then
            xmsg = 'Could not read ' // trim( vnmld( i ) ) // ' from GRIDCRO2D file'
            call m3exit( pname, jdate, jtime, xmsg, xstat1 )
         end if
         j = id_usgs(i)
         do r = 1, my_nrows
            do c = 1, my_ncols
               uland( c,r,j ) = uland( c,r,j ) + lut( c,r)
            end do
         end do
      end do


C Merge fractional BELD landuse types into 4 categories for dust removal
      do r = 1, my_nrows
      do c = 1, my_ncols

         tland = 0.0
         do i = 1, 4
            uland( c,r,i ) = max( 0.0, min( 1.0, uland( c,r,i ) ) )
            tland = tland + uland( c,r,i )
         end do

         if ( tland .gt. 1.0 ) then
            do i = 1, 4
               uland( c,r,i ) = uland( c,r,i ) * 1.0 / tland
            end do
         end if

!dqt Windbreak effect on grass&crop
!dqt     if( uland( c,r,4 ) .gt. 5 .or. rainf( c,r ) .gt. 15 ) fw( 2 ) = 0.20

         ufc = 0.0
         do i = 1, 4
            ufc = ufc + fw( i ) * uland( c,r,i )
         end do
         tfb( c,r ) = 1.0 - ufc

         if ( tfb( c,r ) .gt. 1.0 .or. tfb( c,r ) .lt. 0.0 ) then
            write( xmsg,'( a, e10.3, a, 2i4 )' ) 'Transport factor error: ',
     &            tfb( c,r ), ' At col, row: ', c, r 
            call m3exit( pname, jdate, jtime, xmsg, xstat1 )
         end if

      end do   ! my_ncols
      end do   ! my_nrows

      return
      end

