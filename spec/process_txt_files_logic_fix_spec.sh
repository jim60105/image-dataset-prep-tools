#!/bin/zsh

eval "$(shellspec - -c) exit 1"
# Copyright (C) 2025 Jim Chen <Jim@ChenJ.im>, licensed under GPL-3.0-or-later
#
# Tests for trigger word logic fixes in process_txt_files.zsh

Describe 'process_txt_files.zsh trigger word logic fix'
  Include spec/spec_helper.sh

  setup() {
    setup_test_env
  }

  cleanup() {
    cleanup_test_env
  }

  Before 'setup'
  After 'cleanup'

  Describe 'Trigger word extraction from path'
    It 'should extract compound trigger word from blue_flower directory'
      mkdir -p 3_blue_flower && cd 3_blue_flower
      echo "blue_flower, nature, garden, flower_crown" > test.txt
      
      When run script "$SHELLSPEC_PROJECT_ROOT/src/process_txt_files.zsh"
      The status should be success
  The output should include "Auto-detected trigger word from path: blue_flower"
      The output should include "Processing complete!"
    End

    It 'should extract compound trigger word from green_apple directory'
      mkdir -p 2_green_apple && cd 2_green_apple
      echo "green_apple, red_apple, apple_tree" > test.txt
      
      When run script "$SHELLSPEC_PROJECT_ROOT/src/process_txt_files.zsh"
      The status should be success
  The output should include "Auto-detected trigger word from path: green_apple"
      The output should include "Processing complete!"
    End
  End

  Describe 'Compound word preservation in content processing'
    It 'should preserve compound words containing trigger word'
      echo "blue_flower, flower_crown, sunflower, blue_dress, garden" > test.txt
      
      When run script "$SHELLSPEC_PROJECT_ROOT/src/process_txt_files.zsh" "flower"
      The status should be success
  The output should include "Using provided trigger word: flower"
      The output should include "Processing complete!"
      
      # Check that compound words are preserved (accounting for tag aliases)
      # flower_crown becomes head_wreath due to alias, but sunflower should be preserved
      The contents of file test.txt should include "sunflower"
      The contents of file test.txt should include "blue_flower"
      # These should NOT exist because they would indicate the trigger was incorrectly removed from compounds
      The contents of file test.txt should not include ", blue_,"
      The contents of file test.txt should not include "blue_, "
      The contents of file test.txt should not include ", _crown"
      The contents of file test.txt should not include "_crown, "
      The contents of file test.txt should not include ", sun,"
      The contents of file test.txt should not include "sun, "
    End

    It 'should remove standalone trigger word but preserve compounds'
      echo "apple, green_apple, red_apple, apple_tree, apple_sauce" > test.txt
      
      When run script "$SHELLSPEC_PROJECT_ROOT/src/process_txt_files.zsh" "apple"
      The status should be success
  The output should include "Using provided trigger word: apple"
      The output should include "Processing complete!"
      
      # For debugging - let's first check the actual content
      The file test.txt should be present
      
      # Check that compounds preserved (accounting for red_apple -> apple alias)
      The contents of file test.txt should start with "apple, green_apple"
      The contents of file test.txt should include "green_apple"
      The contents of file test.txt should include "apple_tree"
      The contents of file test.txt should include "apple_sauce"
    End
  End

  Describe 'Edge cases'
    It 'should handle multiple underscores in directory names'
      mkdir -p 1_my_special_character && cd 1_my_special_character
      echo "my_special_character, other_tags" > test.txt
      
      When run script "$SHELLSPEC_PROJECT_ROOT/src/process_txt_files.zsh"
      The status should be success
  The output should include "Auto-detected trigger word from path: my_special_character"
      The output should include "Processing complete!"
    End

    It 'should handle trigger word at different positions'
      echo "tag1, trigger_word, tag2, word_trigger, trigger_suffix, prefix_trigger" > test.txt
      
      When run script "$SHELLSPEC_PROJECT_ROOT/src/process_txt_files.zsh" "trigger"
      The status should be success
  The output should include "Using provided trigger word: trigger"
      The output should include "Processing complete!"
      
      # Check boundary matching
      The contents of file test.txt should include "trigger_word"
      The contents of file test.txt should include "word_trigger" 
      The contents of file test.txt should include "trigger_suffix"
      The contents of file test.txt should include "prefix_trigger"
    End
  End
End
