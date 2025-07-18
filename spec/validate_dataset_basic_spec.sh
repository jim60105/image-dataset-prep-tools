#!/bin/zsh

eval "$(shellspec - -c) exit 1"
# Copyright (C) 2025 Jim Chen <Jim@ChenJ.im>, licensed under GPL-3.0-or-later
#
# Basic tests for validate_dataset.zsh to verify syntax and fundamental functionality

Describe 'validate_dataset.zsh basic functionality'
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
      When call zsh -n "$SHELLSPEC_PROJECT_ROOT/validate_dataset.zsh"
      The status should be success
    End

    It 'should handle script execution without parameters'
      When call zsh "$SHELLSPEC_PROJECT_ROOT/validate_dataset.zsh"
      The status should be success
      The output should include "Dataset validation complete"
    End
  End

  Describe 'Basic dataset validation'
    It 'should validate empty directory without errors'
      When call zsh "$SHELLSPEC_PROJECT_ROOT/validate_dataset.zsh"
      The status should be success
      The output should include "Dataset validation complete"
    End

    It 'should detect and report missing txt files'
      touch image1.jpg image2.png
      
      When call zsh "$SHELLSPEC_PROJECT_ROOT/validate_dataset.zsh"
      The status should be success
      The output should include "Missing .txt file for image: image1.jpg"
      The output should include "Missing .txt file for image: image2.png"
    End

    It 'should detect and report orphaned txt files'
      echo "test content" > orphan1.txt
      echo "test content" > orphan2.txt
      
      When call zsh "$SHELLSPEC_PROJECT_ROOT/validate_dataset.zsh"
      The status should be success
      The output should include "Orphaned .txt file (no corresponding image): orphan1.txt"
      The output should include "Orphaned .txt file (no corresponding image): orphan2.txt"
    End
  End

  Describe 'Trigger word parameter handling'
    It 'should accept trigger word as parameter'
      echo "1girl, character, test" > test.txt
      touch test.jpg
      
      When call zsh "$SHELLSPEC_PROJECT_ROOT/validate_dataset.zsh" "character"
      The status should be success
      The output should include "Using provided trigger word: character"
    End

    It 'should work without trigger word parameter'
      echo "1girl, test content" > test.txt
      touch test.jpg
      
      When call zsh "$SHELLSPEC_PROJECT_ROOT/validate_dataset.zsh"
      The status should be success
      The output should include "Dataset validation complete"
    End
  End

  Describe 'File format support'
    It 'should support jpg files'
      echo "test content" > test.txt
      touch test.jpg
      
      When call zsh "$SHELLSPEC_PROJECT_ROOT/validate_dataset.zsh"
      The status should be success
      The output should include "Dataset validation complete"
    End

    It 'should support png files'
      echo "test content" > test.txt
      touch test.png
      
      When call zsh "$SHELLSPEC_PROJECT_ROOT/validate_dataset.zsh"
      The status should be success
      The output should include "Dataset validation complete"
    End

    It 'should ignore non-image files'
      echo "test content" > test.txt
      touch test.bmp test.gif test.doc
      
      When call zsh "$SHELLSPEC_PROJECT_ROOT/validate_dataset.zsh"
      The status should be success
      The output should include "Orphaned .txt files"
      The output should include "test.txt"
    End
  End
End
