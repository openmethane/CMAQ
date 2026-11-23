#!/usr/bin/env bash
#
# Copyright 2026 The Superpower Institute
#
# Licensed under the Apache License, Version 2.0 (the "License");
# you may not use this file except in compliance with the License.
# You may obtain a copy of the License at
#
#     http://www.apache.org/licenses/LICENSE-2.0
#
# Unless required by applicable law or agreed to in writing, software
# distributed under the License is distributed on an "AS IS" BASIS,
# WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
# See the License for the specific language governing permissions and
# limitations under the License.
#
set -euo pipefail

export M3HOME="${M3HOME:-/opt/cmaq}"
export M3LIB="${M3LIB:-/opt/lib}"

# makefile.gcc installs libse_snl.a and its .mod files into
# $M3LIB/stenex/$STENEX_SUBDIR, which is set in config.cmaq
STENEX_SUBDIR="$( cd -- "$(dirname "$0")/.." && pwd -P )/config.cmaq"
STENEX_SUBDIR="$(sed -n 's/^ *setenv STENEX_SUBDIR *//p' "$STENEX_SUBDIR")"
export STENEX_SUBDIR

cd "$M3HOME/models/STENEX/se"
make -f makefile.gcc
