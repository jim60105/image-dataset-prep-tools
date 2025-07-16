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
# Validates image dataset completeness and quality by checking image files and corresponding tag files.
# Automatically extracts trigger word from directory path or accepts it as parameter.
# Usage: validate_dataset.zsh [trigger_word] (from any directory)

# Set nullglob option to handle cases where no files match the pattern
setopt nullglob

# Color codes for output
RED='\033[31m'
YELLOW='\033[33m'
GRAY='\033[90m'
RESET='\033[0m'

# Counters for statistics
total_images=0
total_texts=0
missing_txt_files=0
orphaned_txt_files=0
error_count=0
warning_count=0

# Arrays to store detailed problems
declare -a error_messages
declare -a warning_messages

# Function to print colored messages
print_error() {
    echo -e "${RED}ERROR: $1${RESET}"
    error_messages+=("$1")
    ((error_count++))
}

print_warning() {
    echo -e "${YELLOW}WARNING: $1${RESET}"
    warning_messages+=("$1")
    ((warning_count++))
}

print_info() {
    echo "$1"
}

print_verbose() {
    echo -e "${GRAY}$1${RESET}"
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
        print_info "Using provided trigger word: $trigger"
    elif [[ $# -eq 0 ]]; then
        # Zero parameter mode - try to extract from path
        trigger=$(extract_trigger_from_path)
        if [[ -n "$trigger" && "$trigger" != "" ]]; then
            print_info "Auto-detected trigger word from path: $trigger"
        else
            # Interactive mode
            print_info "Could not auto-detect trigger word from current path."
            echo -n "Please enter the trigger word: "
            read trigger
            print_info "Using provided trigger word: $trigger"
        fi
    else
        print_error "Too many parameters. Usage: validate_dataset.zsh [trigger_word]"
        exit 1
    fi
    
    echo "$trigger"
}

# Function to validate image files
validate_image_files() {
    local trigger_word="$1"
    
    print_info "Validating image files..."
    
    for img in *.jpg *.png; do
        [[ ! -f "$img" ]] && continue
        ((total_images++))
        
        local basename="${img%.*}"
        local txt_file="${basename}.txt"
        
        # Check for corresponding .txt file
        if [[ ! -f "$txt_file" ]]; then
            print_error "Missing .txt file for image: $img"
            ((missing_txt_files++))
        fi
        
        # Check image dimensions using ImageMagick
        if command -v identify >/dev/null 2>&1; then
            local dimensions
            if dimensions=$(identify -format "%w %h" "$img" 2>/dev/null); then
                local width height
                read width height <<< "$dimensions"
                if [[ -n "$width" && -n "$height" ]]; then
                    if (( width < 500 || height < 500 )); then
                        print_warning "Image $img has small dimensions: ${width}x${height} (should be >= 500px on both sides)"
                    fi
                    print_verbose "Image $img: ${width}x${height}"
                else
                    print_warning "Could not read dimensions for image: $img"
                fi
            else
                print_warning "Could not process image: $img"
            fi
        else
            print_warning "ImageMagick not available - skipping dimension checks"
        fi
    done
}

# Function to validate text files
validate_text_files() {
    local trigger_word="$1"
    
    print_info "Validating text files..."
    
    for txt in *.txt; do
        [[ ! -f "$txt" ]] && continue
        ((total_texts++))
        
        local basename="${txt%.*}"
        local content=$(cat "$txt" 2>/dev/null)
        
        # Check if trigger word is present
        if [[ ! "$content" =~ .*${trigger_word}.* ]]; then
            print_error "Trigger word '${trigger_word}' not found in: $txt"
        fi
        
        # Count tags (split by comma)
        local tag_count=$(echo "$content" | tr ',' '\n' | wc -l)
        if (( tag_count < 5 )); then
            print_warning "Too few tags ($tag_count) in file: $txt (should be >= 5)"
        elif (( tag_count > 100 )); then
            print_warning "Too many tags ($tag_count) in file: $txt (should be <= 100)"
        fi
        print_verbose "File $txt: $tag_count tags"
        
        # Check for orphaned .txt files (no corresponding image)
        local has_image=false
        for ext in jpg png; do
            if [[ -f "${basename}.${ext}" ]]; then
                has_image=true
                break
            fi
        done
        
        if [[ "$has_image" == false ]]; then
            print_warning "Orphaned .txt file (no corresponding image): $txt"
            ((orphaned_txt_files++))
        fi
    done
}

# Function to print statistics report
print_statistics() {
    print_info ""
    print_info "=== VALIDATION STATISTICS ==="
    print_info "Total image files: $total_images"
    print_info "Total text files: $total_texts"
    print_info "Missing .txt files: $missing_txt_files"
    print_info "Orphaned .txt files: $orphaned_txt_files"
    print_info "Total errors: $error_count"
    print_info "Total warnings: $warning_count"
    
    if [[ $error_count -gt 0 || $warning_count -gt 0 ]]; then
        print_info ""
        print_info "=== DETAILED PROBLEM LIST ==="
        
        if [[ $error_count -gt 0 ]]; then
            print_info ""
            echo -e "${RED}ERRORS ($error_count):${RESET}"
            for msg in "${error_messages[@]}"; do
                echo -e "  ${RED}- $msg${RESET}"
            done
        fi
        
        if [[ $warning_count -gt 0 ]]; then
            print_info ""
            echo -e "${YELLOW}WARNINGS ($warning_count):${RESET}"
            for msg in "${warning_messages[@]}"; do
                echo -e "  ${YELLOW}- $msg${RESET}"
            done
        fi
    fi
    
    print_info ""
    if [[ $error_count -eq 0 && $warning_count -eq 0 ]]; then
        print_info "✅ Dataset validation completed successfully - no issues found!"
    elif [[ $error_count -eq 0 ]]; then
        print_info "✅ Dataset validation completed with warnings only."
    else
        print_info "❌ Dataset validation completed with errors that need to be fixed."
    fi
}

# Main execution
main() {
    print_info "Starting dataset validation in: $(pwd)"
    
    # Get trigger word based on parameters
    local trigger_word=""
    
    if [[ $# -eq 1 ]]; then
        # Single parameter mode
        trigger_word="$1"
        print_info "Using provided trigger word: $trigger_word"
    elif [[ $# -eq 0 ]]; then
        # Zero parameter mode - try to extract from path
        trigger_word=$(extract_trigger_from_path)
        if [[ -n "$trigger_word" && "$trigger_word" != "" ]]; then
            print_info "Auto-detected trigger word from path: $trigger_word"
        else
            # Interactive mode
            print_info "Could not auto-detect trigger word from current path."
            echo -n "Please enter the trigger word: "
            read trigger_word
            print_info "Using provided trigger word: $trigger_word"
        fi
    else
        print_error "Too many parameters. Usage: validate_dataset.zsh [trigger_word]"
        exit 1
    fi
    
    if [[ -z "$trigger_word" ]]; then
        print_error "No trigger word provided or could be determined"
        exit 1
    fi
    
    # Validate image files
    validate_image_files "$trigger_word"
    
    # Validate text files
    validate_text_files "$trigger_word"
    
    # Print final statistics
    print_statistics
}

# Execute main function with all arguments
main "$@"
