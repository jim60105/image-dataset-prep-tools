#!/bin/zsh
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
      # Create a mock magick command that does nothing
      mkdir -p bin
      cat > bin/magick << 'EOF'
#!/bin/bash
case "$1" in
  "identify") echo "1024 768" ;;
  *) echo "Mock resize operation" ;;
esac
EOF
      chmod +x bin/magick
      export PATH="$PWD/bin:$PATH"
      
      When call zsh "$SHELLSPEC_PROJECT_ROOT/resize_images.zsh"
      The status should be success
      The output should include "Removed all .npz files"
    End

    It 'should process files when they exist'
      # Create test files
      touch test.jpg test.png test.npz
      
      # Create mock magick that simulates small images
      mkdir -p bin
      cat > bin/magick << 'EOF'
#!/bin/bash
case "$1" in
  "identify") echo "400 300" ;;  # Small image
  *) echo "Mock resize: $*" ;;
esac
EOF
      chmod +x bin/magick
      export PATH="$PWD/bin:$PATH"
      
      When call zsh "$SHELLSPEC_PROJECT_ROOT/resize_images.zsh"
      The status should be success
      The output should include "Removed all .npz files"
      The output should include "Skip test.jpg"
      The output should include "Skip test.png"
    End

    It 'should resize large images'
      # Create test files
      touch large.jpg
      
      # Create mock magick that simulates large images
      mkdir -p bin
      cat > bin/magick << 'EOF'
#!/bin/bash
case "$1" in
  "identify") echo "1200 800" ;;  # Large landscape image
  *) echo "Landscape image large.jpg resized height to 1024 (overwritten)" ;;
esac
EOF
      chmod +x bin/magick
      export PATH="$PWD/bin:$PATH"
      
      When call zsh "$SHELLSPEC_PROJECT_ROOT/resize_images.zsh"
      The status should be success
      The output should include "resized height to 1024"
    End
  End

  Describe 'Error handling'
    It 'should handle magick command failure gracefully'
      touch test.jpg
      
      # Create mock magick that fails
      mkdir -p bin
      cat > bin/magick << 'EOF'
#!/bin/bash
exit 1  # Always fail
EOF
      chmod +x bin/magick
      export PATH="$PWD/bin:$PATH"
      
  When call zsh "$SHELLSPEC_PROJECT_ROOT/resize_images.zsh"
  The status should be success  # Script should continue despite individual failures
  The output should include "Removed all .npz files"
  The stderr should include "magick: error processing test.jpg"
    End
  End
End
