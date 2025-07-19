#!/bin/zsh

eval "$(shellspec - -c) exit 1"
# Copyright (C) 2025 Jim Chen <Jim@ChenJ.im>, licensed under GPL-3.0-or-later
#
# Tests for resize_images.zsh logic fix - issue #12
# Testing the correction from && to || in small image detection

Describe 'resize_images.zsh logic fix'
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

  Describe 'Small image detection logic'
    Context 'Images with any side < 1024px should be skipped'
      It 'should skip 800x600 landscape image'
        touch test_800x600.jpg
        Mock magick
          if [[ "$1" == "identify" ]]; then
            echo "800 600"
          fi
        End
        
        When run script "$SHELLSPEC_PROJECT_ROOT/src/resize_images.zsh"
        The status should be success
        The output should include "Skip test_800x600.jpg"
        The output should not include "resized"
      End

      It 'should skip 1200x800 landscape image'
        touch test_1200x800.jpg
        Mock magick
          if [[ "$1" == "identify" ]]; then
            echo "1200 800"
          fi
        End
        
        When run script "$SHELLSPEC_PROJECT_ROOT/src/resize_images.zsh"
        The status should be success
        The output should include "Skip test_1200x800.jpg"
        The output should not include "resized"
      End

      It 'should skip 600x800 portrait image'
        touch test_600x800.jpg
        Mock magick
          if [[ "$1" == "identify" ]]; then
            echo "600 800"
          fi
        End
        
        When run script "$SHELLSPEC_PROJECT_ROOT/src/resize_images.zsh"
        The status should be success
        The output should include "Skip test_600x800.jpg"
        The output should not include "resized"
      End

      It 'should skip 800x1200 portrait image'
        touch test_800x1200.jpg
        Mock magick
          if [[ "$1" == "identify" ]]; then
            echo "800 1200"
          fi
        End
        
        When run script "$SHELLSPEC_PROJECT_ROOT/src/resize_images.zsh"
        The status should be success
        The output should include "Skip test_800x1200.jpg"
        The output should not include "resized"
      End
    End

    Context 'Images with both sides >= 1024px should be processed'
      It 'should process 1500x1200 landscape image'
        touch test_1500x1200.jpg
        Mock magick
          if [[ "$1" == "identify" ]]; then
            echo "1500 1200"
          elif [[ "$1" == "convert" || "$2" == "-resize" ]]; then
            exit 0
          fi
        End
        
        When run script "$SHELLSPEC_PROJECT_ROOT/src/resize_images.zsh"
        The status should be success
        The output should include "Landscape image test_1500x1200.jpg resized"
        The output should not include "Skip"
      End

      It 'should process 1200x1500 portrait image'
        touch test_1200x1500.jpg
        Mock magick
          if [[ "$1" == "identify" ]]; then
            echo "1200 1500"
          elif [[ "$1" == "convert" || "$2" == "-resize" ]]; then
            exit 0
          fi
        End
        
        When run script "$SHELLSPEC_PROJECT_ROOT/src/resize_images.zsh"
        The status should be success
        The output should include "Portrait image test_1200x1500.jpg resized"
        The output should not include "Skip"
      End
    End

    Context 'Edge cases'
      It 'should skip exactly 1024x800 image'
        touch test_1024x800.jpg
        Mock magick
          if [[ "$1" == "identify" ]]; then
            echo "1024 800"
          fi
        End
        
        When run script "$SHELLSPEC_PROJECT_ROOT/src/resize_images.zsh"
        The status should be success
        The output should include "Skip test_1024x800.jpg"
      End

      It 'should skip exactly 800x1024 image'
        touch test_800x1024.jpg
        Mock magick
          if [[ "$1" == "identify" ]]; then
            echo "800 1024"
          fi
        End
        
        When run script "$SHELLSPEC_PROJECT_ROOT/src/resize_images.zsh"
        The status should be success
        The output should include "Skip test_800x1024.jpg"
      End

      It 'should process exactly 1024x1024 square image'
        touch test_1024x1024.jpg
        Mock magick
          if [[ "$1" == "identify" ]]; then
            echo "1024 1024"
          elif [[ "$1" == "convert" || "$2" == "-resize" ]]; then
            exit 0
          fi
        End
        
        When run script "$SHELLSPEC_PROJECT_ROOT/src/resize_images.zsh"
        The status should be success
        The output should include "resized"
        The output should not include "Skip"
      End
    End
  End
End