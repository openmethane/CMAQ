# Open Methane CMAQ

Open Methane CMAQ is a fork of US EPA
[CMAQ 5.0.2](https://github.com/USEPA/CMAQ/tree/5.0.2).

The primary science change is the introduction of the `CH4only` chemical
mechanism in `models/CCTM/MECHS/CH4only`, and associated profiles in
`models/BCON/prof_data` and `models/ICON/prof_data`.

Other changes from the official CMAQ v5.0.2 release include:
 - bug fixes
 - support for newer file formats, ie WRFv4
 - updates to build scripts to enable building and running in docker

## Packages

CMAQ is published as two Debian packages, attached to each
[GitHub release](https://github.com/openmethane/CMAQ/releases) together with a
`SHA256SUMS` file. They are built for Debian 13 (trixie), and their
dependencies name trixie packages.

| Package | Contents |
| --- | --- |
| `openmethane-cmaq` | `/opt/cmaq/bin/mcip.exe`, and `/opt/cmaq/bin/{ICON,BCON}_CH4only/` with the executable, the `GC`, `AE`, `NR` and `Species_Table_TR_0` namelists and the profile data file. Depends on the libraries they link, and `csh`. |
| `openmethane-cmaq-dev` | The build environment for CMAQ-Adjoint: the I/O API, PARIO and STENEX libraries and module files under `/opt/lib`, `bldmake`, and `config.cmaq` at `/opt/scripts/config.cmaq`. Depends on the toolchain they were built with, including `gfortran-14`. A package can't set environment variables, so a consumer sets `M3HOME`, `M3LIB` and `IOAPI_DIR` itself (see [docs/building.md](docs/building.md)). |

**Images are no longer published.** The last image is
`ghcr.io/openmethane/cmaq:1.0.2`, and it and earlier ones stay available.

### Installing

Pin a package by URL and checksum, for example in a Dockerfile:

```dockerfile
FROM scratch AS cmaq-deb
ADD --checksum=sha256:<sum> https://github.com/openmethane/CMAQ/releases/download/v<ver>/openmethane-cmaq_<ver>_amd64.deb /

FROM debian:trixie-slim
RUN --mount=type=bind,from=cmaq-deb,target=/debs \
    apt-get update && apt-get install -y /debs/*.deb
```

### Testing an unmerged change downstream

Define each package as a named stage, as above, and install it from a bind
mount on that stage. BuildKit lets a build replace a named stage with
`--build-context <stage>=<source>`, without editing the Dockerfile. Each stage
installs `/debs/*.deb`, so a directory holding both packages works for either.

Locally, from the pull request's CI artifact `debs`:

```shell
# <branch> is the CMAQ pull request's branch
RUN_ID=$(gh run list -R openmethane/CMAQ --branch <branch> --workflow build.yaml \
  --status success --limit 1 --json databaseId -q '.[0].databaseId')
gh run download "$RUN_ID" -R openmethane/CMAQ -n debs -D debs/cmaq
docker build --build-context cmaq-deb=./debs/cmaq -t openmethane:dev .
```

In downstream CI, or in AWS, the package needs a public URL. Run the
`Publish dev build` workflow on the pull request's branch:

```shell
gh workflow run dev-build.yaml -R openmethane/CMAQ --ref <branch>
```

It publishes a pre-release tagged `dev-pr<PR>-<sha7>` with the packages, and
writes the `ADD --checksum=…` lines to the job summary. Pin those in the
downstream pull request temporarily, and move the pin to a real release before
it merges. The pre-release is deleted when the CMAQ pull request closes.

### Building

`docker build --target debs --output type=local,dest=dist .` builds both
packages, and `--target test` installs `openmethane-cmaq` in a clean
`debian:trixie-slim` and runs the tests. See [docs/building.md](docs/building.md)
for the steps, and for building without Docker.

## Development

See [docs/development.md](docs/development.md), which includes how to decide
whether a pull request needs review.

## License

US EPA did not include a definitive LICENSE in the 5.0.2 release of CMAQ.
However, the CMAQ v5.4 release (2019) includes an
[MIT license](https://github.com/USEPA/CMAQ/blob/5.4/license.md). We have
duplicated that license in a best effort to respect the intentions of the
copyright owner.

Where individual files in this repo include their own license in headers or
comments, that license should be considered to apply to the file in place of
the general license provided in the repository LICENSE file.

# CMAQ

Community Multiscale Air Quality Model version 5.0.2 (April 2014)

[![DOI](https://zenodo.org/badge/DOI/10.5281/zenodo.1079898.svg)](https://doi.org/10.5281/zenodo.1079898)

CMAQ is an active open-source development project of the U.S. EPA Atmospheric Science Modeling Division that consists of a suite of programs for conducting air quality model simulations. CMAQ is supported and distributed by the CMAS Center.

CMAQ combines current knowledge in atmospheric science and air quality modeling with multi-processor computing techniques in an open-source framework to deliver fast, technically sound estimates of ozone, particulates, toxics, and acid deposition.

CMAQ version 5.0.2 is an incremental update to CMAQ version 5.0.1 that includes several changes to the science algorithms in the base model and new diagnostic/scientific modules. The instrumented versions of the model provide CMAQ users with diagnostic tools for help in interpreting model performance and results. Community versions of the model include new science algorithms contributed by development groups outside of EPA.

Release Notes available from 
https://cmascenter.org/cmaq/wiki/airqualitymodeling.org/index.php/CMAQ_version_5.0.2_(April_2014_release)_Technical_Documentation

