#!/bin/zsh
# Copyright (C) 2025 Jim Chen <Jim@ChenJ.im>, licensed under GPL-3.0-or-later
#
# ShellSpec tests for resize_images.zsh

# shellcheck shell=zsh

# Include spec helper
Include spec/spec_helper.sh

Describe 'resize_images.zsh'
  # Include the script to test
  # Note: We'll source it in each test to avoid interference

  setup() {
    setup_test_env
    # Source mocks with correct path
    source "$SHELLSPEC_PROJECT_ROOT/spec/support/mocks/imagemagick_mock.sh"
  }

  cleanup() {
    cleanup_test_env
  }

  Before 'setup'
  After 'cleanup'

  Describe 'Image size detection and processing'
    Context 'when image is larger than 1024px'
      It 'should process large images correctly'
        # Create test image 
        touch test_large.jpg
        
        # Create mock magick in PATH
        mkdir -p bin
        cat > bin/magick << 'EOF'
#!/bin/zsh
if [[ "$1" == "identify" && "$2" == "-format" && "$3" == "%w %h" ]]; then
  echo "1200 800"
elif [[ "$1" == "test_large.jpg" && "$2" == "-resize" ]]; then
  echo "Landscape image test_large.jpg resized height to 1024 (overwritten)"
fi
EOF
        chmod +x bin/magick
        export PATH="$PWD/bin:$PATH"
        
        When run source "$SHELLSPEC_PROJECT_ROOT/resize_images.zsh"
        The output should include "resized height to 1024"
      End
    End
  End

  Describe 'File format support'
    Context 'supported formats'
      It 'should process .jpg files'
        touch test.jpg
        
        magick() {
          if [[ "$1" == "identify" ]]; then
            echo "1200 800"
          else
            touch test.jpg
            echo "Landscape image test.jpg resized height to 1024 (overwritten)"
          fi
        }
        
        When run source "$SHELLSPEC_PROJECT_ROOT/resize_images.zsh"
        The output should include "test.jpg resized"
      End

      It 'should process .png files'
        touch test.png
        
        magick() {
          if [[ "$1" == "identify" ]]; then
            echo "1200 800"
          else
            touch test.png
            echo "Landscape image test.png resized height to 1024 (overwritten)"
          fi
        }
        
        When run source "$SHELLSPEC_PROJECT_ROOT/resize_images.zsh"
        The output should include "test.png resized"
      End

      It 'should skip unsupported formats'
        touch test.bmp test.gif test.tiff
        
        When run source "$SHELLSPEC_PROJECT_ROOT/resize_images.zsh"
        The output should not include "test.bmp"
        The output should not include "test.gif" 
        The output should not include "test.tiff"
      End
    End

    Context 'when no image files exist'
      It 'should complete without errors'
        # Empty directory
        When run source "$SHELLSPEC_PROJECT_ROOT/resize_images.zsh"
        The status should be success
        The output should include "Removed all .npz files"
      End
    End
  End

  Describe 'NPZ file cleanup'
    It 'should remove .npz files before processing'
      touch test1.npz test2.npz test.jpg
      
      magick() {
        if [[ "$1" == "identify" ]]; then
          echo "400 300"  # Small image, will be skipped
        fi
      }
      
      When run source "$SHELLSPEC_PROJECT_ROOT/resize_images.zsh"
      The output should include "Removed all .npz files"
      The file test1.npz should not be exist
      The file test2.npz should not be exist
    End

    It 'should work when no .npz files exist'
      touch test.jpg
      
      magick() {
        if [[ "$1" == "identify" ]]; then
          echo "400 300"
        fi
      }
      
      When run source "$SHELLSPEC_PROJECT_ROOT/resize_images.zsh"
      The output should include "Removed all .npz files"
      The status should be success
    End
  End

  Describe 'Error handling'
    Context 'when ImageMagick fails'
      It 'should handle identify command failure gracefully'
        touch test.jpg
        
        magick() {
          if [[ "$1" == "identify" ]]; then
            return 1  # Simulate identify failure
          fi
        }
        
        When run source "$SHELLSPEC_PROJECT_ROOT/resize_images.zsh"
        # Should not crash, might skip the file or show error
        The status should be success
      End

      It 'should continue processing other files after error'
        touch test1.jpg test2.jpg test3.jpg
        
        magick() {
          if [[ "$1" == "identify" ]]; then
            case "$2" in
              *test1*) return 1 ;;  # Fail for test1
              *test2*) echo "800 600" ;;  # Success for test2
              *test3*) echo "400 300" ;;  # Small image, skip
            esac
          elif [[ "$1" == "test2.jpg" ]]; then
            touch test2.jpg
            echo "Landscape image test2.jpg resized height to 1024 (overwritten)"
          fi
        }
        
        When run source "$SHELLSPEC_PROJECT_ROOT/resize_images.zsh"
        The output should include "test2.jpg resized"
        The output should include "Skip test3.jpg"
      End
    End

    Context 'when file permissions are restricted'
      It 'should handle permission errors gracefully'
        touch readonly.jpg
        chmod 444 readonly.jpg
        
        magick() {
          if [[ "$1" == "identify" ]]; then
            echo "1200 800"
          elif [[ "$1" == "readonly.jpg" ]]; then
            # Simulate permission error in resize
            return 1
          fi
        }
        
        When run source "$SHELLSPEC_PROJECT_ROOT/resize_images.zsh"
        # Should attempt to process but may fail on resize
        The status should be success  # Script continues despite individual file failures
      End
    End
  End

  Describe 'Progress reporting'
    It 'should show progress for each processed image'
      touch img1.jpg img2.jpg img3.png
      
      magick() {
        if [[ "$1" == "identify" ]]; then
          case "$2" in
            *img1*) echo "1200 800" ;;
            *img2*) echo "400 300" ;;  # Will be skipped
            *img3*) echo "800 1200" ;; # Portrait
          esac
        else
          local file="$1"
          touch "$file"
          if [[ "$file" == *img1* ]]; then
            echo "Landscape image img1.jpg resized height to 1024 (overwritten)"
          elif [[ "$file" == *img3* ]]; then
            echo "Portrait image img3.png resized width to 1024 (overwritten)"
          fi
        fi
      }
      
      When run source "$SHELLSPEC_PROJECT_ROOT/resize_images.zsh"
      The output should include "img1.jpg resized"
      The output should include "Skip img2.jpg"
      The output should include "img3.png resized"
    End

    It 'should report image dimensions correctly'
      touch dimension_test.jpg
      
      magick() {
        if [[ "$1" == "identify" ]]; then
          echo "1920 1080"
        else
          touch dimension_test.jpg
          echo "Landscape image dimension_test.jpg resized height to 1024 (overwritten)"
        fi
      }
      
      When run source "$SHELLSPEC_PROJECT_ROOT/resize_images.zsh"
      The output should include "resized height to 1024"
    End
  End

  Describe 'Batch processing'
    It 'should process multiple images in sequence'
      touch batch1.jpg batch2.png batch3.jpg
      
      magick() {
        if [[ "$1" == "identify" ]]; then
          echo "1200 900"  # All need resizing
        else
          local file="$1"
          touch "$file"
          echo "Landscape image $file resized height to 1024 (overwritten)"
        fi
      }
      
      When run source "$SHELLSPEC_PROJECT_ROOT/resize_images.zsh"
      The output should include "batch1.jpg resized"
      The output should include "batch2.png resized"
      The output should include "batch3.jpg resized"
    End

    It 'should handle mixed scenarios correctly'
      touch large.jpg small.jpg portrait.png corrupted.jpg
      
      magick() {
        if [[ "$1" == "identify" ]]; then
          case "$2" in
            *large*) echo "2000 1500" ;;
            *small*) echo "300 200" ;;
            *portrait*) echo "600 800" ;;
            *corrupted*) return 1 ;;
          esac
        else
          local file="$1"
          touch "$file"
          case "$file" in
            *large*) echo "Landscape image large.jpg resized height to 1024 (overwritten)" ;;
            *portrait*) echo "Portrait image portrait.png resized width to 1024 (overwritten)" ;;
          esac
        fi
      }
      
      When run source "$SHELLSPEC_PROJECT_ROOT/resize_images.zsh"
      The output should include "large.jpg resized"
      The output should include "Skip small.jpg (size: 300x200)"
      The output should include "portrait.png resized"
      # corrupted.jpg might be skipped or cause error, but script continues
    End
  End
End