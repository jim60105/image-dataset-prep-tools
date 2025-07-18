#!/bin/zsh
# Copyright (C) 2025 Jim Chen <Jim@ChenJ.im>, licensed under GPL-3.0-or-later
#
# This program is free software: you can redistribute it and/or modify
# it under the terms of the GNU General Public License as published by
# the Free Software Foundation, either version 3 of the License, or
# (at your option) any later version.
#
# This program is distributed in the hope that it will be useful,
# but WITHOUT ANY WARRANTY; without even the implied warranty of
# MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
# GNU General Public License for more details.
#
# You should have received a copy of the GNU General Public License
# along with this program.  If not, see <https://www.gnu.org/licenses/>.
# ==================================================================
#
# Scrapes all Danbooru tag aliases from the API and saves them to a CSV file.
# Supports pagination to fetch complete dataset and implements proper rate limiting.
# Data is sorted by tag count (most popular aliases first) with a maximum of 1000 pages.
# Usage: scrape_danbooru_aliases.zsh (from any directory)

# Set nullglob option to handle cases where no files match the pattern
setopt nullglob

# Configuration
BASE_URL="https://danbooru.donmai.us"  # Use production environment by default
ENDPOINT="/tag_aliases.json"
MIN_INTERVAL=0.1  # Minimum interval between requests (10 requests/second max)
MAX_PAGES=1000   # Maximum number of pages to scrape

# Color codes for output
RED='\033[31m'
YELLOW='\033[33m'
GRAY='\033[90m'
RESET='\033[0m'

# Function to make API request with rate limiting
api_request() {
    local page=$1
    local start_time=$(date +%s.%N)
    local params="?page=${page}&search%5Border%5D=tag_count"
    
    # Add authentication parameters if environment variables are set
    if [[ -n "$DANBOORU_LOGIN" && -n "$DANBOORU_APIKEY" ]]; then
        params="${params}&login=${DANBOORU_LOGIN}&api_key=${DANBOORU_APIKEY}"
    fi
    
    local url="${BASE_URL}${ENDPOINT}${params}"
    
    # Make the request
    local response
    response=$(curl -s -f "$url" --max-time 30 2>/dev/null)
    local curl_exit_code=$?
    
    # Calculate elapsed time and ensure rate limiting
    local end_time=$(date +%s.%N)
    local elapsed=$(echo "$end_time - $start_time" | bc -l)
    
    if (( $(echo "$elapsed < $MIN_INTERVAL" | bc -l) )); then
        local sleep_time=$(echo "$MIN_INTERVAL - $elapsed" | bc -l)
        sleep "$sleep_time"
    fi
    
    # Check for curl errors
    if [[ $curl_exit_code -ne 0 ]]; then
        return $curl_exit_code
    fi
    
    echo "$response"
}

