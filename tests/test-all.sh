#!/bin/bash
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

# fail on any command exiting with non-zero status
set -e

TESTS_ROOT="$( cd -- "$(dirname "$0")" >/dev/null 2>&1 ; pwd -P )"
TEST_DATA_DIR="${TESTS_ROOT}/test-data"
TEST_OUTPUT_DIR="/tmp/cmaq-tests"

# Uncomment to output test data in the repo in tests/output
# TEST_OUTPUT_DIR="${TESTS_ROOT}/output"

# populate the test data dir with example data
mkdir -p "${TEST_OUTPUT_DIR}"
cp -r "${TEST_DATA_DIR}"/* "${TEST_OUTPUT_DIR}"

export M3DATA="${TEST_OUTPUT_DIR}"

# test that MCIP runs and produces non-zero output
$TESTS_ROOT/test.run.mcip
if [ ! -s "${TEST_OUTPUT_DIR}/mcip/GRIDBDY2D_mcip-test" ]; then
  echo "FAILED: test.run.mcip - GRIDBDY2D_mcip-test not created or zero size"
  exit 1
fi

# test that ICON runs and produces non-zero output
$TESTS_ROOT/test.run.icon
if [ ! -s "${TEST_OUTPUT_DIR}/icon/ICON_icon-test_CH4only_profile" ]; then
  echo "FAILED: test.run.icon - ICON_icon-test_CH4only_profile not created or zero size"
  exit 1
fi

# test that BCON runs and produces non-zero output
$TESTS_ROOT/test.run.bcon
if [ ! -s "${TEST_OUTPUT_DIR}/bcon/BCON_bcon-test_CH4only_profile" ]; then
  echo "FAILED: test.run.bcon - BCON_bcon-test_CH4only_profile not created or zero size"
  exit 1
fi

echo "PASSED: all tests completed successfully, cleaning up"
rm -rf "${TEST_OUTPUT_DIR}"
