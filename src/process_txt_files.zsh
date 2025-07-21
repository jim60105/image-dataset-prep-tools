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

# Global variable for preserved tags
declare -ga preserve_tags

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
    
    echo "Loading tag aliases from: $csv_file"
    
    local line_count=0
    while IFS=',' read -r id antecedent_name consequent_name creator_id forum_topic_id alias_status rest; do
        ((line_count++))
        [[ $line_count -eq 1 ]] && continue  # Skip header
        
        local clean_antecedent=${antecedent_name//\"/}
        local clean_consequent=${consequent_name//\"/}
        tag_aliases[$clean_antecedent]=$clean_consequent
    done < "$csv_file"
    
    echo "Loaded ${#tag_aliases[@]} active tag aliases"
    return 0
}

# Function to apply tag aliases to a single tag
apply_tag_alias() {
    local tag="$1"
    
    # Check if tag should be preserved
    if is_tag_preserved "$tag"; then
        echo "$tag"
        return
    fi
    
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
    
    # If no preserved tags, use original logic
    if [[ ${#preserve_tags[@]} -eq 0 ]]; then
        echo "$content" | sed -E 's/([^\\]|^)[(]/\1\\(/g; s/([^\\]|^)\)/\1\\)/g'
        return
    fi
    
    # Split content into tags and process each one
    split_tags "$content"
    local processed_tags=()
    
    for tag in "${split_tags_result[@]}"; do
        if is_tag_preserved "$tag"; then
            # Don't escape preserved tags
            processed_tags+=("$tag")
        else
            # Escape parentheses in non-preserved tags
            local escaped_tag=$(echo "$tag" | sed -E 's/([^\\]|^)[(]/\1\\(/g; s/([^\\]|^)\)/\1\\)/g')
            processed_tags+=("$escaped_tag")
        fi
    done
    
    join_tags "${processed_tags[@]}"
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
        # Check if tag should be preserved
        if is_tag_preserved "$tag"; then
            filtered_tags+=("$tag")
            continue
        fi
        
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
# PARAMETER PARSING FUNCTIONS
# ============================================================================

# Function to show usage information
show_usage() {
    cat >&2 << 'EOF'
Usage: process_txt_files.zsh [trigger_word] [class_word] [-p|--preserve tag1,tag2] [-p tag3]

Parameters:
  trigger_word          Trigger word to use (optional if auto-detectable from path)
  class_word           Class word to use (optional)
  -p, --preserve tags  Comma-separated list of tags to preserve from alias conversion
                       and removal. Can be specified multiple times.

Examples:
  process_txt_files.zsh                                    # Auto-detect from path
  process_txt_files.zsh cornflower                         # Specify trigger only
  process_txt_files.zsh cornflower flower                  # Specify trigger and class
  process_txt_files.zsh cornflower -p iris                 # Preserve single tag (short)
  process_txt_files.zsh cornflower --preserve iris         # Preserve single tag (long)
  process_txt_files.zsh cornflower -p iris,rose            # Preserve multiple tags
  process_txt_files.zsh cornflower -p iris -p hydrangea    # Multiple short flags
  process_txt_files.zsh cornflower -p iris --preserve rose # Mixed short/long flags

EOF
}

# Function to parse preserve tags from comma-separated string
parse_preserve_tags() {
    local preserve_string="$1"
    [[ -z "$preserve_string" ]] && return
    
    IFS=',' read -rA temp_tags <<< "$preserve_string"
    for tag in "${temp_tags[@]}"; do
        local trimmed_tag=$(trim_whitespace "$tag")
        [[ -n "$trimmed_tag" ]] && preserve_tags+=("$trimmed_tag")
    done
}

# Function to check if a tag should be preserved
is_tag_preserved() {
    local tag="$1"
    local preserved_tag
    for preserved_tag in "${preserve_tags[@]}"; do
        [[ "$tag" == "$preserved_tag" ]] && return 0
    done
    return 1
}

# Function to display preserved tags info
show_preserve_info() {
    if [[ ${#preserve_tags[@]} -gt 0 ]]; then
        local preserve_list
        preserve_list=$(join_tags "${preserve_tags[@]}")
        echo "Preserving tags: $preserve_list"
    else
        echo "No tags to preserve"
    fi
}

# Function to parse command line arguments
parse_arguments() {
    local args=("$@")
    local i=1
    local trigger=""
    local class=""
    local trigger_provided=false
    preserve_tags=()
    
    while [[ $i -le ${#args[@]} ]]; do
        case "${args[$i]}" in
            --preserve|-p)
                if [[ $i -eq ${#args[@]} || "${args[$((i+1))]}" =~ ^- ]]; then
                    echo "ERROR: -p/--preserve requires a value" >&2
                    show_usage
                    return 1
                fi
                local preserve_value="${args[$((i+1))]}"
                parse_preserve_tags "$preserve_value"
                i=$((i + 2))
                ;;
            --*)
                echo "ERROR: Unknown parameter: ${args[$i]}" >&2
                show_usage
                return 1
                ;;
            -*)
                echo "ERROR: Unknown parameter: ${args[$i]}" >&2
                show_usage
                return 1
                ;;
            *)
                if [[ -z "$trigger" && "$trigger_provided" == false ]]; then
                    trigger="${args[$i]}"
                    trigger_provided=true
                elif [[ -z "$class" ]]; then
                    class="${args[$i]}"
                else
                    echo "ERROR: Too many parameters" >&2
                    show_usage
                    return 1
                fi
                i=$((i + 1))
                ;;
        esac
    done
    
    # Set results to global variables
    parsed_trigger="$trigger"
    parsed_class="$class"
    parsed_trigger_provided="$trigger_provided"
}

# ============================================================================
# TRIGGER WORD FUNCTIONS
# ============================================================================

# Function to extract trigger and class words from current directory path
# Returns trigger_word and class_word via global variables
extract_trigger_and_class_from_path() {
    local current_dir=$(basename "$(pwd)")
    
    # Remove numeric prefix (e.g., "5_Doraemon" -> "Doraemon")
    local clean_dir=${current_dir#[0-9]*_}
    
    # Split on spaces and take max 2 parts
    local parts=(${(s: :)clean_dir})
    case ${#parts[@]} in
        1) 
            extracted_trigger="${parts[1]}"
            extracted_class=""
            ;;
        2) 
            extracted_trigger="${parts[1]}"
            extracted_class="${parts[2]}"
            ;;
        *) 
            extracted_trigger="${parts[1]}"
            extracted_class="${parts[2]}"
            ;;  # 3 or more parts, use first two
    esac
}

# Function to prompt user for trigger and class words
prompt_for_words() {
    echo "Could not auto-detect words from current path." >&2
    echo -n "Please enter the trigger word: "
    read trigger_word
    echo -n "Please enter the class word (or press Enter if none): "
    read class_word
    
    # Trim whitespace and validate
    trigger_word=$(trim_whitespace "$trigger_word")
    class_word=$(trim_whitespace "$class_word")
    
    if [[ -z "$trigger_word" ]]; then
        echo "ERROR: Trigger word cannot be empty" >&2
        return 1
    fi
    
    echo "Using provided trigger word: $trigger_word"
    [[ -n "$class_word" ]] && echo "Using provided class word: $class_word"
    
    # Return via global variables
    final_trigger="$trigger_word"
    final_class="$class_word"
}

# Function to get trigger and class words based on parameters
get_trigger_and_class_words() {
    # Parse command line arguments first
    if ! parse_arguments "$@"; then
        return 1
    fi
    
    # Handle trigger and class word resolution
    if [[ "$parsed_trigger_provided" == false ]]; then
        # Auto-detect mode
        extract_trigger_and_class_from_path
        if [[ -n "$extracted_trigger" && "$extracted_trigger" != "" ]]; then
            echo "Auto-detected trigger word from path: $extracted_trigger"
            [[ -n "$extracted_class" ]] && echo "Auto-detected class word from path: $extracted_class"
            final_trigger="$extracted_trigger"
            final_class="$extracted_class"
        else
            prompt_for_words || return 1
        fi
    elif [[ -z "$(trim_whitespace "$parsed_trigger")" ]]; then
        # Empty trigger provided explicitly
        echo "Using provided trigger word: $parsed_trigger"
        echo "ERROR: No trigger word provided or could be determined"
        return 1
    else
        # Use parsed values
        echo "Using provided trigger word: $parsed_trigger"
        [[ -n "$parsed_class" ]] && echo "Using provided class word: $parsed_class"
        final_trigger="$parsed_trigger"
        final_class="$parsed_class"
    fi
}

# Function to remove class word from content using tag processing
remove_class_word_from_content() {
    local content="$1"
    local class_word="$2"
    
    # If no class word, return content unchanged
    [[ -z "$class_word" ]] && { echo "$content"; return; }
    
    # Use the existing tag processing functions for reliable handling
    split_tags "$content"
    local filtered_tags=()
    
    for tag in "${split_tags_result[@]}"; do
        # Check if tag should be preserved
        if is_tag_preserved "$tag"; then
            filtered_tags+=("$tag")
            continue
        fi
        
        # Only skip tags that exactly match the class word
        if [[ "$tag" != "$class_word" ]]; then
            filtered_tags+=("$tag")
        fi
    done
    
    join_tags "${filtered_tags[@]}"
}

# Function to add prefix to content based on trigger and class words
add_prefix_to_content() {
    local content="$1"
    local trigger="$2"
    local class_word="$3"
    
    local prefix=""
    if [[ -n "$class_word" ]]; then
        prefix="$class_word, $trigger"
    else
        prefix="$trigger"
    fi
    
    if [[ -n "$content" ]]; then
        echo "$prefix, $content"
    else
        echo "$prefix"
    fi
}

# ============================================================================
# CONTENT PROCESSING FUNCTIONS
# ============================================================================

# Function to process content through all cleaning steps
process_content() {
    local content="$1"
    local trigger="$2"
    local class_word="$3"
    
    # Step 1: Escape parentheses
    content=$(escape_parentheses "$content")
    
    # Step 2: Remove unwanted patterns (including trigger word)
    content=$(remove_unwanted_patterns "$content" "$trigger")
    
    # Step 3: Remove class word from content
    content=$(remove_class_word_from_content "$content" "$class_word")
    
    # Step 4: Convert emoji tags
    content=$(convert_emoji_tags "$content")
    
    # Step 5: Remove standalone problematic tags
    content=$(remove_standalone_tags "$content")
    
    # Step 6: Clean up formatting
    content=$(cleanup_formatting "$content")
    
    # Step 7: Apply tag aliases
    content=$(apply_tag_aliases_to_content "$content")
    
    # Step 8: Remove duplicates
    content=$(remove_duplicate_tags "$content")
    
    echo "$content"
}

# Function to process a single file
process_single_file() {
    local file="$1"
    local trigger="$2"
    local class_word="$3"
    
    echo "Processing: $file"
    
    local content=$(cat "$file")
    local processed_content=$(process_content "$content" "$trigger" "$class_word")
    local final_content=$(add_prefix_to_content "$processed_content" "$trigger" "$class_word")
    
    printf "%s" "$final_content" > "$file"
}

# ============================================================================
# MAIN EXECUTION
# ============================================================================

# Main function
main() {
    # Get trigger and class words based on parameters
    if ! get_trigger_and_class_words "$@"; then
        exit 1
    fi
    
    # Validate that we have a trigger word
    if [[ -z "$final_trigger" ]]; then
        echo "ERROR: No trigger word provided or could be determined"
        exit 1
    fi
    
    # Show preserve information
    show_preserve_info
    
    # Load tag aliases
    load_tag_aliases
    
    # Display processing information
    if [[ -n "$final_class" ]]; then
        echo "Processing text files with trigger: $final_trigger, class: $final_class"
    else
        echo "Processing text files with trigger: $final_trigger"
    fi
    
    # Process all txt files in the current directory
    for file in *.txt; do
        [[ -f "$file" ]] && process_single_file "$file" "$final_trigger" "$final_class"
    done
    
    echo "Processing complete!"
}

# Run main function with all arguments
main "$@"
