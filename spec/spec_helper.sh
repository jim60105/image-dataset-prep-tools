#!/bin/zsh
# Copyright (C) 2025 Jim Chen <Jim@ChenJ.im>, licensed under GPL-3.0-or-later
#
# This program is free software: you can redistribute it and/or modify
# it under the terms of the GNU General Public License as published by
# the Free Software Foundation, either version 3 of the License, or
# (at your option) any later version.
#
# This program is distributed in the hope that it will be useful,
# but WITHOUT ANY WARRANTY; without even the implied warranty of
# MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
# GNU General Public License for more details.
#
# You should have received a copy of the GNU General Public License
# along with this program.  If not, see <https://www.gnu.org/licenses/>.
# ==================================================================
#
# ShellSpec helper functions for testing image dataset preparation tools

# Set nullglob option for safe testing
setopt nullglob

# Test environment setup
export TESTING=1
export TEST_TMP_DIR=""

# Initialize test environment
setup_test_env() {
  TEST_TMP_DIR=$(mktemp -d)
  cd "$TEST_TMP_DIR" || exit 1
  
  # Copy test fixtures to temporary directory when needed
  if [[ -d "$SHELLSPEC_PROJECT_ROOT/spec/support/fixtures" ]]; then
    cp -r "$SHELLSPEC_PROJECT_ROOT/spec/support/fixtures"/* . 2>/dev/null || true
  fi
}

# Cleanup test environment
cleanup_test_env() {
  if [[ -n "$TEST_TMP_DIR" && -d "$TEST_TMP_DIR" ]]; then
    cd /tmp
    rm -rf "$TEST_TMP_DIR"
  fi
}

# Mock function for user input
mock_user_input() {
  local input="$1"
  echo "$input"
}

# Helper function to create test image files
create_test_image() {
  local filename="$1"
  local width="${2:-1024}"
  local height="${3:-768}"
  
  # Create a simple test image file (just touch it for tests)
  touch "$filename"
  
  # Store dimensions in a way our mock can read them
  echo "${width} ${height}" > ".${filename}.dimensions"
}

# Helper function to create test text files
create_test_txt() {
  local filename="$1"
  local content="$2"
  
  printf "%s" "$content" > "$filename"
}

# Helper function to create complete test dataset
create_test_dataset() {
  local type="$1"  # complete, missing_txt, orphaned_txt, mixed_issues
  
  case "$type" in
    "complete")
      create_test_image "test1.jpg" 1024 768
      create_test_txt "test1.txt" "1girl, anime, character, long hair, blue eyes"
      create_test_image "test2.png" 800 600  
      create_test_txt "test2.txt" "1girl, manga, girl, short hair, green eyes"
      ;;
    "missing_txt")
      create_test_image "missing1.jpg" 1024 768
      create_test_image "missing2.png" 800 600
      ;;
    "orphaned_txt")
      create_test_txt "orphan1.txt" "1girl, anime, character"
      create_test_txt "orphan2.txt" "1girl, manga, girl"
      ;;
    "mixed_issues")
      create_test_image "good.jpg" 1024 768
      create_test_txt "good.txt" "1girl, anime, character, long hair, blue eyes, green dress"
      create_test_image "missing_txt.jpg" 800 600
      create_test_image "small.jpg" 400 300
      create_test_txt "small.txt" "1girl, small"  # Too few tags
      create_test_txt "orphan.txt" "1girl, orphaned, file"
      create_test_txt "duplicates.txt" "1girl, anime, character, anime, character"  # Duplicate tags
      ;;
  esac
}

# Override commands with mocks when testing
if [[ "$TESTING" == "1" ]]; then
  alias read='mock_user_input'
fi
