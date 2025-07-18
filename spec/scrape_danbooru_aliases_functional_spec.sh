#!/usr/bin/env shellspec
# Copyright (C) 2025 Jim Chen <Jim@ChenJ.im>, licensed under GPL-3.0-or-later
#
# Comprehensive functional tests for scrape_danbooru_aliases.zsh
# Tests core functionality, error handling, and edge cases with HTTP mocking

# Mock curl for HTTP requests
Include support/mocks/curl_mock.sh

Describe "scrape_danbooru_aliases.zsh comprehensive functionality"
  setup() {
    # Set up test environment
    work_dir="$(mktemp -d)"
    cd "$work_dir"
    mkdir -p data
    rm -f data/danbooru_tag_aliases.csv data/danbooru_tag_aliases.temp.csv
  }
  
  cleanup() {
    cd / && rm -rf "$work_dir"
  }
  
  BeforeEach 'setup'
  AfterEach 'cleanup'

  Context "Script execution and basic functionality"
    It "should execute and produce output file"
      When run zsh /home/runner/work/image-dataset-prep-tools/image-dataset-prep-tools/scrape_danbooru_aliases.zsh
      The status should be success
      The output should include "Scraping completed successfully!"
      The path "data/danbooru_tag_aliases.csv" should be file
    End

    It "should generate proper CSV header"
      When run zsh /home/runner/work/image-dataset-prep-tools/image-dataset-prep-tools/scrape_danbooru_aliases.zsh
      The line 1 of file "data/danbooru_tag_aliases.csv" should equal "id,antecedent_name,consequent_name,creator_id,forum_topic_id,status,created_at,updated_at,approver_id,forum_post_id,reason"
    End

    It "should process multiple pages of data"
      When run zsh /home/runner/work/image-dataset-prep-tools/image-dataset-prep-tools/scrape_danbooru_aliases.zsh
      The output should include "Fetching page 1..."
      The output should include "Fetching page 2..."
      The output should include "Page 1 completed, 2 records"
      The output should include "Total records: 3"
    End
  End

  Context "Authentication handling"
    It "should work without authentication"
      unset DANBOORU_LOGIN DANBOORU_APIKEY
      When run zsh /home/runner/work/image-dataset-prep-tools/image-dataset-prep-tools/scrape_danbooru_aliases.zsh
      The output should include "Authentication: None (public access)"
    End

    It "should display authentication when credentials provided"
      export DANBOORU_LOGIN="testuser"
      export DANBOORU_APIKEY="testkey123"
      When run zsh /home/runner/work/image-dataset-prep-tools/image-dataset-prep-tools/scrape_danbooru_aliases.zsh
      The output should include "Authentication: Enabled (login: testuser)"
      unset DANBOORU_LOGIN DANBOORU_APIKEY
    End
  End

  Context "Error handling"
    It "should handle network failures"
      mock_curl_failure
      When run zsh /home/runner/work/image-dataset-prep-tools/image-dataset-prep-tools/scrape_danbooru_aliases.zsh
      The stderr should include "API request failed"
      The status should be failure
    End

    It "should handle invalid JSON responses"
      mock_curl_invalid_json
      When run zsh /home/runner/work/image-dataset-prep-tools/image-dataset-prep-tools/scrape_danbooru_aliases.zsh
      The stderr should include "No valid data on page"
    End

    It "should fail when curl is missing"
      When run zsh -c 'PATH="/dev/null" /home/runner/work/image-dataset-prep-tools/image-dataset-prep-tools/scrape_danbooru_aliases.zsh'
      The stderr should include "curl is required but not installed"
      The status should be failure
    End

    It "should fail when jq is missing"
      When run zsh -c 'PATH="/usr/bin:/bin" /home/runner/work/image-dataset-prep-tools/image-dataset-prep-tools/scrape_danbooru_aliases.zsh'
      The stderr should include "jq is required but not installed"
      The status should be failure
    End
  End

  Context "Data processing"
    It "should create valid CSV output"
      When run zsh /home/runner/work/image-dataset-prep-tools/image-dataset-prep-tools/scrape_danbooru_aliases.zsh
      The file "data/danbooru_tag_aliases.csv" should include "12345"
      The file "data/danbooru_tag_aliases.csv" should include "test_tag_1"
      The file "data/danbooru_tag_aliases.csv" should include "real_tag_1"
    End

    It "should handle null values properly"
      When run zsh /home/runner/work/image-dataset-prep-tools/image-dataset-prep-tools/scrape_danbooru_aliases.zsh
      The file "data/danbooru_tag_aliases.csv" should be valid
    End

    It "should clean up temporary files"
      When run zsh /home/runner/work/image-dataset-prep-tools/image-dataset-prep-tools/scrape_danbooru_aliases.zsh
      The path "data/danbooru_tag_aliases.temp.csv" should not exist
    End
  End

  Context "Configuration and setup"
    It "should create data directory if missing"
      rmdir data
      When run zsh /home/runner/work/image-dataset-prep-tools/image-dataset-prep-tools/scrape_danbooru_aliases.zsh
      The output should include "Created data directory"
      The path "data" should be directory
    End

    It "should display configuration information"
      When run zsh /home/runner/work/image-dataset-prep-tools/image-dataset-prep-tools/scrape_danbooru_aliases.zsh
      The output should include "Danbooru Tag Aliases Scraper"
      The output should include "API endpoint: https://danbooru.donmai.us/tag_aliases.json"
      The output should include "Maximum pages: 1000"
    End
  End

  Context "JSON processing functions"
    It "should process valid JSON arrays correctly"
      json='[{"id":123,"antecedent_name":"test","consequent_name":"real","creator_id":456,"forum_topic_id":null,"status":"active","created_at":"2024-01-01","updated_at":"2024-01-01","approver_id":789,"forum_post_id":null,"reason":"test"}]'
      When call zsh -c "source /home/runner/work/image-dataset-prep-tools/image-dataset-prep-tools/scrape_danbooru_aliases.zsh && json_to_csv '$json'"
      The output should include "123"
      The output should include '"test"'
      The output should include '"real"'
    End

    It "should reject invalid JSON"
      invalid_json='invalid json'
      When call zsh -c "source /home/runner/work/image-dataset-prep-tools/image-dataset-prep-tools/scrape_danbooru_aliases.zsh && json_to_csv '$invalid_json'"
      The output should be blank
      The status should be failure
    End
  End

  Context "Rate limiting and performance"
    It "should implement rate limiting"
      start_time=$(date +%s.%N)
      When run zsh /home/runner/work/image-dataset-prep-tools/image-dataset-prep-tools/scrape_danbooru_aliases.zsh
      end_time=$(date +%s.%N)
      elapsed=$(echo "$end_time - $start_time" | bc -l)
      # Should take at least some time due to rate limiting
      The result of 'echo "$elapsed >= 0.1" | bc -l' should equal 1
    End
  End

  Context "API request functionality"
    It "should make proper API requests"
      When call zsh -c "source /home/runner/work/image-dataset-prep-tools/image-dataset-prep-tools/scrape_danbooru_aliases.zsh && api_request 1"
      The output should include '"id": 12345'
      The output should include '"antecedent_name": "test_tag_1"'
    End

    It "should handle empty API responses"
      When call zsh -c "source /home/runner/work/image-dataset-prep-tools/image-dataset-prep-tools/scrape_danbooru_aliases.zsh && api_request 3"
      The output should equal "[]"
    End
  End
End