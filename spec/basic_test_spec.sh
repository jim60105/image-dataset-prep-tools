#!/bin/zsh

eval "$(shellspec - -c) exit 1"
# Copyright (C) 2025 Jim Chen <Jim@ChenJ.im>, licensed under GPL-3.0-or-later
#
# Simple ShellSpec test to verify framework works

Describe 'Basic ShellSpec functionality'
  It 'should perform basic arithmetic'
    When call expr 2 + 2
    The output should equal "4"
    The status should be success
  End

  It 'should handle string operations'
    When call echo "hello world"
    The output should equal "hello world"
  End

  It 'should test file operations'
    When call test -f /etc/passwd
    The status should be success
  End
End
