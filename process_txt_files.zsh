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
        echo "Using provided trigger word: $trigger"
    elif [[ $# -eq 0 ]]; then
        # Zero parameter mode - try to extract from path
        trigger=$(extract_trigger_from_path)
        if [[ -n "$trigger" && "$trigger" != "" ]]; then
            echo "Auto-detected trigger word from path: $trigger"
        else
            # Interactive mode
            echo "Could not auto-detect trigger word from current path."
            echo -n "Please enter the trigger word: "
            read trigger
            echo "Using provided trigger word: $trigger"
        fi
    else
        echo "ERROR: Too many parameters. Usage: process_txt_files.zsh [trigger_word]"
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

echo "Processing text files with trigger: $trigger"

# Process all txt files in the current directory
for file in *.txt; do
    if [[ -f "$file" ]]; then
        echo "Processing: $file"

        # Read the original content
        content=$(cat "$file")
        
        # Step 1: Replace ( with \( and ) with \)
        content=${content///\(/\(}
        content=${content///\)/\)}
        content=${content//\(/\\(}
        content=${content//\)/\\)}
        
        # Step 2: Remove specific patterns
        # Remove the trigger variable
        content=${content//$trigger/}
        
        # Remove ", commentary" followed by any word characters (regex pattern)
        content=${content//, commentary[[:alnum:]_]*/}
        
        # Remove ", " followed by word characters and "_commentary" (regex pattern)
        content=${content//, [[:alnum:]_]*_commentary/}
        
        # Remove ", (;)" (raw text)
        content=${content//, \\\(;\\\)/}

        # Remove ", _," (raw text)
        content=${content//, \\\(_\\\)/,}

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
        
        # Step 3: Add "{trigger}" to the front
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
