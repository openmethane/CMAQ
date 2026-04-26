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

