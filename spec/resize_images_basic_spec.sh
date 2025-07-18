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
      # Remove magick from PATH by using a non-existent directory
      export OLD_PATH="$PATH"
      export PATH="/nonexistent"

      When run script "$SHELLSPEC_PROJECT_ROOT/resize_images.zsh"
      The status should be failure
      The stderr should include "command not found: magick"
      The output should include "Removed all .npz files"

      export PATH="$OLD_PATH"
    End

    It 'should continue processing when individual files fail'
      touch test1.jpg test2.jpg

      Mock magick
        if [[ "$1" == "identify" && "$3" == "test1.jpg" ]]; then
          echo "magick: error processing $3" >&2
          exit 1
        elif [[ "$1" == "test1.jpg" ]]; then
          echo "magick: error processing $1" >&2
          exit 1
        else
          if [[ "$1" == "identify" ]]; then
            echo "1024 1024"
            exit 0
          fi
          exit 0
        fi
      End

      When run script "$SHELLSPEC_PROJECT_ROOT/resize_images.zsh"
      The status should be success
      The output should include "Removed all .npz files"
      The stderr should include "magick: error processing test1.jpg"
    End
  End
End
