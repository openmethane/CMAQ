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
# Build one component of CMAQ: build.sh <step>
#
# Steps: ioapi pario stenex bldmake mcip icon bcon all
#
# This only dispatches to the script for each step, so that the Dockerfile,
# CI and a native build all run the same commands. See docs/building.md.

set -euo pipefail

SCRIPTS_DIR="$( cd -- "$(dirname "$0")" >/dev/null 2>&1 ; pwd -P )"

run_step() {
  case "$1" in
    ioapi)   cd "$SCRIPTS_DIR/ioapi"   && ./build_ioapi.sh ;;
    pario)   cd "$SCRIPTS_DIR/pario"   && ./build_pario.sh ;;
    stenex)  cd "$SCRIPTS_DIR/stenex"  && ./build_stenex.sh ;;
    bldmake) cd "$SCRIPTS_DIR/build"   && ./bldit.bldmake ;;
    mcip)    cd "$SCRIPTS_DIR/mcip"    && ./build_mcip.sh ;;
    icon)    cd "$SCRIPTS_DIR/icon"    && ./bldit.icon ;;
    bcon)    cd "$SCRIPTS_DIR/bcon"    && ./bldit.bcon ;;
    *) echo "Unknown step: $1 (expected ioapi, pario, stenex, bldmake, mcip, icon, bcon or all)" >&2; exit 2 ;;
  esac
}

if [ "$#" -ne 1 ]; then
  echo "Usage: $0 <ioapi|pario|stenex|bldmake|mcip|icon|bcon|all>" >&2
  exit 2
fi

if [ "$1" = "all" ]; then
  for step in ioapi pario stenex bldmake mcip icon bcon; do
    echo "=== build.sh $step ==="
    ( run_step "$step" )
  done
else
  run_step "$1"
fi
