#!/bin/zsh

eval "$(shellspec - -c) exit 1"
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
      When call test -f "$SHELLSPEC_PROJECT_ROOT/src/resize_images.zsh"
      The status should be success
    End

    It 'should have process_txt_files.zsh present'
      When call test -f "$SHELLSPEC_PROJECT_ROOT/src/process_txt_files.zsh"
      The status should be success
    End

    It 'should have validate_dataset.zsh present'
      When call test -f "$SHELLSPEC_PROJECT_ROOT/src/validate_dataset.zsh"
      The status should be success
    End

    It 'should have scrape_danbooru_aliases.zsh present'
      When call test -f "$SHELLSPEC_PROJECT_ROOT/src/scrape_danbooru_aliases.zsh"
      The status should be success
    End
  End

  Describe 'Test infrastructure'

    It 'should have test fixtures available'
      When call test -d "$SHELLSPEC_PROJECT_ROOT/spec/support/fixtures"
      The status should be success
    End

    It 'should count total test examples correctly'
      When call bash -c 'cd "$SHELLSPEC_PROJECT_ROOT" && out=$(shellspec --format tap --count spec/*_functional_spec.sh spec/*_basic_spec.sh); for n in $out; do if [ "$n" -gt 0 ]; then echo OK; break; fi; done'
      The status should be success
      The output should include "OK"
    End
  End

  Describe 'Code quality checks'
    It 'should have all scripts pass zsh syntax check'
      When call zsh -n "$SHELLSPEC_PROJECT_ROOT/src/resize_images.zsh"
      The status should be success
    End

    It 'should have process_txt_files.zsh pass syntax check'
      When call zsh -n "$SHELLSPEC_PROJECT_ROOT/src/process_txt_files.zsh"
      The status should be success
    End

    It 'should have validate_dataset.zsh pass syntax check'
      When call zsh -n "$SHELLSPEC_PROJECT_ROOT/src/validate_dataset.zsh"
      The status should be success
    End

    It 'should have scrape_danbooru_aliases.zsh pass syntax check'
      When call zsh -n "$SHELLSPEC_PROJECT_ROOT/src/scrape_danbooru_aliases.zsh"
      The status should be success
    End
  End
End
