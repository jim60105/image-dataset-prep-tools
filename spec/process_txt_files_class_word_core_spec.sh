#!/bin/zsh

eval "$(shellspec - -c) exit 1"
# Copyright (C) 2025 Jim Chen <Jim@ChenJ.im>, licensed under GPL-3.0-or-later
#
# Core tests for class word functionality in process_txt_files.zsh

# Include spec helper for common utilities
Include spec/spec_helper.sh

Describe 'process_txt_files.zsh class word core functionality'
  setup() {
    setup_test_env
  }

  cleanup() {
    cleanup_test_env
  }

  Before 'setup'
  After 'cleanup'

  Describe 'Basic class word support'
    It 'should work with single trigger word (backward compatibility)'
      echo "blue_flower, nature, garden" > test.txt
      
      When run script "$SHELLSPEC_PROJECT_ROOT/src/process_txt_files.zsh" "hydrangea"
      The output should include "Processing complete!"
      The output should include "Processing text files with trigger: hydrangea"
      The status should be success
  The output should include "Using provided trigger word: hydrangea"
  The output should include "Loading tag aliases from:"
  The output should match pattern "*Loaded * active tag aliases*"
      The contents of file test.txt should equal "hydrangea, blue_flower, nature, garden"
    End

    It 'should detect and use class word from directory name'
      mkdir -p "1_hydrangea flower" && cd "1_hydrangea flower"
      echo "blue_flower, nature, garden" > test.txt
      
      When run script "$SHELLSPEC_PROJECT_ROOT/src/process_txt_files.zsh"
      The status should be success
    The output should include "Auto-detected trigger word from path: hydrangea"
    The output should include "Auto-detected class word from path: flower"
      The output should include "Processing text files with trigger: hydrangea, class: flower"
      The contents of file test.txt should equal "flower, hydrangea, blue_flower, nature, garden"
    End

    It 'should remove class word from content while preserving compounds'
      mkdir -p "1_hydrangea flower" && cd "1_hydrangea flower"
      echo "flower, blue_flower, sunflower" > test.txt
      
      When run script "$SHELLSPEC_PROJECT_ROOT/src/process_txt_files.zsh"
      The status should be success
    The output should include "Auto-detected trigger word from path: hydrangea"
    The output should include "Auto-detected class word from path: flower"
  The output should include "Loading tag aliases from:"
  The output should match pattern "*Loaded * active tag aliases*"
      The output should include "Processing text files with trigger: hydrangea, class: flower"
      The output should include "Processing complete!"
      The contents of file test.txt should equal "flower, hydrangea, blue_flower, sunflower"
    End

    It 'should handle single word directory (no class word)'  
      mkdir -p "1_hydrangea" && cd "1_hydrangea"
      echo "blue_flower, nature, garden" > test.txt
      
      When run script "$SHELLSPEC_PROJECT_ROOT/src/process_txt_files.zsh"
      The status should be success
    The output should include "Auto-detected trigger word from path: hydrangea"
      The output should include "Processing text files with trigger: hydrangea"
      The contents of file test.txt should equal "hydrangea, blue_flower, nature, garden"
    End

    It 'should remove both trigger and class words independently'
      mkdir -p "1_hydrangea flower" && cd "1_hydrangea flower"
      echo "hydrangea, flower, blue_flower, nature" > test.txt
      
      When run script "$SHELLSPEC_PROJECT_ROOT/src/process_txt_files.zsh"
      The status should be success
    The output should include "Auto-detected trigger word from path: hydrangea"
    The output should include "Auto-detected class word from path: flower"
  The output should include "Loading tag aliases from:"
  The output should match pattern "*Loaded * active tag aliases*"
      The output should include "Processing text files with trigger: hydrangea, class: flower"
      The output should include "Processing complete!"
      The contents of file test.txt should equal "flower, hydrangea, blue_flower, nature"
    End
  End

  Describe 'Edge cases'
    It 'should handle empty content'
      mkdir -p "1_hydrangea flower" && cd "1_hydrangea flower"
      echo "" > test.txt
      
      When run script "$SHELLSPEC_PROJECT_ROOT/src/process_txt_files.zsh"
      The status should be success
    The output should include "Auto-detected trigger word from path: hydrangea"
    The output should include "Auto-detected class word from path: flower"
  The output should include "Loading tag aliases from:"
  The output should match pattern "*Loaded * active tag aliases*"
      The output should include "Processing text files with trigger: hydrangea, class: flower"
      The output should include "Processing complete!"
      The contents of file test.txt should equal "flower, hydrangea"
    End

    It 'should handle content with only trigger word'
      echo "hydrangea" > test.txt
      
      When run script "$SHELLSPEC_PROJECT_ROOT/src/process_txt_files.zsh" "hydrangea"
      The status should be success
  The output should include "Using provided trigger word: hydrangea"
  The output should include "Loading tag aliases from:"
  The output should match pattern "*Loaded * active tag aliases*"
      The output should include "Processing text files with trigger: hydrangea"
      The output should include "Processing complete!"
      The contents of file test.txt should equal "hydrangea"
    End
  End
End
