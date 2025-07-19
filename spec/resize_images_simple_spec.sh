#!/bin/zsh

eval "$(shellspec - -c) exit 1"
# Copyright (C) 2025 Jim Chen <Jim@ChenJ.im>, licensed under GPL-3.0-or-later
#
# ShellSpec tests for resize_images.zsh

Describe 'resize_images.zsh'
  setup() {
    # Create temporary test directory
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

  Describe 'NPZ file cleanup'
    It 'should remove npz files when script runs'
      # Create test files
      touch test1.npz test2.npz small.jpg
      
      Mock magick
        if [[ "$1" == "identify" ]]; then
          echo "400 300"
        fi
      End

      When run source "$SHELLSPEC_PROJECT_ROOT/src/resize_images.zsh"
      
      The status should be success
      The output should include "Removed all .npz files"
      The output should include "Skip small.jpg"
      The path test1.npz should not be exist
      The path test2.npz should not be exist
    End
  End

  Describe 'Image processing logic'
    It 'should skip small images'
      touch small_image.jpg
      
      Mock magick
        if [[ "$1" == "identify" ]]; then
          echo "400 300"
        fi
      End

      When run source "$SHELLSPEC_PROJECT_ROOT/src/resize_images.zsh"
      
      The status should be success
      The output should include "Skip small_image.jpg (size: 400x300)"
    End

    It 'should resize landscape images'
      touch landscape.jpg
      
      Mock magick
        if [[ "$1" == "identify" ]]; then
          echo "2400 1600"
        elif [[ "$1" == "landscape.jpg" && "$2" == "-resize" ]]; then
          # Simulate successful resize
          return 0
        fi
      End

      When run source "$SHELLSPEC_PROJECT_ROOT/src/resize_images.zsh"
      
      The status should be success
      The output should include "Landscape image landscape.jpg resized height to 1024 (overwritten)"
    End

    It 'should resize portrait images'
      touch portrait.jpg
      
      Mock magick
        if [[ "$1" == "identify" ]]; then
          echo "1200 2400"
        elif [[ "$1" == "portrait.jpg" && "$2" == "-resize" ]]; then
          # Simulate successful resize
          return 0
        fi
      End

      When run source "$SHELLSPEC_PROJECT_ROOT/src/resize_images.zsh"
      
      The status should be success
      The output should include "Portrait image portrait.jpg resized width to 1024 (overwritten)"
    End
  End

  Describe 'File format support'
    It 'should process jpg files'
      touch test.jpg
      
      Mock magick
        if [[ "$1" == "identify" ]]; then
          echo "1200 1200"
        elif [[ "$1" == "test.jpg" && "$2" == "-resize" ]]; then
          return 0
        fi
      End

      When run source "$SHELLSPEC_PROJECT_ROOT/src/resize_images.zsh"
      
      The status should be success
      The output should include "test.jpg resized"
    End

    It 'should process png files'
      touch test.png
      
      Mock magick
        if [[ "$1" == "identify" ]]; then
          echo "1200 1200"
        elif [[ "$1" == "test.png" && "$2" == "-resize" ]]; then
          return 0
        fi
      End

      When run source "$SHELLSPEC_PROJECT_ROOT/src/resize_images.zsh"
      
      The status should be success
      The output should include "test.png resized"
    End

    It 'should skip unsupported formats'
      touch test.bmp test.tiff

      Mock magick
        # No-op mock: magick should not be called for unsupported formats, but mock to avoid command not found
        return 0
      End

      When run source "$SHELLSPEC_PROJECT_ROOT/src/resize_images.zsh"

      The status should be success
      The output should include "Removed all .npz files"
      The output should not include "test.bmp"
      The output should not include "test.tiff"
    End
  End

  Describe 'Error handling'
    It 'should handle missing magick command'
      # Override command builtin to simulate magick not found  
      command() {
        if [[ "$1" == "-v" && "$2" == "magick" ]]; then
          return 1
        fi
        builtin command "$@"
      }

      When run source "$SHELLSPEC_PROJECT_ROOT/src/resize_images.zsh"
      
      The status should be failure
      The output should include "Removed all .npz files"
      The stderr should include "command not found: magick"
    End

    It 'should handle magick identify errors'
      touch error_image.jpg
      
      Mock magick
        if [[ "$1" == "identify" ]]; then
          echo "magick: unable to open image" >&2
          return 1
        fi
      End

      When run source "$SHELLSPEC_PROJECT_ROOT/src/resize_images.zsh"
      
      The status should be success
      The output should include "Removed all .npz files"
      The stderr should include "magick: error processing error_image.jpg"
    End

    It 'should handle magick resize errors'
      touch resize_error.jpg
      
      Mock magick
        if [[ "$1" == "identify" ]]; then
          echo "1200 800"
        elif [[ "$1" == "resize_error.jpg" && "$2" == "-resize" ]]; then
          echo "magick: unable to resize image" >&2
          return 1
        fi
      End

      When run source "$SHELLSPEC_PROJECT_ROOT/src/resize_images.zsh"
      
      The status should be success
      The output should include "Removed all .npz files"
      The stderr should include "magick: error processing resize_error.jpg"
    End
  End

  Describe 'Integration with actual script'
    It 'should execute the resize_images.zsh script without errors'
      touch small.jpg large.jpg
      
      Mock magick
        if [[ "$1" == "identify" ]]; then
          if [[ "$4" == *small* ]]; then
            echo "400 300"
          elif [[ "$4" == *large* ]]; then
            echo "2400 3600"
          else
            echo "1024 768"
          fi
        elif [[ "$2" == "-resize" ]]; then
          # Simulate successful resize
          return 0
        fi
      End

      When run source "$SHELLSPEC_PROJECT_ROOT/src/resize_images.zsh"
      
      The status should be success
      The output should include "Removed all .npz files"
      The output should include "Skip small.jpg"
      The output should include "large.jpg resized"
    End
  End
End
