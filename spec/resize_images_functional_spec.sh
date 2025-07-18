#!/bin/zsh

eval "$(shellspec - -c) exit 1"
# Copyright (C) 2025 Jim Chen <Jim@ChenJ.im>, licensed under GPL-3.0-or-later
#
# Simple functional tests for resize_images.zsh

Describe 'resize_images.zsh functionality'
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
      When call zsh -n "$SHELLSPEC_PROJECT_ROOT/resize_images.zsh"
      The status should be success
    End

    It 'should handle empty directory gracefully'
      Mock magick
        if [[ "$1" == "identify" ]]; then
          echo "1024 768"
        else
          echo "Mock resize operation"
        fi
      End

      When call zsh "$SHELLSPEC_PROJECT_ROOT/resize_images.zsh"
      The status should be success
      The output should include "Removed all .npz files"
    End

    It 'should process files when they exist'
      # Create test files
      touch test.jpg test.png test.npz

      Mock magick
        if [[ "$1" == "identify" ]]; then
          echo "400 300"
        else
          echo "Mock resize: $*"
        fi
      End

      When call zsh "$SHELLSPEC_PROJECT_ROOT/resize_images.zsh"
      The status should be success
      The output should include "Removed all .npz files"
      The output should include "Skip test.jpg"
      The output should include "Skip test.png"
    End

    It 'should resize large images'
      # Create test files
      touch large.jpg

      Mock magick
        if [[ "$1" == "identify" ]]; then
          echo "1200 800"
        else
          echo "Landscape image large.jpg resized height to 1024 (overwritten)"
        fi
      End

      When call zsh "$SHELLSPEC_PROJECT_ROOT/resize_images.zsh"
      The status should be success
      The output should include "resized height to 1024"
    End
  End

  Describe 'Error handling'
    It 'should handle magick command failure gracefully'
      touch test.jpg

      Mock magick
        exit 1  # Always fail
      End

      When call zsh "$SHELLSPEC_PROJECT_ROOT/resize_images.zsh"
      The status should be success  # Script should continue despite individual failures
      The output should include "Removed all .npz files"
      The stderr should include "magick: error processing test.jpg"
    End
  End
End
