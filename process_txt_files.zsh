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
# Usage: process_txt_files.zsh (from any directory)

# Prompt user for trigger input
echo "What's the trigger?"
read trigger

echo "Processing text files with trigger: $trigger"

# Process all txt files in the current directory
for file in *.txt; do
    if [[ -f "$file" ]]; then
        echo "Processing: $file"

        # Read the original content
        content=$(cat "$file")
        
        # Step 1: Replace ( with \( and ) with \)
        content=${content//\(/\\(}
        content=${content//\)/\\)}
        
        # Step 2: Remove specific patterns
        # Remove "1girl" (raw text)
        content=${content//1girl/}
        
        # Remove the trigger variable
        content=${content//$trigger/}
        
        # Remove ", commentary" followed by any word characters (regex pattern)
        content=${content//, commentary[[:alnum:]_]*/}
        
        # Remove ", " followed by word characters and "_commentary" (regex pattern)
        content=${content//, [[:alnum:]_]*_commentary/}
        
        # Remove ", (;)" (raw text)
        content=${content//, \\\(;\\\)/}
        
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
        
        # Step 3: Add "1girl, {trigger}" to the front
        if [[ -n "$content" ]]; then
            new_content="1girl, $trigger, $content"
        else
            new_content="1girl, $trigger"
        fi
        
        # Write the new content to the file (no extra newline)
        printf "%s" "$new_content" > "$file"

    fi
done

echo "Processing complete!"
