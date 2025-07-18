#!/bin/zsh

eval "$(shellspec - -c) exit 1"
# Copyright (C) 2025 Jim Chen <Jim@ChenJ.im>, licensed under GPL-3.0-or-later
#
# Basic tests for process_txt_files.zsh to verify syntax and fundamental functionality

Describe 'process_txt_files.zsh basic functionality'
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

  Describe 'Script validation'
    It 'should have valid zsh syntax'
      When call zsh -n "$SHELLSPEC_PROJECT_ROOT/src/process_txt_files.zsh"
      The status should be success
    End

    It 'should handle invalid parameters'
      When run script "$SHELLSPEC_PROJECT_ROOT/src/process_txt_files.zsh" "param1" "param2" "param3"
      The status should be failure
      The stderr should include "ERROR: Too many parameters"
      The output should include "ERROR: No trigger word provided or could be determined"
    End
  End

  Describe 'Trigger word parameter handling'

    It 'should accept trigger word as first parameter'
      echo "test content" > test.txt
      
      When run script "$SHELLSPEC_PROJECT_ROOT/src/process_txt_files.zsh" "test_trigger"
      The status should be success
      The stderr should include "Using provided trigger word: test_trigger"
      The stderr should include "Loading tag aliases from:"
      The stderr should match pattern "*Loaded * active tag aliases*"
      The output should include "Processing text files with trigger: test_trigger"
      The output should include "Processing complete!"
    End

    It 'should auto-detect trigger from directory path'
      mkdir -p character_test && cd character_test
      echo "test content" > test.txt
      
      When run script "$SHELLSPEC_PROJECT_ROOT/src/process_txt_files.zsh"
      The status should be success
      The stderr should include "Auto-detected trigger word from path"
      The stderr should include "Loading tag aliases from:"
      The stderr should match pattern "*Loaded * active tag aliases*"
      The output should include "Processing complete!"
    End
  End

  Describe 'File processing basics'
    It 'should process txt files when they exist'
      echo "sample content" > file1.txt
      echo "another sample" > file2.txt
      
      When run script "$SHELLSPEC_PROJECT_ROOT/src/process_txt_files.zsh" "character"
      The status should be success
      The stderr should include "Using provided trigger word: character"
      The stderr should include "Loading tag aliases from:"
      The stderr should match pattern "*Loaded * active tag aliases*"
      The output should include "Processing text files with trigger: character"
      The output should include "Processing: file1.txt"
      The output should include "Processing: file2.txt"
      The output should include "Processing complete!"
    End

    It 'should handle empty directory gracefully'
      When run script "$SHELLSPEC_PROJECT_ROOT/src/process_txt_files.zsh" "character"
      The status should be success
      The stderr should include "Using provided trigger word: character"
      The stderr should include "Loading tag aliases from:"
      The stderr should match pattern "*Loaded * active tag aliases*"
      The output should include "Processing text files with trigger: character"
      The output should include "Processing complete!"
    End

    It 'should handle non-existent trigger parameter gracefully'
      echo "test content" > test.txt
      
      When run script "$SHELLSPEC_PROJECT_ROOT/src/process_txt_files.zsh" ""
      The status should be failure
      The stderr should include "Using provided trigger word:"
      The output should include "ERROR: No trigger word provided or could be determined"
    End
  End
End
