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

# Function to load Danbooru tag aliases
load_tag_aliases() {
    # Get the directory where this script is located
    local script_dir="$(dirname "$(realpath "${(%):-%x}")")"
    local csv_file="$script_dir/data/danbooru_tag_aliases.csv"
    declare -gA tag_aliases
    
    if [[ ! -f "$csv_file" ]]; then
        echo "WARNING: Tag aliases file not found: $csv_file" >&2
        return 1
    fi
    
    echo "Loading tag aliases from: $csv_file" >&2
    
    # Read CSV file and build associative array (skip header line)
    # Only include active aliases
    local line_count=0
    while IFS=',' read -r id antecedent_name consequent_name creator_id forum_topic_id alias_status rest; do
        ((line_count++))
        
        # Skip header line
        [[ $line_count -eq 1 ]] && continue
        
        # Remove quotes from tag names
        local clean_antecedent=${antecedent_name//\"/}
        local clean_consequent=${consequent_name//\"/}
        
        # Store in associative array
        tag_aliases[$clean_antecedent]=$clean_consequent
    done < "$csv_file"
    
    echo "Loaded ${#tag_aliases[@]} active tag aliases" >&2
    return 0
}

# Function to apply tag aliases to a single tag
apply_tag_alias() {
    local tag="$1"
    
    # Check if tag exists in aliases
    if [[ -n "${tag_aliases[$tag]}" ]]; then
        echo "${tag_aliases[$tag]}"
    else
        echo "$tag"
    fi
}

# Function to remove duplicate tags from content
remove_duplicate_tags() {
    local content="$1"
    
    # Use associative array to track seen tags
    declare -A seen_tags
    declare -a unique_tags
    
    # Split tags by comma
    local tags_array
    IFS=',' read -rA tags_array <<< "$content"
    
    for tag in "${tags_array[@]}"; do
        # Trim whitespace from beginning and end
        tag=$(echo "$tag" | sed 's/^[[:space:]]*//;s/[[:space:]]*$//')
        
        # Skip empty tags
        [[ -z "$tag" ]] && continue
        
        # Check if tag already exists
        if [[ -z "${seen_tags[$tag]}" ]]; then
            seen_tags[$tag]=1
            unique_tags+=("$tag")
        fi
    done
    
    # Join unique tags back with commas
    local result=""
    for ((i=1; i<=${#unique_tags[@]}; i++)); do
        if [[ $i -eq 1 ]]; then
            result="${unique_tags[$i]}"
        else
            result="$result, ${unique_tags[$i]}"
        fi
    done
    
    echo "$result"
}

# Function to extract trigger word from current directory path
extract_trigger_from_path() {
    local current_dir=$(basename "$(pwd)")
    local trigger=""
    
    # Remove numeric prefix (e.g., "5_Doraemon" -> "Doraemon")
    local clean_dir=${current_dir##[0-9]*_}
    
    # Split on spaces and take max 2 parts
    local parts=(${(s: :)clean_dir})
    if [[ ${#parts[@]} -eq 1 ]]; then
        trigger="${parts[1]}"
        elif [[ ${#parts[@]} -eq 2 ]]; then
        trigger="${parts[2]}, ${parts[1]}"
        elif [[ ${#parts[@]} -gt 2 ]]; then
        trigger="${parts[2]}, ${parts[1]}"
    fi
    
    echo "$trigger"
}

# Function to get trigger word based on parameters
get_trigger_word() {
    local trigger=""
    
    if [[ $# -eq 1 ]]; then
        # Single parameter mode
        trigger="$1"
        echo "Using provided trigger word: $trigger" >&2
        elif [[ $# -eq 0 ]]; then
        # Zero parameter mode - try to extract from path
        trigger=$(extract_trigger_from_path)
        if [[ -n "$trigger" && "$trigger" != "" ]]; then
            echo "Auto-detected trigger word from path: $trigger" >&2
        else
            # Interactive mode
            echo "Could not auto-detect trigger word from current path." >&2
            echo -n "Please enter the trigger word: " >&2
            read trigger
            echo "Using provided trigger word: $trigger" >&2
        fi
    else
        echo "ERROR: Too many parameters. Usage: process_txt_files.zsh [trigger_word]" >&2
        exit 1
    fi
    echo "$trigger"
}

# Get trigger word based on parameters
trigger=$(get_trigger_word "$@")

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
    if [[ -f "$file" ]]; then
        echo "Processing: $file"
        
        # Read the original content
        content=$(cat "$file")
        
        # Step 1: Replace ( with \( and ) with \) (only if not already escaped)
        content=$(echo "$content" | sed -E 's/([^\\]|^)[(]/\1\\(/g; s/([^\\]|^)\)/\1\\)/g')
        
        # Step 2: Remove specific patterns
        # Remove the trigger variable
        content=${content//$trigger/}
        
        # Remove ", commentary" followed by any word characters (regex pattern)
        content=${content//, commentary[[:alnum:]_]*/}
        
        # Remove ", " followed by word characters and "_commentary" (regex pattern)
        content=${content//, [[:alnum:]_]*_commentary/}
        
        # Remove ", (;)" (raw text)
        content=${content//, \\(;\\)/}
        
        # Remove ", _," (raw text)
        content=${content//, \\(_\\)/,}
        
        # Convert ', _w,' to ', :w,' for emoji tag support
        content=$(echo "$content" | sed -E 's/, _([a-zA-Z0-9]),/, :\1,/g')
        
        # Remove ', s,' as a standalone tag
        content=$(echo "$content" | sed -E 's/, s,/,/g')
        
        # Remove ", virtual_youtuber" (raw text)
        content=${content//, virtual_youtuber/}
        
        # Remove ", " followed by word characters and "_commission" (regex pattern)
        content=${content//, [[:alnum:]_]*_commission/}
        
        # Remove ", commission" (raw text)
        content=${content//, commission/}
        
        # Clean up multiple commas and spaces
        content=${content//,, /, }
        content=${content//,,/,}
        content=${content//, ,/,}
        
        # Remove leading comma and space if present
        content=${content#, }
        
        # Remove trailing comma and space if present
        content=${content%, }
        
        # Step 4: Apply tag aliases and handle duplicates
        if [[ ${#tag_aliases[@]} -gt 0 ]]; then
            # Split content into tags and apply aliases
            local tags_array
            IFS=',' read -rA tags_array <<< "$content"
            
            local processed_tags=()
            for tag in "${tags_array[@]}"; do
                # Trim whitespace
                tag=$(echo "$tag" | sed 's/^[[:space:]]*//;s/[[:space:]]*$//')
                
                # Skip empty tags
                [[ -z "$tag" ]] && continue
                
                # Apply alias if exists
                local processed_tag=$(apply_tag_alias "$tag")
                processed_tags+=("$processed_tag")
            done
            
            # Rebuild content with processed tags
            content=""
            for ((i=1; i<=${#processed_tags[@]}; i++)); do
                if [[ $i -eq 1 ]]; then
                    content="${processed_tags[$i]}"
                else
                    content="$content, ${processed_tags[$i]}"
                fi
            done
        fi
        
        # Step 5: Remove duplicate tags
        content=$(remove_duplicate_tags "$content")
        
        # Step 6: Add "{trigger}" to the front
        if [[ -n "$content" ]]; then
            new_content="$trigger, $content"
        else
            new_content="$trigger"
        fi
        
        # Write the new content to the file (no extra newline)
        printf "%s" "$new_content" > "$file"
        
    fi
done

echo "Processing complete!"
