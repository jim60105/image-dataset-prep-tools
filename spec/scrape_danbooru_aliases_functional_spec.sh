#!/usr/bin/env shellspec
# Copyright (C) 2025 Jim Chen <Jim@ChenJ.im>, licensed under GPL-3.0-or-later
#
# Comprehensive functional tests for scrape_danbooru_aliases.zsh
# Tests core functionality, error handling, and edge cases with HTTP mocking

# Mock curl for HTTP requests
Include support/mocks/curl_mock.sh

Describe "scrape_danbooru_aliases.zsh functionality"
  setup() {
    # Set up test environment
    work_dir="$(mktemp -d)"
    cd "$work_dir"
    
    # Create data directory
    mkdir -p data
    
    # Remove any existing output files
    rm -f data/danbooru_tag_aliases.csv data/danbooru_tag_aliases.temp.csv
  }
  
  cleanup() {
    # Clean up test environment
    cd /
    rm -rf "$work_dir"
  }
  
  BeforeEach 'setup'
  AfterEach 'cleanup'

  Context "Script syntax and basic execution"
    It "should execute without syntax errors"
      When run zsh -n "../scrape_danbooru_aliases.zsh"
      The status should be success
    End

    It "should handle being sourced without executing main"
      When run zsh -c 'source "../scrape_danbooru_aliases.zsh" && echo "sourced successfully"'
      The output should include "sourced successfully"
      The status should be success
    End
  End

  Context "Dependency checking"
    It "should fail when curl is not available"
      When run zsh -c 'PATH="/tmp/empty:$PATH" "../scrape_danbooru_aliases.zsh"'
      The stderr should include "curl is required but not installed"
      The status should be failure
    End

    It "should fail when jq is not available"
      When run zsh -c 'PATH="/usr/bin:/bin" curl() { echo "curl exists"; } "../scrape_danbooru_aliases.zsh"'
      The stderr should include "jq is required but not installed"
      The status should be failure
    End

    It "should fail when bc is not available"
      When run zsh -c 'PATH="/usr/bin:/bin" jq() { echo "jq exists"; } curl() { echo "curl exists"; } "../scrape_danbooru_aliases.zsh"'
      The stderr should include "bc is required but not installed"
      The status should be failure
    End
  End

  Context "Data directory creation"
    It "should create data directory if it doesn't exist"
      # Remove data directory
      rmdir data
      
      When run zsh "../scrape_danbooru_aliases.zsh"
      The output should include "Created data directory"
      The path "data" should be directory
    End

    It "should not recreate data directory if it exists"
      When run zsh "../scrape_danbooru_aliases.zsh"
      The output should not include "Created data directory"
    End
  End

  Context "API request functionality"
    It "should make successful API requests and process data"
      When run zsh "../scrape_danbooru_aliases.zsh"
      The status should be success
      The output should include "Fetching page 1..."
      The output should include "Fetching page 2..."
      The output should include "Page 1 completed, 2 records"
      The output should include "Page 2 completed, 1 record"
      The output should include "Reached last page, total records fetched: 3"
      The output should include "Total records: 3"
      The path "data/danbooru_tag_aliases.csv" should be file
    End

    It "should generate proper CSV format"
      When run zsh "../scrape_danbooru_aliases.zsh"
      The file "data/danbooru_tag_aliases.csv" should include "id,antecedent_name,consequent_name,creator_id"
      The file "data/danbooru_tag_aliases.csv" should include "12345,test_tag_1,real_tag_1,100"
      The file "data/danbooru_tag_aliases.csv" should include "12346,test_tag_2,real_tag_2,101"
      The file "data/danbooru_tag_aliases.csv" should include "12347,test_tag_3,real_tag_3,102"
    End

    It "should handle null values in JSON properly"
      When run zsh "../scrape_danbooru_aliases.zsh"
      # Check that null values are converted to empty strings in CSV
      The file "data/danbooru_tag_aliases.csv" should include '12345,"test_tag_1","real_tag_1",100,,"active"'
      The file "data/danbooru_tag_aliases.csv" should include '12347,"test_tag_3","real_tag_3",102,,"retired"'
    End
  End

  Context "Authentication handling"
    It "should include authentication parameters when provided"
      export DANBOORU_LOGIN="testuser"
      export DANBOORU_APIKEY="testkey123"
      
      When run zsh "../scrape_danbooru_aliases.zsh"
      The output should include "Authentication: Enabled (login: testuser)"
      The status should be success
      
      unset DANBOORU_LOGIN DANBOORU_APIKEY
    End

    It "should work without authentication"
      unset DANBOORU_LOGIN DANBOORU_APIKEY
      
      When run zsh "../scrape_danbooru_aliases.zsh"
      The output should include "Authentication: None (public access)"
      The status should be success
    End
  End

  Context "Error handling"
    It "should handle network failures gracefully"
      # Override curl to simulate failure
      mock_curl_failure
      
      When run zsh "../scrape_danbooru_aliases.zsh"
      The stderr should include "API request failed (page 1), exit code: 6"
      The stderr should include "This might be due to network restrictions"
      The status should be failure
    End

    It "should handle invalid JSON responses"
      # Override curl to return invalid JSON
      mock_curl_invalid_json
      
      When run zsh "../scrape_danbooru_aliases.zsh"
      The stderr should include "No valid data on page 1 (JSON to CSV conversion failed)"
      The output should include "Reached last page"
      The status should be failure
    End

    It "should handle empty responses"
      # Override curl to return empty responses
      mock_curl_empty_response
      
      When run zsh "../scrape_danbooru_aliases.zsh"
      The output should include "Reached last page, total records fetched: 0"
      The status should be failure
    End

    It "should respect maximum page limit"
      # Test with mock that would return data for many pages
      MAX_PAGES=2 zsh -c 'source "../scrape_danbooru_aliases.zsh" && fetch_all_pages "data/test_output.csv"' 2>&1 | {
        When call cat
        The output should include "Reached maximum page limit (2), stopping..."
      }
    End
  End

  Context "Rate limiting"
    It "should implement rate limiting between requests"
      start_time=$(date +%s.%N)
      
      When run zsh "../scrape_danbooru_aliases.zsh"
      
      end_time=$(date +%s.%N)
      elapsed=$(echo "$end_time - $start_time" | bc -l)
      
      # Should take at least 0.2 seconds for 2 pages (0.1s minimum interval each)
      # Using bc to compare floating point numbers
      The result of 'echo "$elapsed >= 0.15" | bc -l' should equal 1
    End
  End

  Context "File output and cleanup"
    It "should create proper CSV header"
      When run zsh "../scrape_danbooru_aliases.zsh"
      The line 1 of file "data/danbooru_tag_aliases.csv" should equal "id,antecedent_name,consequent_name,creator_id,forum_topic_id,status,created_at,updated_at,approver_id,forum_post_id,reason"
    End

    It "should clean up temporary files"
      When run zsh "../scrape_danbooru_aliases.zsh"
      The path "data/danbooru_tag_aliases.temp.csv" should not exist
    End

    It "should remove temp file if no data is fetched"
      mock_curl_empty_response
      
      When run zsh "../scrape_danbooru_aliases.zsh"
      The path "data/danbooru_tag_aliases.temp.csv" should not exist
      The path "data/danbooru_tag_aliases.csv" should not exist
    End
  End

  Context "CSV data validation"
    It "should produce valid CSV with proper escaping"
      When run zsh "../scrape_danbooru_aliases.zsh"
      The file "data/danbooru_tag_aliases.csv" should be valid CSV
      # Count lines (header + 3 data rows = 4 total)
      The result of 'wc -l < "data/danbooru_tag_aliases.csv"' should equal 4
    End

    It "should handle special characters in tag names"
      # This tests the jq @csv formatting
      When run zsh "../scrape_danbooru_aliases.zsh"
      # Verify CSV quoting is applied
      The file "data/danbooru_tag_aliases.csv" should include '"test_tag_1"'
      The file "data/danbooru_tag_aliases.csv" should include '"real_tag_1"'
    End
  End

  Context "JSON processing functions"
    It "should handle valid JSON arrays"
      json='[{"id":123,"antecedent_name":"test","consequent_name":"real","creator_id":456,"forum_topic_id":null,"status":"active","created_at":"2024-01-01","updated_at":"2024-01-01","approver_id":789,"forum_post_id":null,"reason":"test"}]'
      
      When call zsh -c "source '../scrape_danbooru_aliases.zsh' && json_to_csv '$json'"
      The output should include "123"
      The output should include "test"
      The output should include "real"
    End

    It "should reject invalid JSON"
      invalid_json='{"invalid": json}'
      
      When call zsh -c "source '../scrape_danbooru_aliases.zsh' && json_to_csv '$invalid_json'"
      The output should be blank
      The status should be failure
    End

    It "should reject non-array JSON"
      non_array_json='{"valid": "json", "but": "not array"}'
      
      When call zsh -c "source '../scrape_danbooru_aliases.zsh' && json_to_csv '$non_array_json'"
      The output should be blank
      The status should be failure
    End
  End

  Context "Configuration and environment"
    It "should use correct API endpoint"
      When run zsh "../scrape_danbooru_aliases.zsh"
      The output should include "API endpoint: https://danbooru.donmai.us/tag_aliases.json"
    End

    It "should display correct configuration"
      When run zsh "../scrape_danbooru_aliases.zsh"
      The output should include "Danbooru Tag Aliases Scraper"
      The output should include "Sorting: By tag count (descending)"
      The output should include "Maximum pages: 1000"
    End

    It "should create output file with correct name"
      When run zsh "../scrape_danbooru_aliases.zsh"
      The output should include "Output file: data/danbooru_tag_aliases.csv"
    End
  End
End