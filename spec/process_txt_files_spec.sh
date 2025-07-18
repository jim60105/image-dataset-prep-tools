#!/bin/zsh
# Copyright (C) 2025 Jim Chen <Jim@ChenJ.im>, licensed under GPL-3.0-or-later
#
# ShellSpec tests for process_txt_files.zsh

Describe 'process_txt_files.zsh'

  setup() {
    setup_test_env
  }

  cleanup() {
    cleanup_test_env
  }

  Before 'setup'
  After 'cleanup'

  Describe 'User input handling'
    Context 'when user provides trigger word'
      It 'should accept and use the trigger word'
        echo "test_trigger" > /tmp/test_input
        touch test.txt
        echo "some tags" > test.txt
        
        # Mock read command to return our test input
        read() { cat /tmp/test_input; }
        
        When run source "$SHELLSPEC_PROJECT_ROOT/process_txt_files.zsh" < /tmp/test_input
        The output should include "Processing text files with trigger: test_trigger"
      End

      It 'should process files with the provided trigger'
        echo "anime_character" > /tmp/test_input
        touch test.txt
        echo "original content" > test.txt
        
        read() { cat /tmp/test_input; }
        
        When run source "$SHELLSPEC_PROJECT_ROOT/process_txt_files.zsh" < /tmp/test_input
        The contents of file test.txt should equal "1girl, anime_character, original content"
      End
    End
  End

  Describe 'Text content processing'
    Context 'bracket replacement'
      It 'should replace ( with \('
        echo "test_trigger" > /tmp/test_input
        touch test.txt
        echo "tags with (parentheses) content" > test.txt
        
        read() { cat /tmp/test_input; }
        
        When run source "$SHELLSPEC_PROJECT_ROOT/process_txt_files.zsh" < /tmp/test_input
        The contents of file test.txt should include "\("
        The contents of file test.txt should include "\)"
      End

      It 'should handle multiple parentheses correctly'
        echo "test_trigger" > /tmp/test_input
        touch test.txt
        echo "text (with) (multiple) (parentheses)" > test.txt
        
        read() { cat /tmp/test_input; }
        
        When run source "$SHELLSPEC_PROJECT_ROOT/process_txt_files.zsh" < /tmp/test_input
        The contents of file test.txt should equal "1girl, test_trigger, text \\(with\\) \\(multiple\\) \\(parentheses\\)"
      End
    End

    Context 'keyword removal'
      It 'should remove existing "1girl" keyword'
        echo "character" > /tmp/test_input
        touch test.txt
        echo "1girl, long hair, blue eyes" > test.txt
        
        read() { cat /tmp/test_input; }
        
        When run source "$SHELLSPEC_PROJECT_ROOT/process_txt_files.zsh" < /tmp/test_input
        The contents of file test.txt should equal "1girl, character, long hair, blue eyes"
      End

      It 'should remove the trigger keyword from content'
        echo "anime_girl" > /tmp/test_input
        touch test.txt
        echo "anime_girl, long hair, anime_girl, blue eyes" > test.txt
        
        read() { cat /tmp/test_input; }
        
        When run source "$SHELLSPEC_PROJECT_ROOT/process_txt_files.zsh" < /tmp/test_input
        The contents of file test.txt should equal "1girl, anime_girl, long hair, blue eyes"
      End

      It 'should remove commentary-related tags'
        echo "character" > /tmp/test_input
        touch test.txt
        echo "character, hair, commentary, eyes, english_commentary" > test.txt
        
        read() { cat /tmp/test_input; }
        
        When run source "$SHELLSPEC_PROJECT_ROOT/process_txt_files.zsh" < /tmp/test_input
        The contents of file test.txt should equal "1girl, character, hair, eyes"
      End

      It 'should remove commission-related tags'
        echo "character" > /tmp/test_input
        touch test.txt
        echo "character, hair, commission, eyes, artist_commission" > test.txt
        
        read() { cat /tmp/test_input; }
        
        When run source "$SHELLSPEC_PROJECT_ROOT/process_txt_files.zsh" < /tmp/test_input
        The contents of file test.txt should equal "1girl, character, hair, eyes"
      End

      It 'should remove virtual_youtuber tag'
        echo "vtuber" > /tmp/test_input
        touch test.txt
        echo "vtuber, hair, virtual_youtuber, eyes" > test.txt
        
        read() { cat /tmp/test_input; }
        
        When run source "$SHELLSPEC_PROJECT_ROOT/process_txt_files.zsh" < /tmp/test_input
        The contents of file test.txt should equal "1girl, vtuber, hair, eyes"
      End

      It 'should remove (;) pattern'
        echo "character" > /tmp/test_input
        touch test.txt
        echo "character, hair, (;), eyes" > test.txt
        
        read() { cat /tmp/test_input; }
        
        When run source "$SHELLSPEC_PROJECT_ROOT/process_txt_files.zsh" < /tmp/test_input
        The contents of file test.txt should equal "1girl, character, hair, eyes"
      End
    End

    Context 'comma and space cleanup'
      It 'should clean up multiple consecutive commas'
        echo "character" > /tmp/test_input
        touch test.txt
        echo "character,, hair,, eyes" > test.txt
        
        read() { cat /tmp/test_input; }
        
        When run source "$SHELLSPEC_PROJECT_ROOT/process_txt_files.zsh" < /tmp/test_input
        The contents of file test.txt should equal "1girl, character, hair, eyes"
      End

      It 'should clean up comma-space-comma patterns'
        echo "character" > /tmp/test_input
        touch test.txt
        echo "character, , hair, , eyes" > test.txt
        
        read() { cat /tmp/test_input; }
        
        When run source "$SHELLSPEC_PROJECT_ROOT/process_txt_files.zsh" < /tmp/test_input
        The contents of file test.txt should equal "1girl, character, hair, eyes"
      End

      It 'should remove leading commas and spaces'
        echo "character" > /tmp/test_input
        touch test.txt
        echo ", , hair, eyes" > test.txt
        
        read() { cat /tmp/test_input; }
        
        When run source "$SHELLSPEC_PROJECT_ROOT/process_txt_files.zsh" < /tmp/test_input
        The contents of file test.txt should equal "1girl, character, hair, eyes"
      End

      It 'should remove trailing commas and spaces'
        echo "character" > /tmp/test_input
        touch test.txt
        echo "hair, eyes, , " > test.txt
        
        read() { cat /tmp/test_input; }
        
        When run source "$SHELLSPEC_PROJECT_ROOT/process_txt_files.zsh" < /tmp/test_input
        The contents of file test.txt should equal "1girl, character, hair, eyes"
      End
    End

    Context 'trigger word prepending'
      It 'should prepend "1girl, {trigger}" to content'
        echo "anime_character" > /tmp/test_input
        touch test.txt
        echo "long hair, blue eyes" > test.txt
        
        read() { cat /tmp/test_input; }
        
        When run source "$SHELLSPEC_PROJECT_ROOT/process_txt_files.zsh" < /tmp/test_input
        The contents of file test.txt should equal "1girl, anime_character, long hair, blue eyes"
      End

      It 'should handle empty content correctly'
        echo "solo_character" > /tmp/test_input
        touch empty.txt
        echo "" > empty.txt
        
        read() { cat /tmp/test_input; }
        
        When run source "$SHELLSPEC_PROJECT_ROOT/process_txt_files.zsh" < /tmp/test_input
        The contents of file empty.txt should equal "1girl, solo_character"
      End

      It 'should handle whitespace-only content'
        echo "character" > /tmp/test_input
        touch whitespace.txt
        echo "   " > whitespace.txt
        
        read() { cat /tmp/test_input; }
        
        When run source "$SHELLSPEC_PROJECT_ROOT/process_txt_files.zsh" < /tmp/test_input
        The contents of file whitespace.txt should equal "1girl, character"
      End
    End
  End

  Describe 'File processing'
    Context 'batch processing'
      It 'should process all .txt files in directory'
        echo "test_character" > /tmp/test_input
        touch file1.txt file2.txt file3.txt
        echo "content1" > file1.txt
        echo "content2" > file2.txt
        echo "content3" > file3.txt
        
        read() { cat /tmp/test_input; }
        
        When run source "$SHELLSPEC_PROJECT_ROOT/process_txt_files.zsh" < /tmp/test_input
        The output should include "Processing: file1.txt"
        The output should include "Processing: file2.txt"
        The output should include "Processing: file3.txt"
        The contents of file file1.txt should equal "1girl, test_character, content1"
        The contents of file file2.txt should equal "1girl, test_character, content2"
        The contents of file file3.txt should equal "1girl, test_character, content3"
      End

      It 'should skip non-txt files'
        echo "character" > /tmp/test_input
        touch test.txt test.jpg test.png test.md
        echo "text content" > test.txt
        echo "image data" > test.jpg
        
        read() { cat /tmp/test_input; }
        
        When run source "$SHELLSPEC_PROJECT_ROOT/process_txt_files.zsh" < /tmp/test_input
        The output should include "Processing: test.txt"
        The output should not include "Processing: test.jpg"
        The output should not include "Processing: test.png"
        The output should not include "Processing: test.md"
      End

      It 'should complete successfully when no txt files exist'
        echo "character" > /tmp/test_input
        touch test.jpg test.png
        
        read() { cat /tmp/test_input; }
        
        When run source "$SHELLSPEC_PROJECT_ROOT/process_txt_files.zsh" < /tmp/test_input
        The output should include "Processing complete!"
        The status should be success
      End
    End

    Context 'file existence checks'
      It 'should only process existing files'
        echo "character" > /tmp/test_input
        touch existing.txt
        echo "content" > existing.txt
        
        read() { cat /tmp/test_input; }
        
        When run source "$SHELLSPEC_PROJECT_ROOT/process_txt_files.zsh" < /tmp/test_input
        The output should include "Processing: existing.txt"
      End

      It 'should handle symbolic links correctly'
        echo "character" > /tmp/test_input
        touch original.txt
        echo "original content" > original.txt
        ln -s original.txt linked.txt
        
        read() { cat /tmp/test_input; }
        
        When run source "$SHELLSPEC_PROJECT_ROOT/process_txt_files.zsh" < /tmp/test_input
        The output should include "Processing: original.txt"
        The output should include "Processing: linked.txt"
      End
    End
  End

  Describe 'Complex content scenarios'
    Context 'realistic tag processing'
      It 'should handle complex anime tags correctly'
        echo "hatsune_miku" > /tmp/test_input
        touch complex.txt
        echo "1girl, hatsune_miku, long hair, twintails, aqua hair, virtual_youtuber, commentary, (high quality), commission" > complex.txt
        
        read() { cat /tmp/test_input; }
        
        When run source "$SHELLSPEC_PROJECT_ROOT/process_txt_files.zsh" < /tmp/test_input
        The contents of file complex.txt should equal "1girl, hatsune_miku, long hair, twintails, aqua hair, \\(high quality\\)"
      End

      It 'should preserve important tags while removing noise'
        echo "anime_girl" > /tmp/test_input
        touch preserve.txt
        echo "anime_girl, detailed, high resolution, commentary_request, artist_commission, beautiful, (masterpiece)" > preserve.txt
        
        read() { cat /tmp/test_input; }
        
        When run source "$SHELLSPEC_PROJECT_ROOT/process_txt_files.zsh" < /tmp/test_input
        The contents of file preserve.txt should equal "1girl, anime_girl, detailed, high resolution, beautiful, \\(masterpiece\\)"
      End

      It 'should handle mixed case and special characters'
        echo "Special_Character" > /tmp/test_input
        touch special.txt
        echo "Special_Character, UPPERCASE, lowercase, under_score, (special), commentary" > special.txt
        
        read() { cat /tmp/test_input; }
        
        When run source "$SHELLSPEC_PROJECT_ROOT/process_txt_files.zsh" < /tmp/test_input
        The contents of file special.txt should equal "1girl, Special_Character, UPPERCASE, lowercase, under_score, \\(special\\)"
      End
    End

    Context 'edge cases'
      It 'should handle files with only trigger word'
        echo "solo_trigger" > /tmp/test_input
        touch trigger_only.txt
        echo "solo_trigger" > trigger_only.txt
        
        read() { cat /tmp/test_input; }
        
        When run source "$SHELLSPEC_PROJECT_ROOT/process_txt_files.zsh" < /tmp/test_input
        The contents of file trigger_only.txt should equal "1girl, solo_trigger"
      End

      It 'should handle files with only 1girl'
        echo "character" > /tmp/test_input
        touch girl_only.txt
        echo "1girl" > girl_only.txt
        
        read() { cat /tmp/test_input; }
        
        When run source "$SHELLSPEC_PROJECT_ROOT/process_txt_files.zsh" < /tmp/test_input
        The contents of file girl_only.txt should equal "1girl, character"
      End

      It 'should handle files with only noise tags'
        echo "clean_character" > /tmp/test_input
        touch noise_only.txt
        echo "commentary, commission, virtual_youtuber" > noise_only.txt
        
        read() { cat /tmp/test_input; }
        
        When run source "$SHELLSPEC_PROJECT_ROOT/process_txt_files.zsh" < /tmp/test_input
        The contents of file noise_only.txt should equal "1girl, clean_character"
      End
    End
  End

  Describe 'Progress and completion messages'
    It 'should show trigger word being used'
      echo "test_trigger" > /tmp/test_input
      touch dummy.txt
      echo "content" > dummy.txt
      
      read() { cat /tmp/test_input; }
      
      When run source "$SHELLSPEC_PROJECT_ROOT/process_txt_files.zsh" < /tmp/test_input
      The output should include "Processing text files with trigger: test_trigger"
    End

    It 'should show processing completion message'
      echo "character" > /tmp/test_input
      touch test.txt
      echo "content" > test.txt
      
      read() { cat /tmp/test_input; }
      
      When run source "$SHELLSPEC_PROJECT_ROOT/process_txt_files.zsh" < /tmp/test_input
      The output should include "Processing complete!"
    End

    It 'should show individual file processing'
      echo "character" > /tmp/test_input
      touch individual.txt
      echo "content" > individual.txt
      
      read() { cat /tmp/test_input; }
      
      When run source "$SHELLSPEC_PROJECT_ROOT/process_txt_files.zsh" < /tmp/test_input
      The output should include "Processing: individual.txt"
    End
  End

  Describe 'File output format'
    It 'should not add extra newlines to output'
      echo "character" > /tmp/test_input
      touch no_newline.txt
      echo "content without newline" > no_newline.txt
      
      read() { cat /tmp/test_input; }
      
      When run source "$SHELLSPEC_PROJECT_ROOT/process_txt_files.zsh" < /tmp/test_input
      # Use wc to check that there are no trailing newlines
      The result of "wc -l < no_newline.txt" should equal "0"
    End

    It 'should preserve single-line format'
      echo "character" > /tmp/test_input
      touch single_line.txt
      echo "tag1, tag2, tag3" > single_line.txt
      
      read() { cat /tmp/test_input; }
      
      When run source "$SHELLSPEC_PROJECT_ROOT/process_txt_files.zsh" < /tmp/test_input
      The contents of file single_line.txt should equal "1girl, character, tag1, tag2, tag3"
      The result of "wc -l < single_line.txt" should equal "0"
    End
  End
End