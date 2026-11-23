# Changelog

Versions follow [Semantic Versioning](https://semver.org/) (`<major>.<minor>.<patch>`).

Backward incompatible (breaking) changes will only be introduced in major versions
with advance notice in the **Deprecations** section of releases.


<!--
You should *NOT* be adding new changelog entries to this file, this
file is managed by towncrier. See changelog/README.md.

You *may* edit previous changelogs to fix problems like typo corrections or such.
To add a new changelog entry, please see
https://pip.pypa.io/en/latest/development/contributing/#news-entries,
noting that we use the `changelog` directory instead of news, md instead
of rst and use slightly different categories.
-->

<!-- towncrier release notes start -->

## Open Methane CMAQ v1.1.0 (2026-11-23)

### ⚠️ Breaking Changes

- Stopped publishing the `ghcr.io/openmethane/cmaq` image; the last image is `1.0.2`. CMAQ is now published as two Debian 13 (trixie) packages attached to each GitHub release, `openmethane-cmaq` (MCIP, ICON and BCON) and `openmethane-cmaq-dev` (the I/O API, PARIO, STENEX, `bldmake` and `config.cmaq` that CMAQ-Adjoint builds against), together with a `SHA256SUMS` file, so install the packages from the release instead of using the image as a base. ([#11](https://github.com/openmethane/CMAQ/pull/11))

### 🐛 Bug Fixes

- Fixed the `SHA256SUMS` file attached to pre-releases, which listed file names that did not match the attached packages because GitHub shows the `~` in a pre-release version as `.`. ([#12](https://github.com/openmethane/CMAQ/pull/12))


## Open Methane CMAQ v1.0.2 (2026-09-01)

### 🎉 Improvements

- Update the base image from `debian:bookworm-slim` to `debian:trixie-slim`. Trixie ships GCC 14, which promotes several legacy C diagnostics (notably implicit function declarations) from warnings to errors, so the I/O API build now downgrades them explicitly rather than patching the vendored I/O API 3.1 sources. ([#7](https://github.com/openmethane/CMAQ/pull/7))
- Populate `OPENMETHANE_CMAQ_VERSION` from a build `ARG` supplied by CI from `pyproject.toml`, instead of a hardcoded value that was never bumped. Local builds default to `development`, and release builds are checked against the git tag. ([#7](https://github.com/openmethane/CMAQ/pull/7))

### 🐛 Bug Fixes

- Stop passing gfortran-only flags (`-fbacktrace`, `-fallow-argument-mismatch`) to the C compiler when building I/O API, which produced a "valid for Fortran but not for C" warning for every C source file. ([#7](https://github.com/openmethane/CMAQ/pull/7))


## Open Methane CMAQ v1.0.1 (2026-08-12)

### 🐛 Bug Fixes

- Remove OS version number from build paths to prevent builds failing on different kernel versions ([#6](https://github.com/openmethane/CMAQ/pull/6))


## Open Methane CMAQ v1.0.0 (2026-04-26)

### 🆕 Features

- Initial fork of USEPA/CMAQ 5.0.2 ([#1](https://github.com/openmethane/CMAQ/pull/1))
- Add Dockerfile to provide image with compiled libraries and CMAQ ([#1](https://github.com/openmethane/CMAQ/pull/1))
- Downgrade vendored pario and stenex to versions compatible with CMAQ adjoint (CMAQ 4.7.1) ([#1](https://github.com/openmethane/CMAQ/pull/1))
- Add scripts to build ioapi, pario, stenex and bldmake ([#1](https://github.com/openmethane/CMAQ/pull/1))
- Add CH4only chemical mechanism and bcon/icon profile data ([#3](https://github.com/openmethane/CMAQ/pull/3))

### 🎉 Improvements

- Add GitHub issue and PR templates and GitHub Actions build workflow ([#2](https://github.com/openmethane/CMAQ/pull/2))
- Add changelog and release process based on uv and towncrier ([#4](https://github.com/openmethane/CMAQ/pull/4))
