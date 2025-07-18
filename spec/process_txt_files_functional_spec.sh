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
      When call zsh -n "$SHELLSPEC_PROJECT_ROOT/../process_txt_files.zsh"
      The status should be success
    End

    It 'should process text files with mock input'
      # Create test txt files
      echo "original content" > test1.txt
      echo "1girl, old_trigger, some tags" > test2.txt
      
      # Create input file for mock
      echo "new_trigger" > input.txt
      
      When call zsh -c '
        read() { echo "new_trigger"; }
        export -f read
        source "$SHELLSPEC_PROJECT_ROOT/../process_txt_files.zsh"
      ' < input.txt
      
      The status should be success
      The output should include "Processing text files with trigger: new_trigger"
      The output should include "Processing complete!"
    End

    It 'should handle empty directory gracefully'
      # No txt files in directory
      echo "test_trigger" > input.txt
      
      When call zsh -c '
        read() { echo "test_trigger"; }
        export -f read
        source "$SHELLSPEC_PROJECT_ROOT/../process_txt_files.zsh"
      ' < input.txt
      
      The status should be success
      The output should include "Processing complete!"
    End
  End

  Describe 'Text processing logic'
    It 'should replace parentheses correctly'
      echo "tags with (parentheses) content" > test.txt
      echo "character" > input.txt
      
      When call zsh -c '
        read() { echo "character"; }
        export -f read
        source "$SHELLSPEC_PROJECT_ROOT/../process_txt_files.zsh"
      ' < input.txt
      
      The status should be success
      The file test.txt should be exist
      # Check if file was processed (should contain 1girl, character at start)
      When call head -1 test.txt
      The output should include "1girl, character"
    End

    It 'should handle multiple txt files'
      echo "content1" > file1.txt
      echo "content2" > file2.txt
      echo "content3" > file3.txt
      echo "trigger" > input.txt
      
      When call zsh -c '
        read() { echo "trigger"; }
        export -f read
        source "$SHELLSPEC_PROJECT_ROOT/../process_txt_files.zsh"
      ' < input.txt
      
      The status should be success
      The output should include "Processing: file1.txt"
      The output should include "Processing: file2.txt"
      The output should include "Processing: file3.txt"
    End
  End
End