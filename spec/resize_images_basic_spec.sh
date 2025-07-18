#!/bin/zsh
# Copyright (C) 2025 Jim Chen <Jim@ChenJ.im>, licensed under GPL-3.0-or-later
#
# Basic tests for resize_images.zsh to verify syntax and fundamental functionality

Describe 'resize_images.zsh basic functionality'
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

  Describe 'Script validation'
    It 'should have valid zsh syntax'
      When call zsh -n "$SHELLSPEC_PROJECT_ROOT/resize_images.zsh"
      The status should be success
    End

    It 'should execute without parameters in empty directory'
      When call zsh "$SHELLSPEC_PROJECT_ROOT/resize_images.zsh"
      The status should be success
      The output should include "Removed all .npz files"
    End
  End

  Describe 'NPZ file cleanup'
    It 'should remove npz files when they exist'
      touch file1.npz file2.npz test.jpg
      
      # Create simple mock magick
      mkdir -p bin
      cat > bin/magick << 'EOF'
#!/bin/zsh
if [[ "$1" == "identify" ]]; then
  echo "400 300"  # Small image, will be skipped
fi
EOF
      chmod +x bin/magick
      export PATH="$PWD/bin:$PATH"
      
      When call zsh "$SHELLSPEC_PROJECT_ROOT/resize_images.zsh"
      The status should be success
      The output should include "Removed all .npz files"
      The file file1.npz should not be exist
      The file file2.npz should not be exist
    End

    It 'should work when no npz files exist'
      # Create simple mock magick
      mkdir -p bin
      cat > bin/magick << 'EOF'
#!/bin/zsh
if [[ "$1" == "identify" ]]; then
  echo "400 300"
fi
EOF
      chmod +x bin/magick
      export PATH="$PWD/bin:$PATH"
      
      When call zsh "$SHELLSPEC_PROJECT_ROOT/resize_images.zsh"
      The status should be success
      The output should include "Removed all .npz files"
    End
  End

  Describe 'File processing basics'
    It 'should skip files when no images exist'
      # Create simple mock magick
      mkdir -p bin
      cat > bin/magick << 'EOF'
#!/bin/zsh
echo "400 300"
EOF
      chmod +x bin/magick
      export PATH="$PWD/bin:$PATH"
      
      When call zsh "$SHELLSPEC_PROJECT_ROOT/resize_images.zsh"
      The status should be success
      The output should include "Removed all .npz files"
    End

    It 'should process jpg files when they exist'
      touch test.jpg
      
      # Create simple mock magick that returns small dimensions
      mkdir -p bin
      cat > bin/magick << 'EOF'
#!/bin/zsh
if [[ "$1" == "identify" ]]; then
  echo "400 300"  # Small image, will be skipped
fi
EOF
      chmod +x bin/magick
      export PATH="$PWD/bin:$PATH"
      
      When call zsh "$SHELLSPEC_PROJECT_ROOT/resize_images.zsh"
      The status should be success
      The output should include "Skip test.jpg"
    End

    It 'should process png files when they exist'
      touch test.png
      
      # Create simple mock magick that returns small dimensions
      mkdir -p bin
      cat > bin/magick << 'EOF'
#!/bin/zsh
if [[ "$1" == "identify" ]]; then
  echo "400 300"  # Small image, will be skipped
fi
EOF
      chmod +x bin/magick
      export PATH="$PWD/bin:$PATH"
      
      When call zsh "$SHELLSPEC_PROJECT_ROOT/resize_images.zsh"
      The status should be success
      The output should include "Skip test.png"
    End
  End

  Describe 'Error handling'
    It 'should handle missing magick command gracefully'
      touch test.jpg
      
      When call zsh "$SHELLSPEC_PROJECT_ROOT/resize_images.zsh"
      The status should be success
      The stderr should include "command not found: magick"
      The output should include "Removed all .npz files"
    End

    It 'should continue processing when individual files fail'
      touch test1.jpg test2.jpg
      
      # Create mock magick that fails for identify
      mkdir -p bin
      cat > bin/magick << 'EOF'
#!/bin/zsh
exit 1  # Always fail
EOF
      chmod +x bin/magick
      export PATH="$PWD/bin:$PATH"
      
      When call zsh "$SHELLSPEC_PROJECT_ROOT/resize_images.zsh"
      The status should be success
      The output should include "Removed all .npz files"
    End
  End
End