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
export IOAPI_DIR="${IOAPI_DIR:-$M3LIB/ioapi_3.1}"

# makefile.gcc installs libpario.a and its .mod files into $M3LIB/pario
cd "$M3HOME/models/PARIO"
make -f makefile.gcc
