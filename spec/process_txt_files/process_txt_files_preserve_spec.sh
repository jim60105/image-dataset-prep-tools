#!/bin/zsh

eval "$(shellspec - -c) exit 1"
# Copyright (C) 2025 Jim Chen <Jim@ChenJ.im>, licensed under GPL-3.0-or-later
#
# Tests for --preserve/-p parameter functionality in process_txt_files.zsh

Describe 'process_txt_files.zsh --preserve/-p functionality'
  Include spec/spec_helper.sh

  setup() {
    setup_test_env
  }

  cleanup() {
    cleanup_test_env
  }

  Before 'setup'
  After 'cleanup'

  Describe 'Alias protection core functionality'
    It 'should prevent tag alias conversion for preserved tags (long form)'
      # Test with known aliases: iris_(flower) -> iris, hydrangeas -> hydrangea
      echo "iris_(flower), hydrangeas, blue_flower" > test.txt
      
      When run script "$SHELLSPEC_PROJECT_ROOT/src/process_txt_files.zsh" "flower" --preserve "iris_(flower)"
      The status should be success
      The output should include "Preserving tags: iris_(flower)"
      
      # iris_(flower) should NOT be converted to its alias "iris"
      The contents of file test.txt should include "iris_(flower)"
      # hydrangeas should still be converted normally (not preserved)
      The contents of file test.txt should include "hydrangea"
      The contents of file test.txt should not include "hydrangeas"
    End

    It 'should prevent tag alias conversion for preserved tags (short form)'
      # Test with known aliases using -p shorthand
      echo "iris_(flower), hydrangeas, blue_flower" > test.txt
      
      When run script "$SHELLSPEC_PROJECT_ROOT/src/process_txt_files.zsh" "flower" -p "iris_(flower)"
      The status should be success
      The output should include "Preserving tags: iris_(flower)"
      
      # iris_(flower) should NOT be converted to its alias "iris"
      The contents of file test.txt should include "iris_(flower)"
      # hydrangeas should still be converted normally (not preserved)
      The contents of file test.txt should include "hydrangea"
      The contents of file test.txt should not include "hydrangeas"
    End

    It 'should preserve multiple tags from alias conversion (mixed short/long)'
      echo "iris_(flower), hydrangeas, violet, rose" > test.txt
      
      When run script "$SHELLSPEC_PROJECT_ROOT/src/process_txt_files.zsh" "flower" -p "iris_(flower)" --preserve "hydrangeas"
      The status should be success
      The output should include "Preserving tags: iris_(flower), hydrangeas"
      
      # Both preserved tags should maintain original form
      The contents of file test.txt should include "iris_(flower)"
      The contents of file test.txt should include "hydrangeas"
      # Non-preserved tags get normal alias processing
      The contents of file test.txt should not include ", iris,"
    End
  End

  Describe 'Trigger/Class word protection'
    It 'should preserve tags matching trigger word when explicitly preserved (short form)'
      echo "flower, blue_flower, iris, nature" > test.txt
      
      When run script "$SHELLSPEC_PROJECT_ROOT/src/process_txt_files.zsh" "flower" -p "flower"
      The status should be success
      The output should include "Using provided trigger word: flower"
      The output should include "Preserving tags: flower"
      
      # Preserved trigger word should appear twice: as prefix and in content
      The contents of file test.txt should include "flower, flower"
    End

    It 'should preserve class word in content when explicitly preserved (short form)'
      mkdir -p "1_iris flower" && cd "1_iris flower"
      echo "flower, blue_flower, iris, nature" > test.txt
      
      When run script "$SHELLSPEC_PROJECT_ROOT/src/process_txt_files.zsh" -p "flower"
      The status should be success
      The output should include "Auto-detected trigger word from path: iris"
      The output should include "Auto-detected class word from path: flower"
      The output should include "Preserving tags: flower"
      
      # Class word should be preserved in content despite being the class word
      The contents of file test.txt should include ", flower"
    End
  End

  Describe 'Parameter parsing and validation'
    It 'should handle multiple -p flags correctly'
      echo "iris, hydrangea, violet, nature" > test.txt
      
      When run script "$SHELLSPEC_PROJECT_ROOT/src/process_txt_files.zsh" "flower" -p "iris" -p "hydrangea"
      The status should be success
      The output should include "Preserving tags: iris, hydrangea"
    End

    It 'should handle mixed short and long flags correctly'
      echo "iris, hydrangea, violet, nature" > test.txt
      
      When run script "$SHELLSPEC_PROJECT_ROOT/src/process_txt_files.zsh" "flower" -p "iris" --preserve "hydrangea"
      The status should be success
      The output should include "Preserving tags: iris, hydrangea"
    End

    It 'should show error for -p without value'
      When run script "$SHELLSPEC_PROJECT_ROOT/src/process_txt_files.zsh" "flower" -p
      The status should be failure
      The stderr should include "ERROR: -p/--preserve requires a value"
      The stderr should include "Usage:"
    End

    It 'should show error for --preserve without value'
      When run script "$SHELLSPEC_PROJECT_ROOT/src/process_txt_files.zsh" "flower" --preserve
      The status should be failure
      The stderr should include "ERROR: -p/--preserve requires a value"
      The stderr should include "Usage:"
    End

    It 'should show error for unknown parameters'
      When run script "$SHELLSPEC_PROJECT_ROOT/src/process_txt_files.zsh" "flower" --invalid-param
      The status should be failure
      The stderr should include "ERROR: Unknown parameter: --invalid-param"
    End

    It 'should handle empty preserve values gracefully'
      echo "iris, hydrangea, nature" > test.txt
      
      When run script "$SHELLSPEC_PROJECT_ROOT/src/process_txt_files.zsh" "flower" -p ""
      The status should be success
      The output should include "No tags to preserve"
    End
  End

  Describe 'Edge cases and robustness'
    It 'should work when preserved tag not found in content (short form)'
      echo "hydrangea, blue_flower, nature" > test.txt
      
      When run script "$SHELLSPEC_PROJECT_ROOT/src/process_txt_files.zsh" "flower" -p "iris"
      The status should be success
      The output should include "Preserving tags: iris"
      
      # Processing should complete normally
      The contents of file test.txt should start with "flower"
    End

    It 'should handle preserve with auto-detected trigger and class (short form)'
      mkdir -p "1_cornflower flower" && cd "1_cornflower flower"
      echo "iris, hydrangea, cornflower, nature" > test.txt
      
      When run script "$SHELLSPEC_PROJECT_ROOT/src/process_txt_files.zsh" -p "iris"
      The status should be success
      The output should include "Preserving tags: iris"
      
      # Check proper processing with preserved tag
      The contents of file test.txt should start with "flower, cornflower"
      The contents of file test.txt should include "iris"
    End

    It 'should handle comma-separated values with short form'
      echo "iris, hydrangea, violet, nature" > test.txt
      
      When run script "$SHELLSPEC_PROJECT_ROOT/src/process_txt_files.zsh" "flower" -p "iris,hydrangea"
      The status should be success
      The output should include "Preserving tags: iris, hydrangea"
      
      # Both tags should be preserved
      The contents of file test.txt should include "iris"
      The contents of file test.txt should include "hydrangea"
    End
  End
End