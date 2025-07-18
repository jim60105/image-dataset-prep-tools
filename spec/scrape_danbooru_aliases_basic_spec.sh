#!/usr/bin/env shellspec
# Copyright (C) 2025 Jim Chen <Jim@ChenJ.im>, licensed under GPL-3.0-or-later
#
# Basic tests for scrape_danbooru_aliases.zsh to verify functionality

# Mock curl for HTTP requests
Include spec/support/mocks/curl_mock.sh

Describe "scrape_danbooru_aliases.zsh basic functionality"
  Context "Script syntax"
    It "should have valid syntax"
      When run zsh -n "$SHELLSPEC_PROJECT_ROOT/scrape_danbooru_aliases.zsh"
      The status should be success
    End
  End

  Context "Basic execution"
    It "should display header information"
      When run zsh -c 'timeout 5 zsh "$SHELLSPEC_PROJECT_ROOT/scrape_danbooru_aliases.zsh" 2>&1 | head -10'
      The output should include "Danbooru Tag Aliases Scraper"
      The output should include "API endpoint: https://danbooru.donmai.us/tag_aliases.json"
    End
  End
End