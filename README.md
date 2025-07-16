# 🖼️ Image Dataset Preparation Tools

This project provides several practical tools for image dataset preparation. These scripts are designed for pre-processing datasets before AI training.

> [!TIP]  
> Add this project's root directory to your PATH to execute scripts from anywhere and process files in your current working directory.

> [!CAUTION]  
> All three tools overwrite original files. Always back up important data first!

---

## 📝 Overview

-   **process_txt_files.zsh**: Batch cleans and standardizes all `.txt` tag files in the current working directory, removing noise and unifying format based on a user-provided trigger keyword.
-   **resize_images.zsh**: Automatically resizes all images in the current working directory so the long side is 1024px, skipping images that are already smaller.
-   **fetch_tags.py**: Fetches tags from Danbooru/Gelbooru using the MD5 in the image filename from the current working directory and writes them to a corresponding `.txt` file.
-   **validate_dataset.zsh**: Validates image dataset completeness and quality by checking image files and corresponding tag files.

---

## 🛠️ Tool Usage & Requirements

### ⚙️ Setup

First, add this project's root directory to your PATH to run scripts from anywhere:

```bash
# Add to your shell configuration file (.bashrc, .zshrc, etc.)
export PATH="/path/to/image-dataset-prep-tools:$PATH"
```

After setup, navigate to any directory containing your dataset files and run the scripts directly.

### 1️⃣ process_txt_files.zsh

**Requirements:**

-   `zsh` shell

**Function:**

-   Batch processes all `.txt` tag files in the current working directory, cleans content based on a user-input trigger keyword, removes noise tags, and prepends `1girl, {trigger}` to each line.

**Usage:**

```bash
# Navigate to your dataset directory first
cd /path/to/your/dataset
process_txt_files.zsh
```

-   The script will prompt for a trigger keyword, then process all `.txt` files automatically.
-   Original files will be overwritten. **Back up important files first!**

**Processing details:**

-   Replaces all `(` with `\(` and `)` with `\)`.
-   Removes `1girl`, the trigger keyword, and commentary/commission-related noise tags.
-   Cleans up redundant commas and spaces.
-   Prepends `1girl, {trigger}` to the beginning of each file's content.

---

### 2️⃣ resize_images.zsh

**Requirements:**

-   `zsh` shell
-   [ImageMagick](https://imagemagick.org/) (`magick` command)

**Function:**

-   Resizes all `.jpg` and `.png` images in the current working directory so the long side is 1024px, keeping aspect ratio.
-   Images with both sides smaller than 1024px are skipped.

**Usage:**

```bash
# Navigate to your dataset directory first
cd /path/to/your/dataset
resize_images.zsh
```

-   Original images will be overwritten. **Back up important files first!**

**Processing details:**

-   Automatically detects landscape or portrait orientation and resizes the long side.
-   Only processes `.jpg` and `.png` files.

---

### 3️⃣ fetch_tags.py

**Requirements:**

-   Python 3.12+
-   [`requests<3`](https://pypi.org/project/requests/)
    -   If you use `uv run`, all requirements are managed automatically, no manual installation needed.
    -   If you do not use `uv`, you must manually install dependencies with `pip install requests<3`.

**Function:**

-   Scans the current working directory for images named `{id}_{md5}.{ext}` and fetches tags from Danbooru by MD5. If not found, falls back to Gelbooru.
-   Tags are written to a `.txt` file with the same name as the image, comma-separated.

**Usage:**

```bash
# Navigate to your dataset directory first
cd /path/to/your/dataset
uv run fetch_tags.py
```

-   No extra parameters needed; just run the script with uv run.
-   Note: This script requires `uv` to manage Python dependencies automatically.

**Filename pattern:**

-   Only processes files named `{id}_{md5}.{ext}` (supports jpg, jpeg, png, gif).
-   The generated tag file will have the same name as the image, with a `.txt` extension.

**Notes:**

-   1-second delay between each image query to avoid being rate-limited.
-   If neither site returns tags, an error will be shown in the logs.
-   **API rate limits:** Fetching tags may encounter rate limiting; do not run the script in parallel.

---

### 4️⃣ validate_dataset.zsh

**Requirements:**
- `zsh` shell  
- [ImageMagick](https://imagemagick.org/) (`magick identify` command)

**Function:**
- Validates image dataset completeness and quality by checking image files and corresponding tag files
- Automatically extracts trigger word from directory path or accepts it as parameter
- Provides comprehensive validation report with color-coded output

**Usage:**
```bash
# Navigate to your dataset directory first
cd /path/to/your/dataset

# Auto-detect trigger word from path
validate_dataset.zsh

# Or specify trigger word manually  
validate_dataset.zsh "your_trigger_word"
```

**Validation checks:**
- Image files have corresponding .txt files
- Image dimensions are at least 500px on both sides
- Trigger word is present in tag files
- Tag count is between 5-150 per file
- No orphaned .txt files exist

**Output colors:**
- Red: Errors that must be fixed
- Yellow: Warnings that should be reviewed
- Default: Informational messages
- Gray: Verbose details

---

## 💡 Notes

-   **Dependency installation:**
    -   `resize_images.zsh` requires ImageMagick.
    -   `validate_dataset.zsh` requires zsh and ImageMagick.
    -   `fetch_tags.py` requires `requests<3`, recommended to use uv for management.

---

## 📜 License

<img src="https://github.com/user-attachments/assets/f4d883c0-80d1-4980-a9f4-eebf31a28b02" alt="gplv3" width="300" />

[GNU GENERAL PUBLIC LICENSE Version 3](LICENSE)

This program is free software: you can redistribute it and/or modify it under the terms of the GNU General Public License as published by the Free Software Foundation, either version 3 of the License, or (at your option) any later version.

This program is distributed in the hope that it will be useful, but WITHOUT ANY WARRANTY; without even the implied warranty of MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE. See the GNU General Public License for more details.

You should have received a copy of the GNU General Public License along with this program. If not, see <https://www.gnu.org/licenses/>.
