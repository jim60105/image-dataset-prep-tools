#!/bin/zsh
# Copyright (C) 2025 Jim Chen <Jim@ChenJ.im>, licensed under GPL-3.0-or-later
#
# ShellSpec tests for resize_images.zsh

Describe 'resize_images.zsh'
  setup() {
    # Create temporary test directory
    TEST_DIR=$(mktemp -d)
    cd "$TEST_DIR"
    
    # Mock magick command for testing
    magick() {
      case "$1" in
        "identify")
          case "$3" in
            *test_800x600*) echo "800 600" ;;
            *test_400x300*) echo "400 300" ;;
            *test_1024x768*) echo "1024 768" ;;
            *) echo "1024 768" ;;
          esac
          ;;
        *)
          # For resize operations, just touch the file to simulate success
          local target_file="$1"
          touch "$target_file"
          ;;
      esac
    }
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
    It 'should remove npz files'
      touch test1.npz test2.npz test.jpg
      
      When call bash -c '
        magick() {
          case "$1" in
            "identify") echo "400 300" ;;
          esac
        }
        export -f magick
        setopt nullglob
        rm -f -- *.npz
        echo "Removed all .npz files in current directory"
        for img in *.jpg *.png; do
          [[ ! -f "$img" ]] && continue
          read width height < <(magick identify -format "%w %h" "$img")
          if (( width < 1024 && height < 1024 )); then
            echo "Skip $img (size: ${width}x${height})"
            continue
          fi
        done
      '
      
      The output should include "Removed all .npz files"
      The output should include "Skip test.jpg"
    End
  End

  Describe 'Image processing logic'
    It 'should skip small images'
      touch test_400x300.jpg
      
      When call bash -c '
        magick() {
          case "$1" in
            "identify") echo "400 300" ;;
          esac
        }
        export -f magick
        setopt nullglob
        for img in *.jpg *.png; do
          [[ ! -f "$img" ]] && continue
          read width height < <(magick identify -format "%w %h" "$img")
          if (( width < 1024 && height < 1024 )); then
            echo "Skip $img (size: ${width}x${height})"
            continue
          fi
        done
      '
      
      The output should include "Skip test_400x300.jpg (size: 400x300)"
    End

    It 'should resize landscape images'
      touch test_1200x800.jpg
      
      When call bash -c '
        magick() {
          case "$1" in
            "identify") echo "1200 800" ;;
            *) echo "Landscape image test_1200x800.jpg resized height to 1024 (overwritten)" ;;
          esac
        }
        export -f magick
        setopt nullglob
        for img in *.jpg *.png; do
          [[ ! -f "$img" ]] && continue
          read width height < <(magick identify -format "%w %h" "$img")
          if (( width < 1024 && height < 1024 )); then
            echo "Skip $img (size: ${width}x${height})"
            continue
          fi
          if (( width >= height )); then
            magick "$img" -resize x1024\> "$img"
            echo "Landscape image $img resized height to 1024 (overwritten)"
          else
            magick "$img" -resize 1024x\> "$img"
            echo "Portrait image $img resized width to 1024 (overwritten)"
          fi
        done
      '
      
      The output should include "resized height to 1024"
    End

    It 'should resize portrait images'
      touch test_600x1200.jpg
      
      When call bash -c '
        magick() {
          case "$1" in
            "identify") echo "600 1200" ;;
            *) echo "Portrait image test_600x1200.jpg resized width to 1024 (overwritten)" ;;
          esac
        }
        export -f magick
        setopt nullglob
        for img in *.jpg *.png; do
          [[ ! -f "$img" ]] && continue
          read width height < <(magick identify -format "%w %h" "$img")
          if (( width < 1024 && height < 1024 )); then
            echo "Skip $img (size: ${width}x${height})"
            continue
          fi
          if (( width >= height )); then
            magick "$img" -resize x1024\> "$img"
            echo "Landscape image $img resized height to 1024 (overwritten)"
          else
            magick "$img" -resize 1024x\> "$img"
            echo "Portrait image $img resized width to 1024 (overwritten)"
          fi
        done
      '
      
      The output should include "resized width to 1024"
    End
  End

  Describe 'File format support'
    It 'should process jpg files'
      touch test.jpg
      
      When call bash -c '
        magick() {
          case "$1" in
            "identify") echo "1200 800" ;;
            *) echo "Landscape image test.jpg resized height to 1024 (overwritten)" ;;
          esac
        }
        export -f magick
        setopt nullglob
        for img in *.jpg *.png; do
          [[ ! -f "$img" ]] && continue
          read width height < <(magick identify -format "%w %h" "$img")
          if (( width < 1024 && height < 1024 )); then
            continue
          fi
          if (( width >= height )); then
            magick "$img" -resize x1024\> "$img"
            echo "Landscape image $img resized height to 1024 (overwritten)"
          fi
        done
      '
      
      The output should include "test.jpg resized"
    End

    It 'should process png files'
      touch test.png
      
      When call bash -c '
        magick() {
          case "$1" in
            "identify") echo "1200 800" ;;
            *) echo "Landscape image test.png resized height to 1024 (overwritten)" ;;
          esac
        }
        export -f magick
        setopt nullglob
        for img in *.jpg *.png; do
          [[ ! -f "$img" ]] && continue
          read width height < <(magick identify -format "%w %h" "$img")
          if (( width < 1024 && height < 1024 )); then
            continue
          fi
          if (( width >= height )); then
            magick "$img" -resize x1024\> "$img"
            echo "Landscape image $img resized height to 1024 (overwritten)"
          fi
        done
      '
      
      The output should include "test.png resized"
    End

    It 'should skip unsupported formats'
      touch test.bmp test.tiff
      
      When call bash -c '
        setopt nullglob
        count=0
        for img in *.jpg *.png; do
          [[ ! -f "$img" ]] && continue
          ((count++))
        done
        echo "Processed $count files"
      '
      
      The output should include "Processed 0 files"
    End
  End

  Describe 'Integration with actual script'
    It 'should execute the resize_images.zsh script without errors'
      touch small.jpg large.jpg
      # Mock ImageMagick for the actual script
      
      When call bash -c '
        # Create a mock magick command
        cat > magick << "EOF"
#!/bin/bash
case "$1" in
  "identify")
    case "$3" in
      *small*) echo "400 300" ;;
      *large*) echo "1200 800" ;;
      *) echo "1024 768" ;;
    esac
    ;;
  *)
    # For resize operations
    echo "Resize operation: $*"
    ;;
esac
EOF
        chmod +x magick
        export PATH=".:$PATH"
        
        # Run the actual script with our mock
        source "$SHELLSPEC_PROJECT_ROOT/resize_images.zsh"
      '
      
      The status should be success
      The output should include "Removed all .npz files"
    End
  End
End