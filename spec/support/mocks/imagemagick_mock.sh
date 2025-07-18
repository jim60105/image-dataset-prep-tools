#!/bin/zsh
# Copyright (C) 2025 Jim Chen <Jim@ChenJ.im>, licensed under GPL-3.0-or-later
#
# Mock functions for ImageMagick commands used in testing

# Mock magick identify command
mock_magick_identify() {
  local filename="$1"
  local format="$2"
  
  # Handle different format options
  if [[ "$format" == "-format" ]]; then
    local format_string="$3"
    shift 3
    filename="$1"
    
    case "$filename" in
      *test_1024x768*|*standard*) 
        case "$format_string" in
          "%w %h") echo "1024 768" ;;
          "%w") echo "1024" ;;
          "%h") echo "768" ;;
        esac
        ;;
      *test_800x600*|*needs_resize*)
        case "$format_string" in
          "%w %h") echo "800 600" ;;
          "%w") echo "800" ;;
          "%h") echo "600" ;;
        esac
        ;;
      *test_400x300*|*small*)
        case "$format_string" in
          "%w %h") echo "400 300" ;;
          "%w") echo "400" ;;
          "%h") echo "300" ;;
        esac
        ;;
      *test_2000x1500*|*large*)
        case "$format_string" in
          "%w %h") echo "2000 1500" ;;
          "%w") echo "2000" ;;
          "%h") echo "1500" ;;
        esac
        ;;
      *test_corrupted*|*corrupted*)
        return 1
        ;;
      *)
        case "$format_string" in
          "%w %h") echo "1024 768" ;;
          "%w") echo "1024" ;;
          "%h") echo "768" ;;
        esac
        ;;
    esac
  else
    # Basic identify without format
    case "$filename" in
      *test_1024x768*) echo "$filename JPEG 1024x768 8-bit sRGB" ;;
      *test_800x600*) echo "$filename PNG 800x600 8-bit sRGB" ;;
      *test_400x300*) echo "$filename JPEG 400x300 8-bit sRGB" ;;
      *test_corrupted*) return 1 ;;
      *) echo "$filename JPEG 1024x768 8-bit sRGB" ;;
    esac
  fi
}

# Mock magick resize command
mock_magick_resize() {
  local input_file=""
  local resize_spec=""
  local output_file=""
  
  # Parse magick resize arguments
  local i=1
  for arg in "$@"; do
    case "$i" in
      1) input_file="$arg" ;;
      2) if [[ "$arg" == "-resize" ]]; then ((i++)); fi ;;
      3) resize_spec="$arg" ;;
      4) output_file="$arg" ;;
    esac
    ((i++))
  done
  
  # If output file is same as input (overwrite), just touch it
  if [[ "$input_file" == "$output_file" || -z "$output_file" ]]; then
    touch "$input_file"
    echo "Resized $input_file with spec $resize_spec"
  else
    touch "$output_file"
    echo "Resized $input_file to $output_file with spec $resize_spec"
  fi
}

# Simulate ImageMagick failure
simulate_imagemagick_failure() {
  return 1
}

# Mock functions are automatically available in zsh subshells
# export -f mock_magick_identify
# export -f mock_magick_resize
# export -f simulate_imagemagick_failure