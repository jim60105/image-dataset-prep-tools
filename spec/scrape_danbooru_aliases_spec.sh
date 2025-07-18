#!/bin/zsh
# Copyright (C) 2025 Jim Chen <Jim@ChenJ.im>, licensed under GPL-3.0-or-later
#
# ShellSpec tests for scrape_danbooru_aliases.zsh

Describe 'scrape_danbooru_aliases.zsh'

  Describe 'Basic execution'
    It 'should execute without syntax errors'
      When run zsh -n "$SHELLSPEC_PROJECT_ROOT/scrape_danbooru_aliases.zsh"
      The status should be success
    End

    It 'should display help information'
      Skip "Interactive test requires HTTP mocking"
    End
  End
End