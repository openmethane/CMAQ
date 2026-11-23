# syntax=docker/dockerfile:1
#
# Builds CMAQ and packages it as two Debian packages (see README.md):
#   openmethane-cmaq      mcip.exe, ICON_CH4only and BCON_CH4only
#   openmethane-cmaq-dev  the build environment for CMAQ-Adjoint
#
# No image from this Dockerfile is published. Export the packages with
#   docker build --target debs --output type=local,dest=dist .
#
# Each build step is one RUN after a COPY of only that step's inputs, and runs
# the same scripts/build.sh command as a native build (docs/building.md).

# PEP 440 version converted to a Debian version, see scripts/debian-version.sh
ARG DEB_VERSION=0.0.0~development

# ---------------------------------------------------------------------------
# Build packages, and nothing else
FROM debian:trixie-slim AS toolchain

ARG DEBIAN_FRONTEND=noninteractive

RUN <<EOT
apt-get update -qy
apt-get install -qyy \
    -o APT::Install-Recommends=false \
    -o APT::Install-Suggests=false \
    ca-certificates \
    build-essential \
    m4 \
    csh \
    gfortran \
    libnetcdff-dev \
    libmpich-dev \
    wget

apt-get clean
rm -rf /var/lib/apt/lists/* /tmp/* /var/tmp/*
EOT

# Environment read by config.cmaq and the library Makefiles
ENV M3HOME=/opt/cmaq
ENV M3LIB=/opt/lib
ENV IOAPI_DIR=$M3LIB/ioapi_3.1
ENV BIN_DIR=/opt/cmaq/bin

WORKDIR /opt/cmaq

# ---------------------------------------------------------------------------
# I/O API, PARIO, STENEX and bldmake, built into /opt/lib
FROM toolchain AS libs

COPY scripts/config.cmaq /opt/scripts/config.cmaq

COPY scripts/build.sh /opt/scripts/build.sh
COPY scripts/ioapi /opt/scripts/ioapi
RUN /opt/scripts/build.sh ioapi

COPY scripts/build.sh /opt/scripts/build.sh
COPY scripts/pario /opt/scripts/pario
COPY models/PARIO /opt/cmaq/models/PARIO
RUN /opt/scripts/build.sh pario

COPY scripts/build.sh /opt/scripts/build.sh
COPY scripts/stenex /opt/scripts/stenex
COPY models/STENEX /opt/cmaq/models/STENEX
RUN /opt/scripts/build.sh stenex

COPY scripts/build.sh /opt/scripts/build.sh
COPY scripts/build /opt/scripts/build
COPY models/BLDMAKE /opt/cmaq/models/BLDMAKE
RUN /opt/scripts/build.sh bldmake

# ---------------------------------------------------------------------------
# openmethane-cmaq-dev: the files of /opt/lib that CMAQ-Adjoint builds against
FROM libs AS package-dev

RUN <<EOT
apt-get update -qy
apt-get install -qyy -o APT::Install-Recommends=false dpkg-dev
EOT

ARG DEB_VERSION
COPY scripts/build-deb.sh /opt/scripts/build-deb.sh
# .mod files only work with the compiler version that wrote them, hence gfortran-14
RUN <<EOT
set -e
IOAPI_BUILD=$IOAPI_DIR/Linux_$(uname -m)gfort
/opt/scripts/build-deb.sh --no-shlibdeps \
    openmethane-cmaq-dev "$DEB_VERSION" \
    "Build environment for CMAQ-Adjoint: I/O API, PARIO, STENEX, bldmake and config.cmaq" \
    /out \
    $IOAPI_BUILD/libioapi.a \
    $IOAPI_BUILD/*.mod \
    $IOAPI_DIR/ioapi/fixed_src \
    $M3LIB/pario \
    $M3LIB/stenex \
    $M3LIB/bldmake \
    /opt/scripts/config.cmaq \
    -- \
    "gfortran-14" "gfortran (>= 4:14)" "gfortran (<< 4:15)" \
    libnetcdff-dev libmpich-dev csh m4 build-essential
EOT

# ---------------------------------------------------------------------------
# MCIP, ICON and BCON, built from only the installed openmethane-cmaq-dev
FROM debian:trixie-slim AS build

ARG DEBIAN_FRONTEND=noninteractive

RUN --mount=type=bind,from=package-dev,source=/out,target=/debs <<EOT
apt-get update -qy
apt-get install -qyy -o APT::Install-Recommends=false /debs/*.deb
apt-get clean
rm -rf /var/lib/apt/lists/* /tmp/* /var/tmp/*
EOT

ENV M3HOME=/opt/cmaq
ENV M3LIB=/opt/lib
ENV IOAPI_DIR=$M3LIB/ioapi_3.1
ENV BIN_DIR=/opt/cmaq/bin

WORKDIR /opt/cmaq

COPY scripts/build.sh /opt/scripts/build.sh
COPY scripts/mcip /opt/scripts/mcip
RUN /opt/scripts/build.sh mcip

COPY scripts/build.sh /opt/scripts/build.sh
COPY scripts/bcon /opt/scripts/bcon
COPY models/CCTM/ICL /opt/cmaq/models/CCTM/ICL
COPY models/CCTM/MECHS /opt/cmaq/models/CCTM/MECHS
COPY models/BCON /opt/cmaq/models/BCON
RUN /opt/scripts/build.sh bcon

COPY scripts/build.sh /opt/scripts/build.sh
COPY scripts/icon /opt/scripts/icon
COPY models/ICON /opt/cmaq/models/ICON
RUN /opt/scripts/build.sh icon

# ---------------------------------------------------------------------------
# openmethane-cmaq: the executables, with the namelists and profiles beside ICON and BCON
FROM build AS package

RUN <<EOT
apt-get update -qy
apt-get install -qyy -o APT::Install-Recommends=false dpkg-dev
EOT

ARG DEB_VERSION
COPY scripts/build-deb.sh /opt/scripts/build-deb.sh
RUN <<EOT
set -e
FILES="$BIN_DIR/mcip.exe"
# The run scripts read the namelists and the profile data from beside each executable
for m in ICON BCON; do
  d=$BIN_DIR/${m}_CH4only
  p=$(echo $m | sed 's/ICON/ic/;s/BCON/bc/')
  FILES="$FILES $d/${m}_CH4only $d/GC_CH4only.nml $d/AE_CH4only.nml $d/NR_CH4only.nml $d/Species_Table_TR_0.nml $d/${p}_profile_CH4only.dat"
done
/opt/scripts/build-deb.sh \
    openmethane-cmaq "$DEB_VERSION" \
    "Open Methane CMAQ: MCIP, and ICON and BCON with the CH4only mechanism" \
    /out \
    $FILES \
    -- csh
EOT

# ---------------------------------------------------------------------------
# Both packages, for export with --target debs
FROM scratch AS debs
COPY --from=package-dev /out/*.deb /
COPY --from=package /out/*.deb /

# ---------------------------------------------------------------------------
# openmethane-cmaq installed into a clean image, which must run the tests
FROM debian:trixie-slim AS test

ARG DEBIAN_FRONTEND=noninteractive

RUN --mount=type=bind,from=package,source=/out,target=/debs <<EOT
apt-get update -qy
apt-get install -qyy -o APT::Install-Recommends=false /debs/openmethane-cmaq_*.deb
apt-get clean
rm -rf /var/lib/apt/lists/* /tmp/* /var/tmp/*
EOT

COPY tests /opt/tests
RUN /opt/tests/check-libs.sh
RUN /opt/tests/test-all.sh
