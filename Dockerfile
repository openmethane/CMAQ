FROM debian:bookworm-slim as builder

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

WORKDIR /opt/cmaq

# Build ioapi
COPY libs/ioapi /opt/ioapi
RUN /opt/ioapi/build_ioapi.sh

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

COPY scripts/config.cmaq $M3LIB/config.cmaq
COPY models/BLDMAKE /opt/cmaq/models/BLDMAKE
COPY scripts/build/bldit.bldmake $M3LIB/BLDMAKE/bldit.bldmake
RUN <<EOT
cd $M3LIB/BLDMAKE
./bldit.bldmake
EOT

# Final image without extra packages for the runtime environment
FROM debian:bookworm-slim

LABEL org.opencontainers.image.title="CMAQ"
LABEL org.opencontainers.image.description="Community Multiscale Air Quality Model"
LABEL org.opencontainers.image.vendor="The Superpower Institute"

ENV CMAQ_VERSION="5.0.2"

COPY --from=builder /opt/cmaq /opt/cmaq
COPY --from=builder /opt/lib /opt/lib

RUN <<EOT
apt-get update -qy
apt-get install -qyy \
    -o APT::Install-Recommends=false \
    -o APT::Install-Suggests=false \
    ca-certificates \
    libnetcdff7 \
    mpich \
    wget

apt-get clean
rm -rf /var/lib/apt/lists/* /tmp/* /var/tmp/*
EOT

WORKDIR /opt/cmaq

ENTRYPOINT ["/bin/bash"]
