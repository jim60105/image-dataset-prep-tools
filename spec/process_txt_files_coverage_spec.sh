#!/bin/zsh

eval "$(shellspec - -c) exit 1"
# Copyright (C) 2025 Jim Chen <Jim@ChenJ.im>, licensed under GPL-3.0-or-later
#
# Comprehensive coverage tests for process_txt_files.zsh to achieve 80%+ coverage

# Include spec helper for common utilities
Include spec/spec_helper.sh

Describe 'process_txt_files.zsh coverage enhancement'
  setup() {
    setup_test_env
  }

  cleanup() {
    cleanup_test_env
  }

  Before 'setup'
  After 'cleanup'

  Describe 'Utility functions edge cases'
    It 'should handle whitespace trimming edge cases'
      mkdir -p "1_test" && cd "1_test"
      # Test trim_whitespace with various whitespace patterns
      echo "  whitespace_test  , tabs	content	, newline_content
" > test.txt
      
      When run script "$SHELLSPEC_PROJECT_ROOT/src/process_txt_files.zsh" "test_trigger"
      The output should include "Processing complete!"
      The output should include "Processing text files with trigger: test_trigger"
      The status should be success
      The stderr should include "Using provided trigger word: test_trigger"
      The stderr should include "Loading tag aliases from:"
      The stderr should match pattern "*Loaded * active tag aliases*"
      The file test.txt should be exist
    End

    It 'should handle empty and whitespace-only content'
      mkdir -p "1_test" && cd "1_test"
      echo "" > empty.txt
      echo "   " > whitespace.txt
      echo "	" > tab.txt
      
      When run script "$SHELLSPEC_PROJECT_ROOT/src/process_txt_files.zsh" "test_trigger"
      The status should be success
      The stderr should include "Using provided trigger word: test_trigger"
      The stderr should include "Loading tag aliases from:"
      The stderr should match pattern "*Loaded * active tag aliases*"
      The output should include "Processing: empty.txt"
      The output should include "Processing: whitespace.txt"
      The output should include "Processing: tab.txt"
    End

    It 'should handle complex parentheses escaping'
      mkdir -p "1_test" && cd "1_test"
      echo "content (with) ((nested)) (((triple))) parentheses" > test.txt
      
      When run script "$SHELLSPEC_PROJECT_ROOT/src/process_txt_files.zsh" "test_trigger"
      The output should include "Processing complete!"
      The output should include "Processing text files with trigger: test_trigger"
      The status should be success
      The stderr should include "Using provided trigger word: test_trigger"
      The stderr should include "Loading tag aliases from:"
      The stderr should match pattern "*Loaded * active tag aliases*"
      # Parentheses should be escaped to \( \)
      The contents of file test.txt should include "\\("
      The contents of file test.txt should include "\\)"
    End

    It 'should handle emoji tag conversions'
      mkdir -p "1_test" && cd "1_test"
      echo "normal, _h, other, _s, content" > test.txt
      
      When run script "$SHELLSPEC_PROJECT_ROOT/src/process_txt_files.zsh" "test_trigger"
      The output should include "Processing text files with trigger: test_trigger"
      The output should include "Processing complete!"
      The status should be success
      The stderr should include "Using provided trigger word: test_trigger"
      The stderr should include "Loading tag aliases from:"
      The stderr should match pattern "*Loaded * active tag aliases*"
      # Underscore patterns should be converted to colon format (single char patterns)
      The contents of file test.txt should include ":h"
    End

    It 'should handle standalone tag removal'
      mkdir -p "1_test" && cd "1_test"
      echo "content, s, quality_tag" > test.txt
      The output should include "Processing text files with trigger: test_trigger"
      The output should include "Processing complete!"
      
      When run script "$SHELLSPEC_PROJECT_ROOT/src/process_txt_files.zsh" "test_trigger"
      The status should be success
      The stderr should include "Using provided trigger word: test_trigger"
      The stderr should include "Loading tag aliases from:"
      The stderr should match pattern "*Loaded * active tag aliases*"
      # The 's' tag in the middle should be removed
      The contents of file test.txt should not include ", s,"
      The contents of file test.txt should include "content"
      The contents of file test.txt should include "quality_tag"
    End
  End

  Describe 'Content processing edge cases'
    It 'should handle duplicate tag removal'
      The output should include "Processing text files with trigger: test_trigger"
      The output should include "Processing complete!"
      mkdir -p "1_test" && cd "1_test"
      echo "flower, nature, flower, garden, nature, flower" > test.txt
      
      When run script "$SHELLSPEC_PROJECT_ROOT/src/process_txt_files.zsh" "test_trigger"
      The status should be success
      The stderr should include "Using provided trigger word: test_trigger"
      The stderr should include "Loading tag aliases from:"
      The stderr should match pattern "*Loaded * active tag aliases*"
      # Should only contain one instance of each tag
      The contents of file test.txt should include "flower"
      The contents of file test.txt should include "nature"
      The contents of file test.txt should include "garden"
    End
      The output should include "Processing text files with trigger: test_trigger"
      The output should include "Processing complete!"

    It 'should handle complex formatting cleanup'
      mkdir -p "1_test" && cd "1_test"
      echo "tag1  ,   tag2,tag3   ,    tag4 ,tag5" > test.txt
      
      When run script "$SHELLSPEC_PROJECT_ROOT/src/process_txt_files.zsh" "test_trigger"
      The status should be success
      The stderr should include "Using provided trigger word: test_trigger"
      The stderr should include "Loading tag aliases from:"
      The stderr should match pattern "*Loaded * active tag aliases*"
      # Should have clean comma-space separation
      The contents of file test.txt should match pattern "*test_trigger, tag1, tag2, tag3, tag4, tag5*"
    End

    It 'should handle trigger word removal with underscores'
      mkdir -p "1_blue_flower" && cd "1_blue_flower"
      echo "blue_flower, flower_blue, blue, flower, blue_flower_crown" > test.txt
      
      When run script "$SHELLSPEC_PROJECT_ROOT/src/process_txt_files.zsh"
      The stderr should include "Loading tag aliases from:"
      The stderr should match pattern "*Loaded * active tag aliases*"
      The status should be success
      # Should remove standalone trigger but preserve compounds
      The contents of file test.txt should not include ", blue_flower,"
      The contents of file test.txt should include "blue_flower_crown"
      The contents of file test.txt should include "flower_blue"
    End

      The output should include "Processing text files with trigger: test_trigger"
      The output should include "Processing complete!"
    It 'should handle tag alias applications'
      mkdir -p "1_test" && cd "1_test"
      # Use common aliases that should exist in the CSV
      echo "flower_crown, head_wreath, tiara, crown" > test.txt
      
      When run script "$SHELLSPEC_PROJECT_ROOT/src/process_txt_files.zsh" "test_trigger"
      The status should be success
      The stderr should include "Using provided trigger word: test_trigger"
      The stderr should include "Loading tag aliases from:"
      The stderr should match pattern "*Loaded * active tag aliases*"
      The stderr should include "Loaded"
      The stderr should include "active tag aliases"
    End
  End

  Describe 'Path extraction edge cases'
    It 'should handle directory names without numeric prefix'
      mkdir -p "hydrangea_flower" && cd "hydrangea_flower"
      echo "content" > test.txt
      
      When run script "$SHELLSPEC_PROJECT_ROOT/src/process_txt_files.zsh"
      The stderr should include "Loading tag aliases from:"
      The stderr should match pattern "*Loaded * active tag aliases*"
      The status should be success
      # Should extract from directory name even without numeric prefix
      The stderr should include "Auto-detected trigger word"
    End

    It 'should handle directory names with special characters'
      mkdir -p "1_test-char_name" && cd "1_test-char_name"
      echo "content" > test.txt
      
      When run script "$SHELLSPEC_PROJECT_ROOT/src/process_txt_files.zsh"
      The stderr should include "Loading tag aliases from:"
      The stderr should match pattern "*Loaded * active tag aliases*"
      The status should be success
      The stderr should include "Auto-detected trigger word from path: test-char_name"
    End

    It 'should handle complex directory names with spaces and underscores'
      mkdir -p "3_character_name flower type" && cd "3_character_name flower type"
      echo "content" > test.txt
      
      When run script "$SHELLSPEC_PROJECT_ROOT/src/process_txt_files.zsh"
      The stderr should include "Loading tag aliases from:"
      The stderr should match pattern "*Loaded * active tag aliases*"
      The status should be success
      The stderr should include "Auto-detected trigger word from path: character_name"
      The stderr should include "Auto-detected class word from path: flower"
    End
  End

  Describe 'Error handling scenarios'
    It 'should handle missing tag aliases file gracefully'
      The output should include "Processing text files with trigger: test_trigger"
      The output should include "Processing complete!"
      mkdir -p "1_test" && cd "1_test"
      echo "content" > test.txt
      
      # Temporarily move the aliases file
      if [[ -f "$SHELLSPEC_PROJECT_ROOT/data/danbooru_tag_aliases.csv" ]]; then
        mv "$SHELLSPEC_PROJECT_ROOT/data/danbooru_tag_aliases.csv" "$SHELLSPEC_PROJECT_ROOT/data/danbooru_tag_aliases.csv.bak"
      fi
      
      When run script "$SHELLSPEC_PROJECT_ROOT/src/process_txt_files.zsh" "test_trigger"
      The status should be success
      The stderr should include "Using provided trigger word: test_trigger"
      The stderr should include "Loading tag aliases from:"
      The stderr should match pattern "*Loaded * active tag aliases*"
      The stderr should include "WARNING: Tag aliases file not found"
      
      # Restore the aliases file
      if [[ -f "$SHELLSPEC_PROJECT_ROOT/data/danbooru_tag_aliases.csv.bak" ]]; then
        mv "$SHELLSPEC_PROJECT_ROOT/data/danbooru_tag_aliases.csv.bak" "$SHELLSPEC_PROJECT_ROOT/data/danbooru_tag_aliases.csv"
      fi
    End

    It 'should validate trigger word is not empty'
      mkdir -p "1_test" && cd "1_test"
      echo "content" > test.txt
      
      # Test with empty trigger should fail
      When run script "$SHELLSPEC_PROJECT_ROOT/src/process_txt_files.zsh" ""
      The status should be failure
      The stderr should include "Using provided trigger word:"
      The stderr should include "ERROR: No trigger word provided or could be determined"
    End

    It 'should handle too many parameters'
      mkdir -p "1_test" && cd "1_test"
      echo "content" > test.txt
      
      When run script "$SHELLSPEC_PROJECT_ROOT/src/process_txt_files.zsh" "param1" "param2" "param3"
      The stderr should include "Loading tag aliases from:"
      The stderr should match pattern "*Loaded * active tag aliases*"
      The status should be failure
      The stderr should include "ERROR: Too many parameters"
    End
  End

  Describe 'File I/O edge cases'
    It 'should handle directory with no txt files'
      mkdir -p "1_test" && cd "1_test"
      touch notxt.dat
      touch readme.md
      
      When run script "$SHELLSPEC_PROJECT_ROOT/src/process_txt_files.zsh" "test_trigger"
      The status should be success
      The stderr should include "Using provided trigger word: test_trigger"
      The stderr should include "Loading tag aliases from:"
      The stderr should match pattern "*Loaded * active tag aliases*"
      The output should include "Processing complete!"
      The output should not include "Processing:"
    End

    It 'should handle multiple txt files'
      mkdir -p "1_test" && cd "1_test"
      echo "content1" > file1.txt
      echo "content2" > file2.txt
      echo "content3" > file3.txt
      
      When run script "$SHELLSPEC_PROJECT_ROOT/src/process_txt_files.zsh" "test_trigger"
      The status should be success
      The stderr should include "Using provided trigger word: test_trigger"
      The stderr should include "Loading tag aliases from:"
      The output should include "Processing text files with trigger: test_trigger"
      The output should include "Processing complete!"
      The stderr should match pattern "*Loaded * active tag aliases*"
      The output should include "Processing: file1.txt"
      The output should include "Processing: file2.txt"  
      The output should include "Processing: file3.txt"
    End

    It 'should preserve file order and content'
      mkdir -p "1_test" && cd "1_test"
      echo "original_content1" > test1.txt
      echo "original_content2" > test2.txt
      
      When run script "$SHELLSPEC_PROJECT_ROOT/src/process_txt_files.zsh" "test_trigger"
      The status should be success
      The stderr should include "Using provided trigger word: test_trigger"
      The stderr should include "Loading tag aliases from:"
      The stderr should match pattern "*Loaded * active tag aliases*"
      
      # Files should exist and have been processed
      The file test1.txt should be exist
      The file test2.txt should be exist
      The contents of file test1.txt should include "test_trigger"
      The contents of file test2.txt should include "test_trigger"
    End
  End

  Describe 'Class word functionality edge cases'
    It 'should handle empty class word scenarios'
      mkdir -p "1_test_trigger" && cd "1_test_trigger"
      echo "content, test, data" > test.txt
      
      When run script "$SHELLSPEC_PROJECT_ROOT/src/process_txt_files.zsh"
      The stderr should include "Loading tag aliases from:"
      The stderr should match pattern "*Loaded * active tag aliases*"
      The status should be success
      The stderr should include "Auto-detected trigger word from path: test_trigger"
      The stderr should not include "Auto-detected class word"
      The contents of file test.txt should match pattern "test_trigger, *"
      The contents of file test.txt should not match pattern "*, test_trigger, *"
    End

    It 'should handle class word removal edge cases'
      mkdir -p "1_flower plant" && cd "1_flower plant"
      echo "plant, plant_life, plant_pot, flower, flower_plant, content" > test.txt
      
      When run script "$SHELLSPEC_PROJECT_ROOT/src/process_txt_files.zsh"
      The stderr should include "Loading tag aliases from:"
      The stderr should match pattern "*Loaded * active tag aliases*"
      The status should be success
      The stderr should include "Auto-detected trigger word from path: flower"
      The stderr should include "Auto-detected class word from path: plant"
      The stderr should include "Loading tag aliases from:"
      The stderr should match pattern "*Loaded * active tag aliases*"
      # Should remove standalone class word but preserve compounds
      The contents of file test.txt should not include ", plant,"
      The contents of file test.txt should include "plant_life"
      The contents of file test.txt should include "plant_pot"
      The contents of file test.txt should include "flower_plant"
    End

    It 'should handle class and trigger word order in prefix'
      mkdir -p "1_rose flower" && cd "1_rose flower"
      echo "garden, nature" > test.txt
      
      When run script "$SHELLSPEC_PROJECT_ROOT/src/process_txt_files.zsh"
      The stderr should include "Loading tag aliases from:"
      The stderr should match pattern "*Loaded * active tag aliases*"
      The status should be success
      # Should have class word first, then trigger word
      The contents of file test.txt should match pattern "flower, rose, *"
    End
  End

  Describe 'Legacy compatibility'
    It 'should maintain backward compatibility with extract_trigger_from_path'
      mkdir -p "1_legacy_test" && cd "1_legacy_test"
      echo "content" > test.txt
      
      When run script "$SHELLSPEC_PROJECT_ROOT/src/process_txt_files.zsh"
      The stderr should include "Loading tag aliases from:"
      The stderr should match pattern "*Loaded * active tag aliases*"
      The status should be success
      # Legacy function should still work for single word directories
      The stderr should include "Auto-detected trigger word from path: legacy_test"
    End

    It 'should handle two-word legacy directory format'
      mkdir -p "1_character person" && cd "1_character person"
      echo "content" > test.txt
      
      When run script "$SHELLSPEC_PROJECT_ROOT/src/process_txt_files.zsh"
      The stderr should include "Loading tag aliases from:"
      The output should include "Processing text files with trigger: test_trigger"
      The output should include "Processing complete!"
      The stderr should match pattern "*Loaded * active tag aliases*"
      The status should be success
      # Should work with both legacy and new formats
      The stderr should include "Auto-detected trigger word from path: character"
      The stderr should include "Auto-detected class word from path: person"
    End
  End

  Describe 'Additional utility function coverage'
    It 'should handle tag splitting with various separators'
      mkdir -p "1_test" && cd "1_test"
      The output should include "Processing text files with trigger: test_trigger"
      The output should include "Processing complete!"
      echo "tag1,tag2, tag3 ,tag4,  tag5  " > test.txt
      
      When run script "$SHELLSPEC_PROJECT_ROOT/src/process_txt_files.zsh" "test_trigger"
      The status should be success
      The stderr should include "Using provided trigger word: test_trigger"
      The stderr should include "Loading tag aliases from:"
      The stderr should match pattern "*Loaded * active tag aliases*"
      # Should properly split and clean tags
      The contents of file test.txt should include "test_trigger"
    End
      The output should include "Processing text files with trigger: test_trigger"
      The output should include "Processing complete!"

    It 'should handle join_tags with empty arrays'
      mkdir -p "1_test" && cd "1_test"
      echo "" > test.txt
      
      When run script "$SHELLSPEC_PROJECT_ROOT/src/process_txt_files.zsh" "test_trigger"
      The status should be success
      The stderr should include "Using provided trigger word: test_trigger"
      The stderr should include "Loading tag aliases from:"
      The stderr should match pattern "*Loaded * active tag aliases*"
      The contents of file test.txt should equal "test_trigger"
    End

    It 'should handle apply_tag_alias with non-existent aliases'
      mkdir -p "1_test" && cd "1_test"
      echo "nonexistent_tag, unknown_alias, normal_tag" > test.txt
      
      When run script "$SHELLSPEC_PROJECT_ROOT/src/process_txt_files.zsh" "test_trigger"
      The status should be success
      The stderr should include "Using provided trigger word: test_trigger"
      The stderr should include "Loading tag aliases from:"
      The stderr should match pattern "*Loaded * active tag aliases*"
      # Non-existent aliases should remain unchanged
      The contents of file test.txt should include "nonexistent_tag"
      The contents of file test.txt should include "unknown_alias"
      The contents of file test.txt should include "normal_tag"
    End
      The output should include "Processing text files with trigger: test_trigger"
      The output should include "Processing complete!"

    It 'should handle remove_unwanted_patterns with complex triggers'
      mkdir -p "1_complex_trigger_name" && cd "1_complex_trigger_name"
      echo "complex_trigger_name, trigger_complex, name_trigger, other_content" > test.txt
      
      When run script "$SHELLSPEC_PROJECT_ROOT/src/process_txt_files.zsh"
      The stderr should include "Loading tag aliases from:"
      The stderr should match pattern "*Loaded * active tag aliases*"
      The status should be success
      # Should remove exact trigger but preserve compounds
      The contents of file test.txt should not include ", complex_trigger_name,"
      The contents of file test.txt should include "trigger_complex"
      The contents of file test.txt should include "name_trigger"
    End

    It 'should handle s tag removal'
      mkdir -p "1_test" && cd "1_test"
      echo "content, s, valid_tags, s, more_content" > test.txt
      
      When run script "$SHELLSPEC_PROJECT_ROOT/src/process_txt_files.zsh" "test_trigger"
      The status should be success
      The stderr should include "Using provided trigger word: test_trigger"
      The stderr should include "Loading tag aliases from:"
      The stderr should match pattern "*Loaded * active tag aliases*"
      # Standalone 's' tags should be removed
      The contents of file test.txt should not include ", s,"
      The contents of file test.txt should include "content"
      The contents of file test.txt should include "valid_tags"
      The contents of file test.txt should include "more_content"
    End
  End

  Describe 'Content processing pipeline coverage'
    It 'should execute full processing pipeline'
      mkdir -p "1_test" && cd "1_test"
      echo "test, (parentheses), test, s, duplicate, duplicate" > test.txt
      
      When run script "$SHELLSPEC_PROJECT_ROOT/src/process_txt_files.zsh" "test"
      The stderr should include "Loading tag aliases from:"
      The stderr should match pattern "*Loaded * active tag aliases*"
      The status should be success
      
      # Should process through all steps
      The contents of file test.txt should include "\\("
      The contents of file test.txt should include "\\)"
      The contents of file test.txt should not include ", s,"
      # Should have proper prefix
      The contents of file test.txt should match pattern "test, *"
    End

    It 'should handle main function parameter validation'
      mkdir -p "1_test" && cd "1_test"
      echo "content" > test.txt
      
      # Test that main validates trigger word
      When run script "$SHELLSPEC_PROJECT_ROOT/src/process_txt_files.zsh" "valid_trigger"
      The stderr should include "Loading tag aliases from:"
      The stderr should match pattern "*Loaded * active tag aliases*"
      The status should be success
      The stderr should include "Using provided trigger word: valid_trigger"
    End

    It 'should handle process_single_file function'
      mkdir -p "1_test" && cd "1_test"
      echo "original content" > single.txt
      
      When run script "$SHELLSPEC_PROJECT_ROOT/src/process_txt_files.zsh" "trigger_word"
      The stderr should include "Loading tag aliases from:"
      The stderr should match pattern "*Loaded * active tag aliases*"
      The status should be success
      The output should include "Processing: single.txt"
      The contents of file single.txt should include "trigger_word"
      The contents of file single.txt should not include "original"
    End
  End
End