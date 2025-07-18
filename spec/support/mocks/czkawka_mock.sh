#!/bin/zsh
# Copyright (C) 2025 Jim Chen <Jim@ChenJ.im>, licensed under GPL-3.0-or-later
#
# Mock functions for czkawka_cli commands used in testing

# Mock czkawka_cli command
mock_czkawka_cli() {
  local output_file=""
  local mode=""
  local similarity_preset="High"
  
  # Parse arguments
  while [[ $# -gt 0 ]]; do
    case $1 in
      image)
        mode="image"
        shift
        ;;
      --file-to-save)
        output_file="$2"
        shift 2
        ;;
      --similarity-preset)
        similarity_preset="$2"
        shift 2
        ;;
      --directories|--hash-alg|--image-filter|--hash-size|--not-recursive|--do-not-print-results)
        # Skip these arguments and their values
        if [[ "$1" =~ ^--.*$ ]] && [[ ! "$2" =~ ^--.*$ ]]; then
          shift 2
        else
          shift
        fi
        ;;
      *)
        shift
        ;;
    esac
  done
  
  # Create mock output based on current test files
  if [[ -n "$output_file" && "$mode" == "image" ]]; then
    # Check if we have test files that should be considered similar
    local similar_files=()
    for file in *.jpg *.png; do
      [[ ! -f "$file" ]] && continue
      if [[ "$file" =~ (similar|dup) ]]; then
        similar_files+=("$file")
      fi
    done
    
    if [[ ${#similar_files[@]} -gt 1 ]]; then
      cat > "$output_file" << EOF
Found ${#similar_files[@]} images which have similar friends

Group 1 (${#similar_files[@]} images):
EOF
      for file in "${similar_files[@]}"; do
        echo "\"$(pwd)/$file\"" >> "$output_file"
      done
      echo "" >> "$output_file"
      
      return 11  # czkawka_cli returns 11 when files are found
    else
      # No similar files found
      echo "Found 0 images which have similar friends" > "$output_file"
      return 0
    fi
  fi
  
  return 0
}

# Simulate czkawka_cli failure
simulate_czkawka_failure() {
  return 1
}

# Mock function that creates predefined similar image results
mock_czkawka_with_results() {
  local output_file="$1"
  
  cat > "$output_file" << 'EOF'
Found 4 images which have similar friends

Group 1 (2 images):
"test_similar1.jpg"
"test_similar2.jpg"

Group 2 (2 images):
"test_dup1.png" 
"test_dup2.png"
EOF
  
  return 11
}

# Mock function that creates no similar image results
mock_czkawka_no_results() {
  local output_file="$1"
  
  echo "Found 0 images which have similar friends" > "$output_file"
  return 0
}

# Export mock functions
export -f mock_czkawka_cli
export -f simulate_czkawka_failure
export -f mock_czkawka_with_results
export -f mock_czkawka_no_results