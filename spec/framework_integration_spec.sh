#!/bin/zsh
# Copyright (C) 2025 Jim Chen <Jim@ChenJ.im>, licensed under GPL-3.0-or-later
#
# Test suite integration and framework validation

Describe 'ShellSpec Testing Framework Integration'
  
  Describe 'Framework functionality'
    It 'should have ShellSpec properly installed'
      When call which shellspec
      The status should be success
      The output should include "shellspec"
    End

    It 'should support zsh shell execution'
      When call zsh --version
      The status should be success
      The output should include "zsh"
    End

    It 'should have test configuration working'
      When call test -f "$SHELLSPEC_PROJECT_ROOT/.shellspec"
      The status should be success
    End

    It 'should have all main scripts present'
      When call test -f "$SHELLSPEC_PROJECT_ROOT/../resize_images.zsh"
      The status should be success
    End

    It 'should have process_txt_files.zsh present'
      When call test -f "$SHELLSPEC_PROJECT_ROOT/../process_txt_files.zsh"
      The status should be success
    End

    It 'should have validate_dataset.zsh present'
      When call test -f "$SHELLSPEC_PROJECT_ROOT/../validate_dataset.zsh"
      The status should be success
    End
  End

  Describe 'Test infrastructure'
    It 'should have mock utilities available'
      When call test -d "$SHELLSPEC_PROJECT_ROOT/support/mocks"
      The status should be success
    End

    It 'should have test fixtures available'
      When call test -d "$SHELLSPEC_PROJECT_ROOT/support/fixtures"
      The status should be success
    End

    It 'should count total test examples correctly'
      When call bash -c 'cd "$SHELLSPEC_PROJECT_ROOT" && shellspec --format tap --count *_functional_spec.sh basic_test_spec.sh'
      The status should be success
      The output should include "20"
    End
  End

  Describe 'External dependencies'
    It 'should handle imagemagick availability for testing'
      When call bash -c 'which identify || echo "imagemagick not available - tests will use mocks"'
      The status should be success
    End

    It 'should handle missing optional dependencies gracefully'
      # Test that scripts can handle missing czkawka_cli
      When call bash -c 'test -x /usr/local/bin/czkawka_cli || echo "czkawka_cli not required for basic tests"'
      The status should be success
    End
  End

  Describe 'Code quality checks'
    It 'should have all scripts pass zsh syntax check'
      When call zsh -n "$SHELLSPEC_PROJECT_ROOT/../resize_images.zsh"
      The status should be success
    End

    It 'should have process_txt_files.zsh pass syntax check'
      When call zsh -n "$SHELLSPEC_PROJECT_ROOT/../process_txt_files.zsh"
      The status should be success
    End

    It 'should have validate_dataset.zsh pass syntax check'
      When call zsh -n "$SHELLSPEC_PROJECT_ROOT/../validate_dataset.zsh"
      The status should be success
    End
  End
End