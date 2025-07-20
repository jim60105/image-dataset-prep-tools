#!/bin/zsh

eval "$(shellspec - -c) exit 1"
# Copyright (C) 2025 Jim Chen <Jim@ChenJ.im>, licensed under GPL-3.0-or-later
#
# Functional tests for process_txt_files.zsh

# Include spec helper for common utilities
Include spec/spec_helper.sh

Describe 'process_txt_files.zsh functionality'
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
    It 'should run script successfully with minimal input'
      echo "test content" > test.txt
      When run script "$SHELLSPEC_PROJECT_ROOT/src/process_txt_files.zsh" "smoke_trigger"
      The status should be success
      The output should include "Processing complete!"
    End
  End

  Describe 'Text processing logic'
  End
End
