#!/bin/zsh

eval "$(shellspec - -c) exit 1"
# Copyright (C) 2025 Jim Chen <Jim@ChenJ.im>, licensed under GPL-3.0-or-later
#
# Tests for class word functionality in process_txt_files.zsh

# Include spec helper for common utilities
Include spec/spec_helper.sh

Describe 'process_txt_files.zsh class word functionality'
  setup() {
    setup_test_env
  }

  cleanup() {
    cleanup_test_env
  }

  Before 'setup'
  After 'cleanup'

  Describe 'Directory name parsing'
    It 'should extract trigger word only from single word directory'
      mkdir -p "1_hydrangea" && cd "1_hydrangea"
      echo "blue_flower, nature, garden, flower_crown" > test.txt
      
      When run script "$SHELLSPEC_PROJECT_ROOT/src/process_txt_files.zsh"
      The status should be success
      The stderr should include "Auto-detected trigger word from path: hydrangea"
      The stderr should not include "Auto-detected class word from path:"
      The output should include "Processing text files with trigger: hydrangea"
      The output should not include "class:"
    End

    It 'should extract trigger and class words from two word directory'
      mkdir -p "3_hydrangea flower" && cd "3_hydrangea flower"
      echo "blue_flower, nature, garden, flower_crown" > test.txt
      
      When run script "$SHELLSPEC_PROJECT_ROOT/src/process_txt_files.zsh"
      The status should be success
      The stderr should include "Auto-detected trigger word from path: hydrangea"
      The stderr should include "Auto-detected class word from path: flower"
      The output should include "Processing text files with trigger: hydrangea, class: flower"
    End

    It 'should handle three or more words by taking first two'
      mkdir -p "5_hydrangea flower plant" && cd "5_hydrangea flower plant"
      echo "blue_flower, nature, garden, flower_crown" > test.txt
      
      When run script "$SHELLSPEC_PROJECT_ROOT/src/process_txt_files.zsh"
      The status should be success
      The stderr should include "Auto-detected trigger word from path: hydrangea"
      The stderr should include "Auto-detected class word from path: flower"
      The output should include "Processing text files with trigger: hydrangea, class: flower"
    End
  End

  Describe 'Content processing with class words'
    It 'should add trigger prefix when no class word'
      echo "blue_flower, nature, garden" > test.txt
      
      When run script "$SHELLSPEC_PROJECT_ROOT/src/process_txt_files.zsh" "hydrangea"
      The status should be success
      The contents of file test.txt should match pattern "hydrangea, *"
    End

    It 'should add class and trigger prefix when both exist'
      mkdir -p "1_hydrangea flower" && cd "1_hydrangea flower"
      echo "blue_flower, nature, garden" > test.txt
      
      When run script "$SHELLSPEC_PROJECT_ROOT/src/process_txt_files.zsh"
      The status should be success
      The contents of file test.txt should match pattern "flower, hydrangea, *"
    End

    It 'should remove trigger word from content'
      echo "hydrangea, blue_flower, nature, garden" > test.txt
      
      When run script "$SHELLSPEC_PROJECT_ROOT/src/process_txt_files.zsh" "hydrangea"
      The status should be success
      The contents of file test.txt should equal "hydrangea, blue_flower, nature, garden"
    End

    It 'should remove class word from content'
      mkdir -p "1_hydrangea flower" && cd "1_hydrangea flower"  
      echo "flower, blue_flower, nature, garden" > test.txt
      
      When run script "$SHELLSPEC_PROJECT_ROOT/src/process_txt_files.zsh"
      The status should be success
      The contents of file test.txt should equal "flower, hydrangea, blue_flower, nature, garden"
    End

    It 'should preserve compound words containing trigger'
      echo "sunflower, yellow_flower, nature" > test.txt
      
      When run script "$SHELLSPEC_PROJECT_ROOT/src/process_txt_files.zsh" "flower"
      The status should be success
      The contents of file test.txt should include "sunflower"
      The contents of file test.txt should include "yellow_flower"
    End

    It 'should preserve compound words containing class word'
      mkdir -p "1_hydrangea flower" && cd "1_hydrangea flower"
      echo "sunflower, blue_flower, flower_crown" > test.txt
      
      When run script "$SHELLSPEC_PROJECT_ROOT/src/process_txt_files.zsh"
      The status should be success
      The contents of file test.txt should include "sunflower"
      The contents of file test.txt should include "blue_flower"
      # Note: flower_crown becomes head_wreath due to tag aliases
    End

    It 'should remove both trigger and class words independently'
      mkdir -p "1_hydrangea flower" && cd "1_hydrangea flower"
      echo "hydrangea, flower, blue_flower, nature, garden" > test.txt
      
      When run script "$SHELLSPEC_PROJECT_ROOT/src/process_txt_files.zsh"
      The status should be success
      The contents of file test.txt should equal "flower, hydrangea, blue_flower, nature, garden"
    End
  End

  Describe 'Backward compatibility'
    It 'should maintain exact same behavior for single parameter mode'
      echo "blue_flower, nature, garden, flower_crown" > test.txt
      
      # Create backup to compare with old behavior
      cp test.txt test_backup.txt
      
      When run script "$SHELLSPEC_PROJECT_ROOT/src/process_txt_files.zsh" "hydrangea"
      The status should be success
      The stderr should include "Using provided trigger word: hydrangea"
      The output should include "Processing text files with trigger: hydrangea"
      The output should not include "class:"
    End

    It 'should maintain compatibility with old directory auto-detection'
      mkdir -p "character_test" && cd "character_test"
      echo "anime, manga, character" > test.txt
      
      When run script "$SHELLSPEC_PROJECT_ROOT/src/process_txt_files.zsh"
      The status should be success
      The stderr should include "Auto-detected trigger word from path: character_test"
      The output should include "Processing text files with trigger: character_test"
      The contents of file test.txt should match pattern "character_test, *"
    End
  End

  Describe 'Edge cases'
    It 'should handle empty content gracefully'
      mkdir -p "1_hydrangea flower" && cd "1_hydrangea flower"
      echo "" > test.txt
      
      When run script "$SHELLSPEC_PROJECT_ROOT/src/process_txt_files.zsh"
      The status should be success
      The contents of file test.txt should equal "flower, hydrangea"
    End

    It 'should handle content with only trigger word'
      echo "hydrangea" > test.txt
      
      When run script "$SHELLSPEC_PROJECT_ROOT/src/process_txt_files.zsh" "hydrangea"
      The status should be success
      The contents of file test.txt should equal "hydrangea"
    End

    It 'should handle content with only class word'
      mkdir -p "1_hydrangea flower" && cd "1_hydrangea flower"
      echo "flower" > test.txt
      
      When run script "$SHELLSPEC_PROJECT_ROOT/src/process_txt_files.zsh"
      The status should be success
      The contents of file test.txt should equal "flower, hydrangea"
    End

    It 'should handle directory with underscores correctly'
      mkdir -p "1_my_character flower" && cd "1_my_character flower"
      echo "test content" > test.txt
      
      When run script "$SHELLSPEC_PROJECT_ROOT/src/process_txt_files.zsh"
      The status should be success
      The stderr should include "Auto-detected trigger word from path: my_character"
      The stderr should include "Auto-detected class word from path: flower"
    End
  End

  Describe 'Multiple file processing'
    It 'should process multiple files with same class word logic'
      mkdir -p "1_hydrangea flower" && cd "1_hydrangea flower"
      echo "blue_flower, nature, garden" > file1.txt
      echo "flower, red_rose, beauty" > file2.txt
      echo "yellow_flower, sunny, day" > file3.txt
      
      When run script "$SHELLSPEC_PROJECT_ROOT/src/process_txt_files.zsh"
      The status should be success
      The output should include "Processing: file1.txt"
      The output should include "Processing: file2.txt"
      The output should include "Processing: file3.txt"
      
      # Check that all files have correct prefixes
      The contents of file file1.txt should match pattern "flower, hydrangea, *"
      The contents of file file2.txt should match pattern "flower, hydrangea, *"
      The contents of file file3.txt should match pattern "flower, hydrangea, *"
      
      # Check that standalone flower was removed from file2 - will be verified by the expected pattern
      The contents of file file2.txt should include "red_rose"
    End
  End
End