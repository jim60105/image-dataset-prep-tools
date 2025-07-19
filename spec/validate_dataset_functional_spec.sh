#!/bin/zsh

eval "$(shellspec - -c) exit 1"
# Copyright (C) 2025 Jim Chen <Jim@ChenJ.im>, licensed under GPL-3.0-or-later
#
# Functional tests for validate_dataset.zsh

Describe 'validate_dataset.zsh functionality'
  setup() {
    TEST_DIR=$(mktemp -d)
    cd "$TEST_DIR"
  }

  cleanup() {
    if [[ -n "$TEST_DIR" && -d "$TEST_DIR" ]]; then
      cd /tmp
      rm -rf "$TEST_DIR"
    fi
  }

  Before 'setup'
  After 'cleanup'

  Describe 'Script execution'
    It 'should validate complete dataset successfully'
      # Create complete dataset
      touch good.jpg good.png
      echo "test_trigger, tag1, tag2, tag3, tag4, tag5" > good.txt
      echo "test_trigger, tag1, tag2, tag3, tag4, tag5" > good.txt
      
  # Mock dependencies
  Mock identify
    echo "1024 768"  # Always return good dimensions
  End

  Mock czkawka_cli
    echo "Found 0 images which have similar friends"
  End
      
  When run script "$SHELLSPEC_PROJECT_ROOT/src/validate_dataset.zsh" "test_trigger"
      The status should be success
      The output should include "Starting dataset validation"
      The output should include "✅ Dataset validation completed successfully"
    End

    It 'should detect missing txt files'
      # Create images without txt files
      touch missing1.jpg missing2.png
      
  # Mock dependencies
  Mock identify
    echo "1024 768"
  End

  Mock czkawka_cli
    echo "Found 0 images which have similar friends"
  End
      
  When run script "$SHELLSPEC_PROJECT_ROOT/src/validate_dataset.zsh" "test_trigger"
      The status should be success
      The output should include "ERROR: Missing .txt file for image: missing1.jpg"
      The output should include "ERROR: Missing .txt file for image: missing2.png"
      The output should include "❌ Dataset validation completed with errors"
    End

    It 'should handle trigger word parameter correctly'
      touch test.jpg
      echo "provided_trigger, tag1, tag2, tag3, tag4" > test.txt
      
  # Mock dependencies
  Mock identify
    echo "1024 768"
  End

  Mock czkawka_cli
    echo "Found 0 images which have similar friends"
  End
      
  When run script "$SHELLSPEC_PROJECT_ROOT/src/validate_dataset.zsh" "provided_trigger"
      The status should be success
      The output should include "Using provided trigger word: provided_trigger"
    End

    It 'should handle empty directory gracefully'
      # Empty directory
      
      # Mock dependencies  
      Mock czkawka_cli
        echo "Found 0 images which have similar friends"
      End
      
  When run script "$SHELLSPEC_PROJECT_ROOT/src/validate_dataset.zsh" "test_trigger"
      The status should be success
      The output should include "Total image files: 0"
      The output should include "Total text files: 0"
    End
  End

  Describe 'Error detection'
    It 'should detect small images'
      touch small.jpg
      echo "test_trigger, tag1, tag2, tag3, tag4" > small.txt
      
  # Mock identify to return small dimensions
  Mock identify
    echo "400 300"  # Small dimensions
  End

  Mock czkawka_cli
    echo "Found 0 images which have similar friends"
  End
      
  When run script "$SHELLSPEC_PROJECT_ROOT/src/validate_dataset.zsh" "test_trigger"
      The status should be success
      The output should include "WARNING: Image small.jpg has small dimensions: 400x300"
    End

    It 'should detect orphaned txt files'
      # Create txt file without corresponding image
      echo "test_trigger, tag1, tag2, tag3, tag4" > orphan.txt
      
      # Mock dependencies
      Mock czkawka_cli
        echo "Found 0 images which have similar friends"
      End
      
  When run script "$SHELLSPEC_PROJECT_ROOT/src/validate_dataset.zsh" "test_trigger"
      The status should be success
      The output should include "WARNING: Orphaned .txt file (no corresponding image): orphan.txt"
    End
  End
End
