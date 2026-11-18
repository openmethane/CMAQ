# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## What this is

Open Methane's fork of US EPA CMAQ 5.0.2 (Fortran/C, csh build scripts). The main science change is the `CH4only` chemical mechanism (`models/CCTM/MECHS/CH4only`) plus matching profiles in `models/BCON/prof_data/CH4only` and `models/ICON/prof_data/CH4only`. Other fork changes are bug fixes, WRFv4 support, and build changes so everything compiles and runs in Docker. The resulting `openmethane/cmaq` image is the base that CMAQ-Adjoint builds on, so it depends on the libraries, `config.cmaq` and paths under `/opt/cmaq` and `/opt/lib`. See `README.md` and `docs/development.md`.

Most of `models/` and `tools/` is untouched upstream EPA code. Fork-specific work lives mainly in `Dockerfile`, `scripts/` (build/config scripts), `tests/`, and the `CH4only` mechanism/profile directories.

## Build and test

Everything is built and run inside Docker; there is no supported native build.

```bash
make build   # docker build . -t cmaq
make test    # builds, then runs tests/test-all.sh inside the container
```

`make test` uses `docker run -it`; drop `-it` when running non-interactively:

```bash
docker run --rm -v ./tests:/opt/tests cmaq /opt/tests/test-all.sh
```

There are no unit tests. `tests/test-all.sh` runs MCIP → ICON → BCON in sequence (each later step consumes MCIP output) against the small WRF fixture in `tests/test-data/wrf`, and only checks that each output file exists and is non-empty. To run one step, run the container interactively, copy `tests/test-data/*` into a dir, export `M3DATA` to it, and run `tests/test.run.mcip` (ICON/BCON need MCIP's `GRIDDESC` and `METCRO3D` output first).

## Build architecture

The `Dockerfile` is the source of truth for what gets built and in what order. Only these are compiled into the image (installed under `/opt/cmaq/bin`, libs under `/opt/lib`):

1. I/O API 3.1, downloaded from cmascenter.org and built with the Makefile/Makeinclude overrides in `scripts/ioapi/`.
2. `models/PARIO` and `models/STENEX` via their `makefile.gcc`.
3. `bldmake` (`models/BLDMAKE`, via `scripts/build/bldit.bldmake`), the CMAQ tool that generates Makefiles from `cfg.*` files.
4. BCON and ICON via `scripts/{bcon,icon}/bldit.*` (these use bldmake). They default to `MECH=CH4only` and pull mechanism files from `models/CCTM/MECHS/$MECH` and profiles from `models/{BCON,ICON}/prof_data/$MECH`.
5. MCIP via `scripts/mcip/build_mcip.sh` (plain `make` in `scripts/mcip/src`).

CCTM and its variants (`CCTM_APT`, `CCTM_DDM3D`, `CCTM_ISAM`, `CCTM_STM`, `CCTM_VBS`), JPROC, PROCAN and `tools/` are **not** built in the image. `models/CCTM` is copied in only for its `ICL` and `MECHS` directories.

All csh build scripts `source ../config.cmaq` (`scripts/config.cmaq`, also shipped in the final image at `/opt/scripts/config.cmaq`). It sets compilers (`mpif90`/`mpicc`), gfortran flags, and library paths (`IOAPI_*`, `NETCDF_*` via `nf-config`, `PARIO_LIB`, `STENEX_*`). The `EXEC_ID` (`Linux_<arch>gfort`) must match the I/O API build dir naming in `build_ioapi.sh`. Compiler-flag changes usually need to go here and/or in `scripts/ioapi/Makeinclude.*`. The trixie base image ships GCC 14, which turns several legacy C diagnostics into errors; the I/O API build downgrades them rather than patching vendored sources.

The image is multi-stage: a builder stage with dev packages, then a slim runtime stage with only `csh`, `libnetcdff7`, and `mpich`. Any new runtime shared-library dependency must be added to the second stage.

## Releases, versioning, changelog

- The version lives in `pyproject.toml` (the Python project exists only to drive `uv version` and `towncrier`; there's no Python code). Don't bump it by hand. The `Create release` GitHub workflow bumps it, builds `CHANGELOG.md` with towncrier, tags `vX.Y.Z`, then bumps to the next `.devN` pre-release.
- CI (`build_docker.yaml`) passes `OPENMETHANE_CMAQ_VERSION=v<pyproject version>` as a build arg; local builds get `development`. On tag builds, CI fails if the image's version doesn't match the tag.
- Images are pushed to `ghcr.io/openmethane/cmaq`. CI runs `tests/test-all.sh` against the built image.
- A PR that changes what gets released (the image, its build or its outputs) needs a towncrier fragment in `changelog/` named `<PR number>.<type>.md`, where type is one of `breaking`, `deprecation`, `feature`, `improvement`, `fix`, `docs`, `trivial`. Write it for users, in the past tense, as a single paragraph. Never edit `CHANGELOG.md` directly for new entries. Preview with `uvx towncrier build --draft`. PRs that don't change the release, such as agent instructions, contributor docs or PR templates, get no fragment and leave the template's changelog checkbox unticked.
- PR descriptions follow `.github/pull_request_template.md`. The first line says whether the PR needs human review (`**Review:** needed — <reason>` or `**Review:** not needed — <reason>; merging <when> unless someone objects`). Decide using "Code review" in `docs/development.md`: anything that can change science outputs (running source, the `CH4only` mechanism or profiles, compilers, flags, library versions, base image) needs review.

## Before opening a pull request

For any change that isn't mechanical (see "Code review" in
`docs/development.md`), review it from a fresh context before opening the pull
request, and again after reworking it substantially. Skip this for formatter
runs, dependency bumps and CI-only changes, or if the operator asks you to.

Launch the `reviewer` subagent (`.claude/agents/reviewer.md`). Give it:

- the goal of the change and the diff range (e.g. `main...HEAD`)
- the numbers of any issues the change addresses
- any constraints the operator set during the task, such as an approach to use
  or avoid, or something to leave unchanged

Don't give it your reasoning or your view of whether the change is correct,
because it will tend to confirm what it's told.

Independent reviews of the same change find different problems. When a change
both can alter model outputs or break the CMAQ-Adjoint build, and touches the
build (compilers, flags, base image, libraries), the mechanism, or several
components, offer the operator a second review, run in parallel with the same
brief. Each review costs tens of thousands of tokens, so run the second only
if the operator agrees. Merge the two reports, counting a finding both raised
once, before dealing with them.

Deal with each item it reports:

- **Wrong, with a clear fix:** fix it, if the fix stays within the scope of the
  task and doesn't go against the operator's instructions or the project's
  guidance.
- **Needs the operator's decision:** ask the operator, with the options and
  your recommendation. This includes items with an obvious fix that would
  change science outputs or methodology, widen the change beyond what was
  asked, or make the pull request need human review when it otherwise
  wouldn't.
- **Not a problem:** dismiss it, but list it in one line to the operator with
  your reason, because you're judging criticism of your own work.

This review is part of preparing the change. Don't mention it or its findings
in the pull request description or comments.
