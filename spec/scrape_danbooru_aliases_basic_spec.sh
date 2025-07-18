#!/bin/zsh

eval "$(shellspec - -c) exit 1"
# Copyright (C) 2025 Jim Chen <Jim@ChenJ.im>, licensed under GPL-3.0-or-later
#
# Basic tests for scrape_danbooru_aliases.zsh to verify functionality

Describe "scrape_danbooru_aliases.zsh basic functionality"
  # Cleanup: restore tracked CSV after all tests
  AfterAll 'git checkout -- data/danbooru_tag_aliases.csv'

  Context "Script syntax"
    It "should have valid syntax"
      When run zsh -n "$SHELLSPEC_PROJECT_ROOT/scrape_danbooru_aliases.zsh"
      The status should be success
    End
  End

  Context "Basic execution with mocked API"
    Mock curl
      url=""
      page_num="1"
      
      # Parse arguments to find the URL
      while [[ $# -gt 0 ]]; do
          case $1 in
              -s|-f)
                  shift
                  ;;
              --max-time)
                  shift 2
                  ;;
              -o)
                  shift 2
                  ;;
              https://*)
                  url="$1"
                  shift
                  ;;
              *)
                  shift
                  ;;
          esac
      done
      
      # Extract page number from URL
      if [[ "$url" == *"page="* ]]; then
          temp="${url#*page=}"
          page_num="${temp%%&*}"
          page_num="${page_num//[^0-9]/}"
          [[ -z "$page_num" ]] && page_num="1"
      fi
      
      # Mock API responses
      if [[ "$url" == *"danbooru.donmai.us/tag_aliases.json"* ]]; then
          case "$page_num" in
              1)
                  # First page with sample data
                  cat << 'EOF'
[
  {
    "id": 12345,
    "antecedent_name": "test_tag_1",
    "consequent_name": "real_tag_1",
    "creator_id": 100,
    "forum_topic_id": null,
    "status": "active",
    "created_at": "2024-01-01T00:00:00.000Z",
    "updated_at": "2024-01-01T00:00:00.000Z",
    "approver_id": 200,
    "forum_post_id": null,
    "reason": "duplicate tag"
  },
  {
    "id": 12346,
    "antecedent_name": "test_tag_2",
    "consequent_name": "real_tag_2",
    "creator_id": 101,
    "forum_topic_id": 5000,
    "status": "active",
    "created_at": "2024-01-02T00:00:00.000Z",
    "updated_at": "2024-01-02T00:00:00.000Z",
    "approver_id": 201,
    "forum_post_id": 6000,
    "reason": "standardization"
  }
]
EOF
                  ;;
              2)
                  # Second page with sample data
                  cat << 'EOF'
[
  {
    "id": 12347,
    "antecedent_name": "test_tag_3",
    "consequent_name": "real_tag_3",
    "creator_id": 102,
    "forum_topic_id": null,
    "status": "retired",
    "created_at": "2024-01-03T00:00:00.000Z",
    "updated_at": "2024-01-03T00:00:00.000Z",
    "approver_id": null,
    "forum_post_id": null,
    "reason": ""
  }
]
EOF
                  ;;
              *)
                  # Third page and beyond return empty array (end of data)
                  echo "[]"
                  ;;
          esac
          return 0
      else
          return 6  # CURLE_COULDNT_RESOLVE_HOST
      fi
    End

    It "should display header information and process two pages successfully"
      When run zsh "$SHELLSPEC_PROJECT_ROOT/scrape_danbooru_aliases.zsh"
      The status should be success
      The output should include "Danbooru Tag Aliases Scraper"
      The output should include "API endpoint: https://danbooru.donmai.us/tag_aliases.json"
      The stderr should include "Fetching page 1..."
      The stderr should include "Fetching page 2..."
  The output should include "Reached last page, total records fetched: 3"
      The output should include "Scraping completed successfully!"
      The output should include "Total records: 3"
    End

    It "should create output file with correct data"
      When run zsh "$SHELLSPEC_PROJECT_ROOT/scrape_danbooru_aliases.zsh"
      The status should be success
      The file "data/danbooru_tag_aliases.csv" should be exist
      The contents of file "data/danbooru_tag_aliases.csv" should include "test_tag_1"
      The contents of file "data/danbooru_tag_aliases.csv" should include "test_tag_2"
      The contents of file "data/danbooru_tag_aliases.csv" should include "test_tag_3"
  # 補上所有 output 及 stderr assertion，避免 warning
  The output should include "Danbooru Tag Aliases Scraper"
  The output should include "API endpoint: https://danbooru.donmai.us/tag_aliases.json"
  The output should include "Scraping completed successfully!"
  The output should include "Total records: 3"
  The stderr should include "Fetching page 1..."
  The output should include "Page 1 completed, 2 records"
  The stderr should include "Fetching page 2..."
  The output should include "Page 2 completed, 1 records"
  The stderr should include "Fetching page 3..."
  The output should include "Reached last page, total records fetched: 3"
  The output should include "Successfully moved temp file to final location"
    End
  End
End
