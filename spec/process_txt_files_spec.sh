#!/bin/zsh

eval "$(shellspec - -c) exit 1"
# Copyright (C) 2025 Jim Chen <Jim@ChenJ.im>, licensed under GPL-3.0-or-later
#
# ShellSpec tests for process_txt_files.zsh

# Include spec helper
Include spec/spec_helper.sh

Describe 'process_txt_files.zsh'

  setup() {
    setup_test_env
  }

  cleanup() {
    cleanup_test_env
  }

  Before 'setup'
  After 'cleanup'

  Describe 'Basic execution'
    It 'should run script successfully with minimal input'
      touch test.txt
      echo "test content" > test.txt
      When run script "$SHELLSPEC_PROJECT_ROOT/src/process_txt_files.zsh" "smoke_trigger"
      The status should be success
      The output should include "Processing complete!"
    End
  End

  Describe 'File content processing'
    It 'should process single txt file with trigger prepending'
      touch test.txt
      echo "original content" > test.txt
      
      When run script "$SHELLSPEC_PROJECT_ROOT/src/process_txt_files.zsh" "trigger"
      The contents of file test.txt should equal "trigger, original content"
      The status should be success
  The output should include "Using provided trigger word: trigger"
  The output should include "Loading tag aliases from:"
  The output should match pattern "*Loaded * active tag aliases*"
      The stdout should include "Processing text files with trigger: trigger"
      The stdout should include "Processing: test.txt"
      The stdout should include "Processing complete!"
    End

    It 'should handle empty content files'
      touch empty.txt
      echo "" > empty.txt
      
      When run script "$SHELLSPEC_PROJECT_ROOT/src/process_txt_files.zsh" "solo"
      The contents of file empty.txt should equal "solo"
      The status should be success
  The output should include "Using provided trigger word: solo"
  The output should include "Loading tag aliases from:"
  The output should match pattern "*Loaded * active tag aliases*"
      The stdout should include "Processing text files with trigger: solo"
      The stdout should include "Processing: empty.txt"
      The stdout should include "Processing complete!"
    End

    It 'should remove virtual_youtuber tag'
      touch test.txt
      echo "hair, virtual_youtuber, eyes" > test.txt
      
      When run script "$SHELLSPEC_PROJECT_ROOT/src/process_txt_files.zsh" "character"
      The contents of file test.txt should equal "character, hair, eyes"
      The status should be success
  The output should include "Using provided trigger word: character"
  The output should include "Loading tag aliases from:"
  The output should match pattern "*Loaded * active tag aliases*"
      The stdout should include "Processing text files with trigger: character"
      The stdout should include "Processing: test.txt"
      The stdout should include "Processing complete!"
    End

    It 'should process multiple files'
      touch file1.txt file2.txt
      echo "content1" > file1.txt
      echo "content2" > file2.txt
      
      When run script "$SHELLSPEC_PROJECT_ROOT/src/process_txt_files.zsh" "prefix"
      The contents of file file1.txt should equal "prefix, content1"
      The contents of file file2.txt should equal "prefix, content2"
      The status should be success
  The output should include "Using provided trigger word: prefix"
  The output should include "Loading tag aliases from:"
  The output should match pattern "*Loaded * active tag aliases*"
      The stdout should include "Processing text files with trigger: prefix"
      The stdout should include "Processing: file1.txt"
      The stdout should include "Processing: file2.txt"
      The stdout should include "Processing complete!"
    End
  End
End
