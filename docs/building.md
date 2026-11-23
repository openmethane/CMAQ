# Building CMAQ

The supported build is the `Dockerfile`, which produces the two Debian
packages described in the [README](../README.md). It runs the same
`scripts/build.sh` commands that are described here. Building outside Docker
isn't supported, but everything needed to do it is written down below, and a CI
job ([`native-build.yaml`](../.github/workflows/native-build.yaml)) follows this
document literally, on a GitHub-hosted runner with no container. The commands
in the fenced blocks that follow a `<!-- ci:run -->` marker are the ones it runs.

## What you need

Debian 13 (trixie) is what the packages are built and tested on. On another
system, find the equivalents of these:

| What | Debian package | Notes |
| --- | --- | --- |
| Fortran compiler | `gfortran` (`gfortran-14` on trixie) | Module (`.mod`) files only work with the compiler version that wrote them, so everything that builds against the libraries must use the same one |
| C compiler, `make` | `build-essential` | |
| netCDF-Fortran, with `nf-config` | `libnetcdff-dev` | `config.cmaq` reads the flags from `nf-config` |
| MPI, with the `mpif90` and `mpicc` wrappers | `libmpich-dev` | |
| `csh` | `csh` | The `bldit.*` scripts and the test run scripts are csh |
| `m4` | `m4` | Used by the I/O API build |
| `wget`, `ca-certificates` | `wget`, `ca-certificates` | To download the I/O API |

<!-- ci:run -->
```bash
sudo apt-get update
sudo apt-get install -y build-essential m4 csh gfortran libnetcdff-dev libmpich-dev wget ca-certificates
```

## Where things go

The build installs into `/opt` and the scripts read these environment
variables, with these defaults:

| Variable | Default | Meaning |
| --- | --- | --- |
| `M3HOME` | `/opt/cmaq` | Contains `models/`, the sources in this repository's `models/` directory |
| `M3LIB` | `/opt/lib` | Where libraries and `bldmake` are installed |
| `IOAPI_DIR` | `$M3LIB/ioapi_3.1` | Where the I/O API is unpacked and built |
| `BIN_DIR` | unset | Where `mcip.exe` and the `ICON_CH4only` and `BCON_CH4only` directories go. Set it to `/opt/cmaq/bin` to match the packages and the tests |

Both `M3HOME` and `M3LIB` must exist and be writable. `M3HOME/models` must be
this repository's `models/` directory:

<!-- ci:run -->
```bash
sudo mkdir -p /opt/cmaq /opt/lib
sudo chown -R "$USER" /opt/cmaq /opt/lib
ln -sfn "$PWD/models" /opt/cmaq/models
export M3HOME=/opt/cmaq M3LIB=/opt/lib IOAPI_DIR=/opt/lib/ioapi_3.1 BIN_DIR=/opt/cmaq/bin
```

## The steps

Run from the root of this repository. Each step is a script in `scripts/`, and
`scripts/build.sh <step>` runs it:

| Step | Builds | Needs |
| --- | --- | --- |
| `ioapi` | I/O API 3.1, downloaded from cmascenter.org and checked against a recorded SHA-256 | |
| `pario` | PARIO | `ioapi` |
| `stenex` | STENEX | |
| `bldmake` | `bldmake`, which generates the Makefiles for ICON and BCON | |
| `mcip` | `mcip.exe` | `ioapi` |
| `icon` | `ICON_CH4only` | `ioapi`, `bldmake` |
| `bcon` | `BCON_CH4only` | `ioapi`, `bldmake` |
| `all` | all of the above, in this order | |

<!-- ci:run -->
```bash
scripts/build.sh ioapi
scripts/build.sh pario
scripts/build.sh stenex
scripts/build.sh bldmake
scripts/build.sh mcip
scripts/build.sh icon
scripts/build.sh bcon
```

Then run the tests with `tests/test-all.sh`, which runs MCIP, ICON and BCON
against a small WRF fixture. It expects the binaries in `/opt/cmaq/bin`.

## Settings for a different system

`scripts/config.cmaq` is the only place for settings that depend on the
system. These are the ones to change:

- `myFC`, `myCC`: the compiler wrappers (`mpif90`, `mpicc`).
- `myFFLAGS`, `myFRFLAGS`, `myCFLAGS`: compiler flags. The gfortran flags
  include `-fallow-argument-mismatch`, which gfortran 10 and later need for
  this code.
- `mpi`: the MPI library to link, `-lmpich` for MPICH and `-lmpi` for Open MPI.
- `NETCDF_LIB` and `NETCDF_MOD`: netCDF flags, taken from `nf-config`.
- `STENEX_SUBDIR`: the directory under `$M3LIB/stenex` that STENEX installs
  into. The name is historical, and doesn't mean GCC 8.3.0 is needed.

The I/O API has its own settings, in `scripts/ioapi/Makeinclude.*`, with one
file per architecture (`x86_64` and `aarch64`).

## What the build produces

| Path | From | In package |
| --- | --- | --- |
| `$M3LIB/ioapi_3.1/Linux_<arch>gfort/libioapi.a` and `*.mod`, `$M3LIB/ioapi_3.1/ioapi/fixed_src/*.EXT` | `ioapi` | `openmethane-cmaq-dev` |
| `$M3LIB/pario/` | `pario` | `openmethane-cmaq-dev` |
| `$M3LIB/stenex/` | `stenex` | `openmethane-cmaq-dev` |
| `$M3LIB/bldmake` | `bldmake` | `openmethane-cmaq-dev` |
| `/opt/scripts/config.cmaq` (a copy of `scripts/config.cmaq`) | | `openmethane-cmaq-dev` |
| `$BIN_DIR/mcip.exe` | `mcip` | `openmethane-cmaq` |
| `$BIN_DIR/{ICON,BCON}_CH4only/` | `icon`, `bcon` | `openmethane-cmaq`: the executable, `GC`, `AE`, `NR` and `Species_Table_TR_0` namelists, and the profile data file |

The contents of `openmethane-cmaq-dev` are the interface that CMAQ-Adjoint
builds against: it takes the libraries from those paths, and `config.cmaq`
from `/opt/scripts/config.cmaq`. A package contains these files at the paths
the build put them, with nothing moved, renamed or rewritten.

`scripts/build-deb.sh` makes the packages. Its use is in the `Dockerfile`.

## Known limitations

- Only gfortran and MPICH have been tried.
- Only `amd64` is built in CI. `scripts/ioapi/Makeinclude.Linux_aarch64gfort`
  exists but nothing checks it.
- The native build job runs on Ubuntu 26.04 (gfortran 15), rather than on
  Debian 13 (gfortran 14). The packages are only tested on Debian 13.
- The build scripts write into the repository (`scripts/build/BLD`, and the
  ICON and BCON build directories under `$BIN_DIR`).
