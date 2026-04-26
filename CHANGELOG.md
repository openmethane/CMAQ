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
