#!/bin/zsh
# Copyright (C) 2025 Jim Chen <Jim@ChenJ.im>, licensed under GPL-3.0-or-later
#
# Mock implementation of curl for testing scrape_danbooru_aliases.zsh
# This mock prevents real HTTP requests during testing

# Mock curl command
curl() {
    local url=""
    local silent=false
    local fail_fast=false
    local max_time=""
    local output_file=""
    
    # Parse arguments to find the URL
    while [[ $# -gt 0 ]]; do
        case $1 in
            -s)
                silent=true
                shift
                ;;
            -f)
                fail_fast=true
                shift
                ;;
            --max-time)
                max_time="$2"
                shift 2
                ;;
            -o)
                output_file="$2"
                shift 2
                ;;
            http*|https*)
                url="$1"
                shift
                ;;
            *)
                shift
                ;;
        esac
    done
    
    # Extract page number from URL using parameter expansion
    local page_num="1"
    if [[ "$url" == *"page="* ]]; then
        # Extract the page parameter value
        local temp="${url#*page=}"
        page_num="${temp%%&*}"
        # Remove any non-numeric characters
        page_num="${page_num//[^0-9]/}"
        [[ -z "$page_num" ]] && page_num="1"
    fi
    
    # Mock different responses based on conditions
    if [[ "$url" == *"danbooru.donmai.us/tag_aliases.json"* ]]; then
        # Mock successful responses for first few pages
        if [[ "$page_num" == "1" ]]; then
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
        elif [[ "$page_num" == "2" ]]; then
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
        elif [[ "$page_num" == "3" ]]; then
            # Third page returns empty array (end of data)
            echo "[]"
        elif [[ "$page_num" == "999" ]]; then
            # Simulate network failure for error testing
            return 6  # CURLE_COULDNT_RESOLVE_HOST
        else
            # Default: return empty array for other pages
            echo "[]"
        fi
        return 0
    else
        # For any other URL, simulate failure
        return 6  # CURLE_COULDNT_RESOLVE_HOST
    fi
}

# Mock function for testing specific error conditions
mock_curl_failure() {
    curl() {
        return 6  # Always fail with network error
    }
}

# Mock function for testing invalid JSON responses
mock_curl_invalid_json() {
    curl() {
        echo "invalid json response"
        return 0
    }
}

# Mock function for testing empty responses
mock_curl_empty_response() {
    curl() {
        echo ""
        return 0
    }
}