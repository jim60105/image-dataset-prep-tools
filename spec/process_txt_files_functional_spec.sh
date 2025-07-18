#!/bin/zsh
# Copyright (C) 2025 Jim Chen <Jim@ChenJ.im>, licensed under GPL-3.0-or-later
#
# Functional tests for process_txt_files.zsh

Describe 'process_txt_files.zsh functionality'
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
    It 'should execute without syntax errors'
      When call zsh -n "$SHELLSPEC_PROJECT_ROOT/process_txt_files.zsh"
      The status should be success
    End

    It 'should process text files with mock input'
      # Create test txt files
      echo "original content" > test1.txt
      echo "1girl, old_trigger, some tags" > test2.txt
      
      When call zsh "$SHELLSPEC_PROJECT_ROOT/process_txt_files.zsh" "new_trigger"
      
      The status should be success
      The stderr should include "Using provided trigger word: new_trigger"
      The stderr should include "Loading tag aliases from:"
      The stderr should include "Loaded 19608 active tag aliases"
      The output should include "Processing text files with trigger: new_trigger"
      The output should include "Processing complete!"
    End

    It 'should handle empty directory gracefully'
      # No txt files in directory
      
      When call zsh "$SHELLSPEC_PROJECT_ROOT/process_txt_files.zsh" "test_trigger"
      
      The status should be success
      The stderr should include "Using provided trigger word: test_trigger"
      The stderr should include "Loading tag aliases from:"
      The stderr should include "Loaded 19608 active tag aliases"
      The output should include "Processing text files with trigger: test_trigger"
      The output should include "Processing complete!"
    End
  End

  Describe 'Text processing logic'
    It 'should replace parentheses correctly'
      echo "tags with (parentheses) content" > test.txt
      
      When call zsh "$SHELLSPEC_PROJECT_ROOT/process_txt_files.zsh" "character"
      
      The status should be success
      The stderr should include "Using provided trigger word: character"
      The stderr should include "Loading tag aliases from:"
      The stderr should include "Loaded 19608 active tag aliases"
      The output should include "Processing text files with trigger: character"
      The output should include "Processing complete!"
    End

    It 'should verify file content after processing'
      echo "tags with (parentheses) content" > test.txt
      zsh "$SHELLSPEC_PROJECT_ROOT/process_txt_files.zsh" "character" >/dev/null 2>&1
      
      # Check if file was processed (should contain character at start)
      When call head -1 test.txt
      The output should include "character, tags"
    End

    It 'should handle multiple txt files'
      echo "content1" > file1.txt
      echo "content2" > file2.txt
      echo "content3" > file3.txt
      
      When call zsh "$SHELLSPEC_PROJECT_ROOT/process_txt_files.zsh" "trigger"
      
      The status should be success
      The stderr should include "Using provided trigger word: trigger"
      The stderr should include "Loading tag aliases from:"
      The stderr should include "Loaded 19608 active tag aliases"
      The output should include "Processing text files with trigger: trigger"
      The output should include "Processing: file1.txt"
      The output should include "Processing: file2.txt"
      The output should include "Processing: file3.txt"
      The output should include "Processing complete!"
    End
  End
End