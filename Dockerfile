FROM debian:trixie-slim AS builder

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

# Define environment variables needed for CMAQ and lib Makefiles
ENV M3HOME=/opt/cmaq
ENV M3LIB=/opt/lib
ENV IOAPI_DIR=$M3LIB/ioapi_3.1
ENV BIN_DIR=/opt/cmaq/bin

WORKDIR /opt/cmaq

# Build ioapi
COPY scripts/ioapi /opt/scripts/ioapi
RUN /opt/scripts/ioapi/build_ioapi.sh

# Build libraries and tools
COPY models/PARIO $M3HOME/PARIO
RUN <<EOT
cd $M3HOME/PARIO
make -f makefile.gcc
EOT

COPY models/STENEX $M3HOME/STENEX
RUN <<EOT
cd $M3HOME/STENEX/se
make -f makefile.gcc
EOT

COPY scripts/config.cmaq /opt/scripts/config.cmaq
COPY models/BLDMAKE /opt/cmaq/models/BLDMAKE
COPY scripts/build/bldit.bldmake /opt/scripts/BLDMAKE/bldit.bldmake
RUN <<EOT
cd /opt/scripts/BLDMAKE
./bldit.bldmake
EOT

COPY models/CCTM /opt/cmaq/models/CCTM
COPY models/BCON /opt/cmaq/models/BCON
COPY scripts/bcon /opt/scripts/bcon
RUN <<EOT
cd /opt/scripts/bcon
./bldit.bcon
EOT

COPY models/ICON /opt/cmaq/models/ICON
COPY scripts/icon /opt/scripts/icon
RUN <<EOT
cd /opt/scripts/icon
./bldit.icon
EOT

COPY scripts/mcip /opt/scripts/mcip
RUN <<EOT
cd /opt/scripts/mcip
./build_mcip.sh
EOT

# Final image without extra packages for the runtime environment
FROM debian:trixie-slim

LABEL org.opencontainers.image.title="CMAQ"
LABEL org.opencontainers.image.description="Community Multiscale Air Quality Model"
LABEL org.opencontainers.image.vendor="The Superpower Institute"

# Install runtime libraries needed for dynamically linked binaries
RUN <<EOT
apt-get update -qy
apt-get install -qyy \
    -o APT::Install-Recommends=false \
    -o APT::Install-Suggests=false \
    csh \
    libnetcdff7 \
    mpich

apt-get clean
rm -rf /var/lib/apt/lists/* /tmp/* /var/tmp/*
EOT

ENV CMAQ_VERSION="5.0.2"
ENV OPENMETHANE_CMAQ_VERSION="1.0.0"

ENV M3HOME=/opt/cmaq
ENV M3LIB=/opt/lib
ENV BIN_DIR=/opt/cmaq/bin

COPY --from=builder /opt/scripts/config.cmaq /opt/scripts/config.cmaq
COPY --from=builder /opt/cmaq /opt/cmaq
COPY --from=builder /opt/lib /opt/lib

WORKDIR /opt/cmaq

ENTRYPOINT ["/bin/bash"]