# Function to convert JSON response to CSV format
json_to_csv() {
    local input_json="$1"
    
    # First check if input is valid JSON array
    if ! echo "$input_json" | jq -e 'type == "array"' >/dev/null 2>&1; then
        echo "" # Return empty string for invalid JSON
        return 1
    fi
    
    # Convert JSON to CSV, handling null values properly
    echo "$input_json" | jq -r '
        .[] | 
        [
            (.id // ""),
            (.antecedent_name // ""),
            (.consequent_name // ""),
            (.creator_id // ""),
            (.forum_topic_id // ""),
            (.status // ""),
            (.created_at // ""),
            (.updated_at // ""),
            (.approver_id // ""),
            (.forum_post_id // ""),
            (.reason // "")
        ] | @csv
    ' 2>/dev/null || echo ""
}

# Function to fetch all pages
fetch_all_pages() {
    local page=1
    local total_records=0
    local output_file="$1"
    local temp_file="${output_file%.csv}.temp.csv"
    
    # Create CSV header in temp file
    echo "id,antecedent_name,consequent_name,creator_id,forum_topic_id,status,created_at,updated_at,approver_id,forum_post_id,reason" > "$temp_file"
    
    while true; do
        # Check for maximum page limit
        if [[ $page -gt $MAX_PAGES ]]; then
            echo "Reached maximum page limit ($MAX_PAGES), stopping..." >&2
            break
        fi
        
        echo "Fetching page $page..." >&2
        
        local response
        response=$(api_request "$page")
        local request_status=$?
        
        # Check if request failed
        if [[ $request_status -ne 0 ]]; then
            echo -e "${RED}ERROR: API request failed (page $page), exit code: $request_status${RESET}" >&2
            echo -e "${YELLOW}This might be due to network restrictions, authentication requirements, or API changes.${RESET}" >&2
            echo -e "${YELLOW}Try setting DANBOORU_LOGIN and DANBOORU_APIKEY environment variables if you have an account.${RESET}" >&2
            break
        fi
        
        # Check if response is empty array or empty string
        if [[ -z "$response" || "$response" == "[]" ]]; then
            echo "Reached last page, total records fetched: $total_records" >&2
            break
        fi
        
        # Convert to CSV and count records
        local csv_data
        csv_data=$(json_to_csv "$response")
        local csv_exit_code=$?
        
        # Check if CSV conversion was successful and produced data
        if [[ $csv_exit_code -ne 0 || -z "$csv_data" ]]; then
            echo -e "${YELLOW}WARNING: No valid data on page $page (JSON to CSV conversion failed)${RESET}" >&2
            page=$((page + 1))
            continue
        fi
        
        # Additional check: ensure we have actual CSV lines (not just whitespace)
        local csv_line_count
        csv_line_count=$(echo "$csv_data" | grep -c '^[0-9]')
        if [[ $csv_line_count -eq 0 ]]; then
            echo -e "${YELLOW}WARNING: No valid CSV records on page $page${RESET}" >&2
            page=$((page + 1))
            continue
        fi
        
        # Use the already calculated line count
        local page_records=$csv_line_count
        
        # Append CSV data to temp file
        echo "$csv_data" >> "$temp_file"
        total_records=$((total_records + page_records))
        
        echo -e "${GRAY}Page $page completed, $page_records records${RESET}" >&2
        
        page=$((page + 1))
    done
    
    # Move temp file to final location if successful
    if [[ -f "$temp_file" && $total_records -gt 0 ]]; then
        mv "$temp_file" "$output_file"
        echo "Successfully moved temp file to final location" >&2
    elif [[ -f "$temp_file" ]]; then
        rm "$temp_file"
        echo -e "${YELLOW}WARNING: Removed empty temp file${RESET}" >&2
    fi
}

# Main execution
main() {
    echo "Danbooru Tag Aliases Scraper"
    echo "============================"
    echo "API endpoint: ${BASE_URL}${ENDPOINT}"
    echo "Sorting: By tag count (descending)"
    echo "Maximum pages: $MAX_PAGES"
    
    # Check for authentication
    if [[ -n "$DANBOORU_LOGIN" && -n "$DANBOORU_APIKEY" ]]; then
        echo "Authentication: Enabled (login: $DANBOORU_LOGIN)"
    else
        echo "Authentication: None (public access)"
    fi
    
    # Create data directory if it doesn't exist
    if [[ ! -d "data" ]]; then
        mkdir -p "data"
        echo "Created data directory"
    fi
    
    # Generate output filename
    local output_file="data/danbooru_tag_aliases.csv"
    
    echo "Output file: $output_file"
    echo ""
    
    # Check dependencies
    if ! command -v curl >/dev/null 2>&1; then
        echo -e "${RED}ERROR: curl is required but not installed${RESET}" >&2
        exit 1
    fi
    
    if ! command -v jq >/dev/null 2>&1; then
        echo -e "${RED}ERROR: jq is required but not installed${RESET}" >&2
        exit 1
    fi
    
    if ! command -v bc >/dev/null 2>&1; then
        echo -e "${RED}ERROR: bc is required but not installed${RESET}" >&2
        exit 1
    fi
    
    # Start fetching data
    echo "Starting data fetch..."
    fetch_all_pages "$output_file"
    
    # Clean up any remaining temp files
    local temp_file="${output_file%.csv}.temp.csv"
    [[ -f "$temp_file" ]] && rm "$temp_file" 2>/dev/null
    
    # Final summary
    if [[ -f "$output_file" ]]; then
        local total_lines=$(($(wc -l < "$output_file") - 1))  # Subtract header line
        echo ""
        echo "Scraping completed successfully!"
        echo "Total records: $total_lines"
        echo "Output file: $output_file"
    else
        echo -e "${RED}ERROR: Output file was not created${RESET}" >&2
        exit 1
    fi
}

# Check if script is being sourced or executed
if [[ "${BASH_SOURCE[0]}" == "${0}" ]] || [[ "${(%):-%x}" == "${0}" ]]; then
    main "$@"
fi
