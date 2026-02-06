#! /bin/csh -f

#> Source the config.cmaq file to set the build environment
 source ../config.cmaq

#> Check for M3HOME and M3LIB settings:
 if ( ! -e $M3HOME || ! -e $M3LIB ) then
    echo "   $M3HOME or $M3LIB directory not found"
    exit 1
 endif
 echo "    Model repository base path: $M3HOME"
 echo "                  library path: $M3LIB"

#> If $M3MODEL not set, default to $M3HOME
 if ( $?M3MODEL ) then
    echo "         Model repository path: $M3MODEL"
 else
    setenv M3MODEL $M3HOME
    echo " default Model repository path: $M3MODEL"
 endif

 set BLD_OS = `uname -s`        ## Script set up for Linux only 
 if ($BLD_OS != 'Linux') then
    echo "   $BLD_OS -> wrong bldit script for host!"
    exit 1
 endif

# set echo

#> Set full path of Fortran 90 compiler
setenv FC ${myFC}
setenv FFLAGS "-g -O0 -I${IOAPI_MOD} ${NETCDF_MOD}"
setenv LIBS "${IOAPI_LIB} ${NETCDF_LIB}"

cd src
make

 if ( $status != 0 ) then
    echo "   *** failure in make ***"
    exit 1
 endif


#> If $BIN_DIR is set, move compiled binaries there
if ( $?BIN_DIR ) then
  echo "Moving mcip.exe to $BIN_DIR"
  mv mcip.exe $BIN_DIR
endif

 exit
