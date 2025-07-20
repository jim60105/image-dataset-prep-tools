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
# Process all .txt files in the current working directory: cleans and restructures content based on user-provided trigger, removes specified keywords and noise, and prepends "1girl, {trigger}" to each line.
# Automatically extracts trigger word from directory path or accepts it as parameter.
# Usage: process_txt_files.zsh [trigger_word] (from any directory)

# Set nullglob option to handle cases where no files match the pattern
setopt nullglob

# Global variable for tag aliases
declare -gA tag_aliases

# ============================================================================
# UTILITY FUNCTIONS
# ============================================================================

# Function to trim whitespace from a string
trim_whitespace() {
    local input="$1"
    echo "$input" | sed 's/^[[:space:]]*//;s/[[:space:]]*$//'
}

# Function to split content into tags array
split_tags() {
    local content="$1"
    local -a tags_array
    IFS=',' read -rA tags_array <<< "$content"
    
    # Return array via global variable for efficiency
    split_tags_result=()
    for tag in "${tags_array[@]}"; do
        local trimmed_tag=$(trim_whitespace "$tag")
        [[ -n "$trimmed_tag" ]] && split_tags_result+=("$trimmed_tag")
    done
}

# Function to join tags array back to comma-separated string
join_tags() {
    local -a tags=("$@")
    local result=""
    
    for ((i=1; i<=${#tags[@]}; i++)); do
        if [[ $i -eq 1 ]]; then
            result="${tags[$i]}"
        else
            result="$result, ${tags[$i]}"
        fi
    done
    
    echo "$result"
}

# ============================================================================
# TAG ALIAS FUNCTIONS
# ============================================================================
# Function to load Danbooru tag aliases
load_tag_aliases() {
    local script_dir="$(dirname "$(realpath "${(%):-%x}")")"
    local csv_file="$script_dir/../data/danbooru_tag_aliases.csv"
    
    if [[ ! -f "$csv_file" ]]; then
        echo "WARNING: Tag aliases file not found: $csv_file" >&2
        return 1
    fi
    
    echo "Loading tag aliases from: $csv_file" >&2
    
    local line_count=0
    while IFS=',' read -r id antecedent_name consequent_name creator_id forum_topic_id alias_status rest; do
        ((line_count++))
        [[ $line_count -eq 1 ]] && continue  # Skip header
        
        local clean_antecedent=${antecedent_name//\"/}
        local clean_consequent=${consequent_name//\"/}
        tag_aliases[$clean_antecedent]=$clean_consequent
    done < "$csv_file"
    
    echo "Loaded ${#tag_aliases[@]} active tag aliases" >&2
    return 0
}

# Function to apply tag aliases to a single tag
apply_tag_alias() {
    local tag="$1"
    
    if [[ -n "${tag_aliases[$tag]}" ]]; then
        echo "${tag_aliases[$tag]}"
    else
        echo "$tag"
    fi
}

# Function to apply aliases to all tags in content
apply_tag_aliases_to_content() {
    local content="$1"
    [[ ${#tag_aliases[@]} -eq 0 ]] && { echo "$content"; return; }
    
    split_tags "$content"
    local processed_tags=()
    
    for tag in "${split_tags_result[@]}"; do
        local processed_tag=$(apply_tag_alias "$tag")
        processed_tags+=("$processed_tag")
    done
    
    join_tags "${processed_tags[@]}"
}

# ============================================================================
# CONTENT CLEANING FUNCTIONS
# ============================================================================

# Function to escape parentheses in content
escape_parentheses() {
    local content="$1"
    echo "$content" | sed -E 's/([^\\]|^)[(]/\1\\(/g; s/([^\\]|^)\)/\1\\)/g'
}

# Function to remove unwanted patterns from content
remove_unwanted_patterns() {
    local content="$1"
    local trigger="$2"
    
    # Remove the trigger word only when it appears as a standalone tag
    # Use the existing tag processing functions for more reliable handling
    split_tags "$content"
    local filtered_tags=()
    
    for tag in "${split_tags_result[@]}"; do
        # Only skip tags that exactly match the trigger word
        if [[ "$tag" != "$trigger" ]]; then
            filtered_tags+=("$tag")
        fi
    done
    
    content=$(join_tags "${filtered_tags[@]}")
    
    # Remove commentary patterns using bash parameter expansion where possible
    content=${content//, commentary_request/}
    content=$(echo "$content" | sed -E 's/, commentary[[:alnum:]_]*//g')
    content=$(echo "$content" | sed -E 's/, [[:alnum:]_]*_commentary//g')
    
    # Remove specific unwanted tags
    content=${content//, \\(;\\)/}
    content=${content//, \\(_\\)/}
    content=${content//, virtual_youtuber/}
    content=${content//, commission/}
    content=$(echo "$content" | sed -E 's/, [[:alnum:]_]*_commission//g')
    
    echo "$content"
}

# Function to convert emoji tags
convert_emoji_tags() {
    local content="$1"
    echo "$content" | sed -E 's/, _([a-zA-Z0-9]),/, :\1,/g'
}

# Function to remove standalone problematic tags
remove_standalone_tags() {
    local content="$1"
    echo "$content" | sed -E 's/, s,/,/g'
}

# Function to clean up comma and space formatting
cleanup_formatting() {
    local content="$1"
    
    # Clean up multiple commas and spaces
    content=${content//,, /, }
    content=${content//,,/,}
    content=${content//, ,/,}
    
    # Remove leading and trailing comma/space
    content=${content#, }
    content=${content%, }
    
    echo "$content"
}

# Function to remove duplicate tags from content
remove_duplicate_tags() {
    local content="$1"
    
    split_tags "$content"
    declare -A seen_tags
    declare -a unique_tags
    
    for tag in "${split_tags_result[@]}"; do
        if [[ -z "${seen_tags[$tag]}" ]]; then
            seen_tags[$tag]=1
            unique_tags+=("$tag")
        fi
    done
    
    join_tags "${unique_tags[@]}"
}

# ============================================================================
# TRIGGER WORD FUNCTIONS
# ============================================================================

# Function to extract trigger word from current directory path
extract_trigger_from_path() {
    local current_dir=$(basename "$(pwd)")
    
    # Remove numeric prefix (e.g., "5_Doraemon" -> "Doraemon")
    local clean_dir=${current_dir#[0-9]*_}
    
    # Split on spaces and take max 2 parts
    local parts=(${(s: :)clean_dir})
    case ${#parts[@]} in
        1) echo "${parts[1]}" ;;
        2) echo "${parts[2]}, ${parts[1]}" ;;
        *) echo "${parts[2]}, ${parts[1]}" ;;  # 3 or more parts
    esac
}

# Function to prompt user for trigger word
prompt_for_trigger() {
    echo "Could not auto-detect trigger word from current path." >&2
    echo -n "Please enter the trigger word: " >&2
    read trigger
    echo "Using provided trigger word: $trigger" >&2
    echo "$trigger"
}

# Function to get trigger word based on parameters
get_trigger_word() {
    case $# in
        0)
            # Auto-detect mode
            local auto_trigger=$(extract_trigger_from_path)
            if [[ -n "$auto_trigger" && "$auto_trigger" != "" ]]; then
                echo "Auto-detected trigger word from path: $auto_trigger" >&2
                echo "$auto_trigger"
            else
                prompt_for_trigger
            fi
            ;;
        1)
            # Single parameter mode
            echo "Using provided trigger word: $1" >&2
            echo "$1"
            ;;
        *)
            echo "ERROR: Too many parameters. Usage: process_txt_files.zsh [trigger_word]" >&2
            exit 1
            ;;
    esac
}

# ============================================================================
# CONTENT PROCESSING FUNCTIONS
# ============================================================================

# Function to process content through all cleaning steps
process_content() {
    local content="$1"
    local trigger="$2"
    
    # Step 1: Escape parentheses
    content=$(escape_parentheses "$content")
    
    # Step 2: Remove unwanted patterns
    content=$(remove_unwanted_patterns "$content" "$trigger")
    
    # Step 3: Convert emoji tags
    content=$(convert_emoji_tags "$content")
    
    # Step 4: Remove standalone problematic tags
    content=$(remove_standalone_tags "$content")
    
    # Step 5: Clean up formatting
    content=$(cleanup_formatting "$content")
    
    # Step 6: Apply tag aliases
    content=$(apply_tag_aliases_to_content "$content")
    
    # Step 7: Remove duplicates
    content=$(remove_duplicate_tags "$content")
    
    echo "$content"
}

# Function to add trigger to front of content
add_trigger_to_content() {
    local content="$1"
    local trigger="$2"
    
    if [[ -n "$content" ]]; then
        echo "$trigger, $content"
    else
        echo "$trigger"
    fi
}

# Function to process a single file
process_single_file() {
    local file="$1"
    local trigger="$2"
    
    echo "Processing: $file"
    
    local content=$(cat "$file")
    local processed_content=$(process_content "$content" "$trigger")
    local final_content=$(add_trigger_to_content "$processed_content" "$trigger")
    
    printf "%s" "$final_content" > "$file"
}

# ============================================================================
# MAIN EXECUTION
# ============================================================================

# Main function
main() {
    # Get trigger word based on parameters
    local trigger=$(get_trigger_word "$@")
    
    # Validate that we have a trigger word
    if [[ -z "$trigger" ]]; then
        echo "ERROR: No trigger word provided or could be determined"
        exit 1
    fi
    
    # Load tag aliases
    load_tag_aliases
    
    echo "Processing text files with trigger: $trigger"
    
    # Process all txt files in the current directory
    for file in *.txt; do
        [[ -f "$file" ]] && process_single_file "$file" "$trigger"
    done
    
    echo "Processing complete!"
}

# Run main function with all arguments
main "$@"
