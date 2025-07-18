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

# Mock function for ImageMagick identify command
mock_identify() {
  local filename="$1"
  case "$filename" in
    *test_1024x768*) echo "1024 768" ;;
    *test_800x600*) echo "800 600" ;;
    *test_400x300*) echo "400 300" ;;
    *test_2000x1500*) echo "2000 1500" ;;
    *test_corrupted*) return 1 ;;
    *) echo "1024 768" ;;  # Default
  esac
}

# Mock function for ImageMagick resize command
mock_magick() {
  local operation="$1"
  shift
  
  case "$operation" in
    "identify")
      mock_identify "$@"
      ;;
    *)
      # For resize operations, just touch the target file
      local target_file=""
      for arg in "$@"; do
        if [[ -f "$arg" ]]; then
          target_file="$arg"
          break
        fi
      done
      if [[ -n "$target_file" ]]; then
        touch "$target_file"
      fi
      ;;
  esac
}

# Mock function for czkawka_cli
mock_czkawka_cli() {
  local output_file=""
  
  # Parse arguments to find output file
  for arg in "$@"; do
    if [[ "$arg" == --file-to-save ]]; then
      shift
      output_file="$1"
      break
    fi
    shift
  done
  
  # Create mock output file with similar images
  if [[ -n "$output_file" ]]; then
    cat > "$output_file" << 'EOF'
Found 4 images which have similar friends

Group 1 (2 images):
"test_similar1.jpg"
"test_similar2.jpg"

Group 2 (2 images):  
"test_dup1.png"
"test_dup2.png"
EOF
  fi
  
  return 11  # czkawka_cli returns 11 when files are found
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
  alias magick='mock_magick'
  alias identify='mock_identify'
  alias czkawka_cli='mock_czkawka_cli'
  alias read='mock_user_input'
fi