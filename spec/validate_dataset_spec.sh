#!/bin/zsh
# Copyright (C) 2025 Jim Chen <Jim@ChenJ.im>, licensed under GPL-3.0-or-later
#
# ShellSpec tests for validate_dataset.zsh

Describe 'validate_dataset.zsh'

  setup() {
    setup_test_env
    # Source mocks
    source "$SHELLSPEC_PROJECT_ROOT/spec/support/mocks/imagemagick_mock.sh"
    source "$SHELLSPEC_PROJECT_ROOT/spec/support/mocks/czkawka_mock.sh"
  }

  cleanup() {
    cleanup_test_env
  }

  Before 'setup'
  After 'cleanup'

  Describe 'Parameter handling and trigger word detection'
    Context 'single parameter mode'
      It 'should accept provided trigger word as parameter'
        touch test.jpg test.txt
        echo "provided_trigger, tag1, tag2, tag3, tag4" > test.txt
        
        # Mock commands
        identify() { echo "1024 768"; }
        czkawka_cli() { echo "Found 0 images which have similar friends" > "$4"; return 0; }
        
        When run source "$SHELLSPEC_PROJECT_ROOT/validate_dataset.zsh" "provided_trigger"
        The output should include "Using provided trigger word: provided_trigger"
      End

      It 'should validate files using provided trigger word'
        touch test.jpg test.txt
        echo "my_trigger, tag1, tag2, tag3, tag4" > test.txt
        
        identify() { echo "1024 768"; }
        czkawka_cli() { echo "Found 0 images which have similar friends" > "$4"; return 0; }
        
        When run source "$SHELLSPEC_PROJECT_ROOT/validate_dataset.zsh" "my_trigger"
        The output should not include "ERROR: Trigger word 'my_trigger' not found"
      End
    End

    Context 'auto-detection from path'
      It 'should extract trigger from directory path pattern'
        # Create a subdirectory to test path extraction
        mkdir -p "5_TestCharacter" && cd "5_TestCharacter"
        touch test.jpg test.txt
        echo "TestCharacter, tag1, tag2, tag3, tag4" > test.txt
        
        identify() { echo "1024 768"; }
        czkawka_cli() { echo "Found 0 images which have similar friends" > "$4"; return 0; }
        
        When run source "$SHELLSPEC_PROJECT_ROOT/validate_dataset.zsh"
        The output should include "Auto-detected trigger word from path: TestCharacter"
      End

      It 'should handle complex path patterns'
        mkdir -p "1_idol 1girl" && cd "1_idol 1girl"
        touch test.jpg test.txt
        echo "1girl, idol, tag1, tag2, tag3" > test.txt
        
        identify() { echo "1024 768"; }
        czkawka_cli() { echo "Found 0 images which have similar friends" > "$4"; return 0; }
        
        When run source "$SHELLSPEC_PROJECT_ROOT/validate_dataset.zsh"
        The output should include "Auto-detected trigger word from path: 1girl, idol"
      End
    End

    Context 'interactive input mode'
      It 'should prompt for trigger word when auto-detection fails'
        # Use a directory name that won't auto-detect  
        mkdir -p "test_dir" && cd "test_dir"
        touch test.jpg test.txt
        echo "manual_trigger, tag1, tag2, tag3, tag4" > test.txt
        echo "manual_trigger" > /tmp/trigger_input
        
        identify() { echo "1024 768"; }
        czkawka_cli() { echo "Found 0 images which have similar friends" > "$4"; return 0; }
        read() { cat /tmp/trigger_input; }
        
        When run source "$SHELLSPEC_PROJECT_ROOT/validate_dataset.zsh" < /tmp/trigger_input
        The output should include "Could not auto-detect trigger word"
        The output should include "Using provided trigger word: manual_trigger"
      End
    End

    Context 'error handling for parameters'
      It 'should reject too many parameters'
        When run source "$SHELLSPEC_PROJECT_ROOT/validate_dataset.zsh" "param1" "param2" "param3"
        The status should not be success
        The output should include "Too many parameters"
      End

      It 'should handle empty trigger word'
        echo "" > /tmp/empty_trigger
        read() { cat /tmp/empty_trigger; }
        
        When run source "$SHELLSPEC_PROJECT_ROOT/validate_dataset.zsh" < /tmp/empty_trigger
        The status should not be success
        The output should include "No trigger word provided"
      End
    End
  End

  Describe 'Image file validation'
    Context 'missing txt files'
      It 'should detect images without corresponding txt files'
        touch image1.jpg image2.png
        # No txt files created
        
        identify() { echo "1024 768"; }
        czkawka_cli() { echo "Found 0 images which have similar friends" > "$4"; return 0; }
        
        When run source "$SHELLSPEC_PROJECT_ROOT/validate_dataset.zsh" "test_trigger"
        The output should include "ERROR: Missing .txt file for image: image1.jpg"
        The output should include "ERROR: Missing .txt file for image: image2.png"
      End

      It 'should count missing txt files correctly'
        touch missing1.jpg missing2.jpg missing3.png
        
        identify() { echo "1024 768"; }
        czkawka_cli() { echo "Found 0 images which have similar friends" > "$4"; return 0; }
        
        When run source "$SHELLSPEC_PROJECT_ROOT/validate_dataset.zsh" "trigger"
        The output should include "Missing .txt files: 3"
      End
    End

    Context 'image dimension validation'
      It 'should check minimum image dimensions'
        touch small.jpg normal.jpg
        echo "trigger, tag1, tag2, tag3, tag4" > small.txt
        echo "trigger, tag1, tag2, tag3, tag4" > normal.txt
        
        identify() {
          case "$3" in
            *small*) echo "400 300" ;;  # Below 500px threshold
            *normal*) echo "1024 768" ;;
          esac
        }
        czkawka_cli() { echo "Found 0 images which have similar friends" > "$4"; return 0; }
        
        When run source "$SHELLSPEC_PROJECT_ROOT/validate_dataset.zsh" "trigger"
        The output should include "WARNING: Image small.jpg has small dimensions: 400x300"
      End

      It 'should handle ImageMagick identify failures'
        touch broken.jpg
        echo "trigger, tag1, tag2, tag3, tag4" > broken.txt
        
        identify() { return 1; }  # Simulate identify failure
        czkawka_cli() { echo "Found 0 images which have similar friends" > "$4"; return 0; }
        
        When run source "$SHELLSPEC_PROJECT_ROOT/validate_dataset.zsh" "trigger"
        The output should include "WARNING: Could not process image: broken.jpg"
      End

      It 'should warn when ImageMagick is not available'
        touch test.jpg
        echo "trigger, tag1, tag2, tag3, tag4" > test.txt
        
        # Mock command not found
        command() { 
          if [[ "$2" == "identify" ]]; then
            return 1  # identify not found
          fi
        }
        czkawka_cli() { echo "Found 0 images which have similar friends" > "$4"; return 0; }
        
        When run source "$SHELLSPEC_PROJECT_ROOT/validate_dataset.zsh" "trigger"
        The output should include "WARNING: ImageMagick not available"
      End
    End
  End

  Describe 'Text file validation'
    Context 'trigger word presence'
      It 'should detect missing trigger words in txt files'
        touch test.jpg
        echo "wrong_trigger, tag1, tag2, tag3, tag4" > test.txt
        
        identify() { echo "1024 768"; }
        czkawka_cli() { echo "Found 0 images which have similar friends" > "$4"; return 0; }
        
        When run source "$SHELLSPEC_PROJECT_ROOT/validate_dataset.zsh" "correct_trigger"
        The output should include "ERROR: Trigger word 'correct_trigger' not found in: test.txt"
      End

      It 'should pass when trigger word is present'
        touch test.jpg
        echo "expected_trigger, tag1, tag2, tag3, tag4" > test.txt
        
        identify() { echo "1024 768"; }
        czkawka_cli() { echo "Found 0 images which have similar friends" > "$4"; return 0; }
        
        When run source "$SHELLSPEC_PROJECT_ROOT/validate_dataset.zsh" "expected_trigger"
        The output should not include "ERROR: Trigger word 'expected_trigger' not found"
      End
    End

    Context 'tag count validation'
      It 'should warn about too few tags'
        touch test.jpg
        echo "trigger, tag1" > test.txt  # Only 2 tags
        
        identify() { echo "1024 768"; }
        czkawka_cli() { echo "Found 0 images which have similar friends" > "$4"; return 0; }
        
        When run source "$SHELLSPEC_PROJECT_ROOT/validate_dataset.zsh" "trigger"
        The output should include "WARNING: Too few tags (2) in file: test.txt"
      End

      It 'should warn about too many tags'
        touch test.jpg
        # Create a file with more than 100 tags
        local many_tags="trigger"
        for i in {1..105}; do
          many_tags="$many_tags, tag$i"
        done
        echo "$many_tags" > test.txt
        
        identify() { echo "1024 768"; }
        czkawka_cli() { echo "Found 0 images which have similar friends" > "$4"; return 0; }
        
        When run source "$SHELLSPEC_PROJECT_ROOT/validate_dataset.zsh" "trigger"
        The output should include "WARNING: Too many tags (106) in file: test.txt"
      End

      It 'should accept appropriate tag counts'
        touch test.jpg
        echo "trigger, tag1, tag2, tag3, tag4, tag5, tag6" > test.txt  # 7 tags - good
        
        identify() { echo "1024 768"; }
        czkawka_cli() { echo "Found 0 images which have similar friends" > "$4"; return 0; }
        
        When run source "$SHELLSPEC_PROJECT_ROOT/validate_dataset.zsh" "trigger"
        The output should not include "Too few tags"
        The output should not include "Too many tags"
      End
    End

    Context 'duplicate tag detection'
      It 'should detect duplicate tags within files'
        touch test.jpg
        echo "trigger, tag1, tag2, tag1, tag3, tag2" > test.txt
        
        identify() { echo "1024 768"; }
        czkawka_cli() { echo "Found 0 images which have similar friends" > "$4"; return 0; }
        
        When run source "$SHELLSPEC_PROJECT_ROOT/validate_dataset.zsh" "trigger"
        The output should include "WARNING: Duplicate tags found in file test.txt: tag1, tag2"
      End

      It 'should handle tags with whitespace correctly'
        touch test.jpg
        echo "trigger, tag1 , tag2,  tag1  , tag3" > test.txt
        
        identify() { echo "1024 768"; }
        czkawka_cli() { echo "Found 0 images which have similar friends" > "$4"; return 0; }
        
        When run source "$SHELLSPEC_PROJECT_ROOT/validate_dataset.zsh" "trigger"
        The output should include "WARNING: Duplicate tags found in file test.txt: tag1"
      End

      It 'should not report duplicates when none exist'
        touch test.jpg
        echo "trigger, tag1, tag2, tag3, tag4, tag5" > test.txt
        
        identify() { echo "1024 768"; }
        czkawka_cli() { echo "Found 0 images which have similar friends" > "$4"; return 0; }
        
        When run source "$SHELLSPEC_PROJECT_ROOT/validate_dataset.zsh" "trigger"
        The output should not include "Duplicate tags found"
      End
    End

    Context 'orphaned txt files'
      It 'should detect txt files without corresponding images'
        echo "trigger, tag1, tag2, tag3, tag4" > orphan1.txt
        echo "trigger, tag1, tag2, tag3, tag4" > orphan2.txt
        # No image files created
        
        czkawka_cli() { echo "Found 0 images which have similar friends" > "$4"; return 0; }
        
        When run source "$SHELLSPEC_PROJECT_ROOT/validate_dataset.zsh" "trigger"
        The output should include "WARNING: Orphaned .txt file (no corresponding image): orphan1.txt"
        The output should include "WARNING: Orphaned .txt file (no corresponding image): orphan2.txt"
      End

      It 'should not report orphans when images exist'
        touch paired.jpg
        echo "trigger, tag1, tag2, tag3, tag4" > paired.txt
        
        identify() { echo "1024 768"; }
        czkawka_cli() { echo "Found 0 images which have similar friends" > "$4"; return 0; }
        
        When run source "$SHELLSPEC_PROJECT_ROOT/validate_dataset.zsh" "trigger"
        The output should not include "Orphaned .txt file"
      End

      It 'should count orphaned files correctly'
        echo "trigger, tag1, tag2, tag3, tag4" > orphan1.txt
        echo "trigger, tag1, tag2, tag3, tag4" > orphan2.txt
        echo "trigger, tag1, tag2, tag3, tag4" > orphan3.txt
        
        czkawka_cli() { echo "Found 0 images which have similar friends" > "$4"; return 0; }
        
        When run source "$SHELLSPEC_PROJECT_ROOT/validate_dataset.zsh" "trigger"
        The output should include "Orphaned .txt files: 3"
      End
    End
  End

  Describe 'Similar image detection with czkawka_cli'
    Context 'when czkawka_cli is available'
      It 'should detect similar images'
        touch similar1.jpg similar2.jpg
        echo "trigger, tag1, tag2, tag3, tag4" > similar1.txt
        echo "trigger, tag1, tag2, tag3, tag4" > similar2.txt
        
        identify() { echo "1024 768"; }
        czkawka_cli() {
          # Mock finding similar images
          local output_file=""
          for arg in "$@"; do
            if [[ "$1" == "--file-to-save" ]]; then
              output_file="$2"
              break
            fi
            shift
          done
          
          if [[ -n "$output_file" ]]; then
            cat > "$output_file" << 'EOF'
Found 2 images which have similar friends

Group 1 (2 images):
"similar1.jpg"
"similar2.jpg"
EOF
          fi
          return 11  # czkawka_cli returns 11 when files found
        }
        
        When run source "$SHELLSPEC_PROJECT_ROOT/validate_dataset.zsh" "trigger"
        The output should include "WARNING: 發現 High 相似度影像群組: similar1.jpg, similar2.jpg"
      End

      It 'should handle no similar images found'
        touch unique1.jpg unique2.jpg
        echo "trigger, tag1, tag2, tag3, tag4" > unique1.txt
        echo "trigger, tag1, tag2, tag3, tag4" > unique2.txt
        
        identify() { echo "1024 768"; }
        czkawka_cli() {
          local output_file=""
          for arg in "$@"; do
            if [[ "$1" == "--file-to-save" ]]; then
              output_file="$2"
              break
            fi
            shift
          done
          
          if [[ -n "$output_file" ]]; then
            echo "Found 0 images which have similar friends" > "$output_file"
          fi
          return 0
        }
        
        When run source "$SHELLSPEC_PROJECT_ROOT/validate_dataset.zsh" "trigger"
        The output should include "未發現相似影像"
      End

      It 'should handle czkawka_cli execution failure'
        touch test.jpg
        echo "trigger, tag1, tag2, tag3, tag4" > test.txt
        
        identify() { echo "1024 768"; }
        czkawka_cli() { return 1; }  # Simulate failure
        
        When run source "$SHELLSPEC_PROJECT_ROOT/validate_dataset.zsh" "trigger"
        The output should include "WARNING: 影像相似度檢查失敗"
      End
    End

    Context 'when czkawka_cli is not available'
      It 'should skip similarity check gracefully'
        touch test.jpg
        echo "trigger, tag1, tag2, tag3, tag4" > test.txt
        
        identify() { echo "1024 768"; }
        command() { 
          if [[ "$2" == "czkawka_cli" ]]; then
            return 1  # Not available
          fi
        }
        
        When run source "$SHELLSPEC_PROJECT_ROOT/validate_dataset.zsh" "trigger"
        The output should include "WARNING: czkawka_cli 不可用 - 跳過影像相似度檢查"
      End
    End
  End

  Describe 'Statistics and reporting'
    Context 'basic statistics'
      It 'should count total files correctly'
        touch img1.jpg img2.png img3.jpg
        echo "trigger, tag1, tag2, tag3, tag4" > txt1.txt
        echo "trigger, tag1, tag2, tag3, tag4" > txt2.txt
        # Missing img3.txt and img2.txt, extra orphan.txt
        echo "trigger, tag1, tag2, tag3, tag4" > orphan.txt
        
        identify() { echo "1024 768"; }
        czkawka_cli() { echo "Found 0 images which have similar friends" > "$4"; return 0; }
        
        When run source "$SHELLSPEC_PROJECT_ROOT/validate_dataset.zsh" "trigger"
        The output should include "Total image files: 3"
        The output should include "Total text files: 3"
      End

      It 'should provide complete error and warning counts'
        touch img1.jpg small.jpg
        echo "wrong_trigger, tag1, tag2, tag3, tag4" > img1.txt  # Wrong trigger
        echo "trigger, few" > small.txt  # Too few tags
        echo "trigger, tag1, tag2, tag3, tag4" > orphan.txt  # Orphaned
        
        identify() { 
          case "$3" in
            *small*) echo "400 300" ;;  # Small image
            *) echo "1024 768" ;;
          esac
        }
        czkawka_cli() { echo "Found 0 images which have similar friends" > "$4"; return 0; }
        
        When run source "$SHELLSPEC_PROJECT_ROOT/validate_dataset.zsh" "trigger"
        The output should include "Total errors:"
        The output should include "Total warnings:"
      End
    End

    Context 'completion status'
      It 'should report success when no issues found'
        touch perfect.jpg
        echo "trigger, tag1, tag2, tag3, tag4, tag5" > perfect.txt
        
        identify() { echo "1024 768"; }
        czkawka_cli() { echo "Found 0 images which have similar friends" > "$4"; return 0; }
        
        When run source "$SHELLSPEC_PROJECT_ROOT/validate_dataset.zsh" "trigger"
        The output should include "✅ Dataset validation completed successfully - no issues found!"
      End

      It 'should report warnings only when appropriate'
        touch warning_test.jpg
        echo "trigger, few" > warning_test.txt  # Too few tags - warning only
        
        identify() { echo "1024 768"; }
        czkawka_cli() { echo "Found 0 images which have similar friends" > "$4"; return 0; }
        
        When run source "$SHELLSPEC_PROJECT_ROOT/validate_dataset.zsh" "trigger"
        The output should include "✅ Dataset validation completed with warnings only."
      End

      It 'should report errors when present'
        touch error_test.jpg
        # No txt file - this creates an error
        
        identify() { echo "1024 768"; }
        czkawka_cli() { echo "Found 0 images which have similar friends" > "$4"; return 0; }
        
        When run source "$SHELLSPEC_PROJECT_ROOT/validate_dataset.zsh" "trigger"
        The output should include "❌ Dataset validation completed with errors that need to be fixed."
      End
    End

    Context 'detailed problem reporting'
      It 'should list all errors in detail'
        touch missing_txt.jpg
        touch has_txt.jpg
        echo "wrong_trigger, tag1, tag2, tag3, tag4" > has_txt.txt
        
        identify() { echo "1024 768"; }
        czkawka_cli() { echo "Found 0 images which have similar friends" > "$4"; return 0; }
        
        When run source "$SHELLSPEC_PROJECT_ROOT/validate_dataset.zsh" "correct_trigger"
        The output should include "ERRORS ("
        The output should include "Missing .txt file for image: missing_txt.jpg"
        The output should include "Trigger word 'correct_trigger' not found in: has_txt.txt"
      End

      It 'should list all warnings in detail'
        touch small.jpg duplicate.jpg
        echo "trigger, tag1, tag2" > small.txt  # Too few tags
        echo "trigger, tag1, tag2, tag1, tag3" > duplicate.txt  # Duplicates
        echo "trigger, tag1, tag2, tag3, tag4" > orphan.txt  # Orphaned
        
        identify() {
          case "$3" in
            *small*) echo "400 300" ;;  # Small image
            *) echo "1024 768" ;;
          esac
        }
        czkawka_cli() { echo "Found 0 images which have similar friends" > "$4"; return 0; }
        
        When run source "$SHELLSPEC_PROJECT_ROOT/validate_dataset.zsh" "trigger"
        The output should include "WARNINGS ("
        The output should include "Too few tags"
        The output should include "Duplicate tags found"
        The output should include "Orphaned .txt file"
        The output should include "small dimensions"
      End
    End
  End

  Describe 'Color-coded output'
    Context 'error messages'
      It 'should use red color for errors'
        touch error_test.jpg
        # Missing txt file creates error
        
        identify() { echo "1024 768"; }
        czkawka_cli() { echo "Found 0 images which have similar friends" > "$4"; return 0; }
        
        When run source "$SHELLSPEC_PROJECT_ROOT/validate_dataset.zsh" "trigger"
        The output should include "ERROR:"
        # Note: Testing color codes in ShellSpec is complex, mainly test that error prefix appears
      End
    End

    Context 'warning messages'
      It 'should use yellow color for warnings'
        touch warning_test.jpg
        echo "trigger, few" > warning_test.txt
        
        identify() { echo "1024 768"; }
        czkawka_cli() { echo "Found 0 images which have similar friends" > "$4"; return 0; }
        
        When run source "$SHELLSPEC_PROJECT_ROOT/validate_dataset.zsh" "trigger"
        The output should include "WARNING:"
      End
    End
  End

  Describe 'Edge cases and robustness'
    Context 'empty directories'
      It 'should handle directories with no files gracefully'
        czkawka_cli() { echo "Found 0 images which have similar friends" > "$4"; return 0; }
        
        When run source "$SHELLSPEC_PROJECT_ROOT/validate_dataset.zsh" "trigger"
        The output should include "Total image files: 0"
        The output should include "Total text files: 0"
        The status should be success
      End
    End

    Context 'mixed file scenarios'
      It 'should handle complex mixed scenarios correctly'
        # Complete pair
        touch good.jpg
        echo "trigger, tag1, tag2, tag3, tag4, tag5" > good.txt
        
        # Missing txt
        touch missing_txt.jpg
        
        # Orphaned txt
        echo "trigger, tag1, tag2, tag3, tag4" > orphan.txt
        
        # Small image with few tags
        touch small.jpg
        echo "trigger, few" > small.txt
        
        # Duplicate tags
        touch dup.jpg
        echo "trigger, tag1, tag2, tag1, tag3" > dup.txt
        
        identify() {
          case "$3" in
            *small*) echo "400 300" ;;
            *) echo "1024 768" ;;
          esac
        }
        czkawka_cli() { echo "Found 0 images which have similar friends" > "$4"; return 0; }
        
        When run source "$SHELLSPEC_PROJECT_ROOT/validate_dataset.zsh" "trigger"
        The output should include "Total image files: 4"
        The output should include "Total text files: 4"
        The output should include "Missing .txt files: 1"
        The output should include "Orphaned .txt files: 1"
        The output should include "Files with duplicate tags: 1"
      End
    End
  End
End