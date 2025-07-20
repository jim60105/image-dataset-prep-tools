# 🖼️ Image Dataset Preparation Tools

![Zsh](https://img.shields.io/badge/Zsh-F15A24?logo=Zsh&logoColor=white) ![Python](https://img.shields.io/badge/Python-3776AB?logo=Python&logoColor=white) [![CodeFactor](https://www.codefactor.io/repository/github/jim60105/image-dataset-prep-tools/badge)](https://www.codefactor.io/repository/github/jim60105/image-dataset-prep-tools) [![codecov](https://codecov.io/gh/jim60105/image-dataset-prep-tools/graph/badge.svg?token=eCb26rs5Ma)](https://codecov.io/gh/jim60105/image-dataset-prep-tools) [![🧪 Shell Script Testing with Coverage](https://github.com/jim60105/image-dataset-prep-tools/actions/workflows/test.yml/badge.svg)](https://github.com/jim60105/image-dataset-prep-tools/actions/workflows/test.yml) [![🔄 Update Danbooru Tag Aliases Data](https://github.com/jim60105/image-dataset-prep-tools/actions/workflows/update-danbooru-data.yml/badge.svg)](https://github.com/jim60105/image-dataset-prep-tools/actions/workflows/update-danbooru-data.yml)  

This project provides several practical tools for image dataset preparation. These scripts are designed for pre-processing datasets before AI training.

> [!TIP]  
> Add this project's `/src/` directory to your PATH to execute scripts from anywhere and process files in your current working directory.

> [!CAUTION]  
> All tools overwrite original files. Always back up important data first!

---

## 📝 Overview

- **process_txt_files.zsh**: Batch cleans and standardizes all `.txt` tag files in the current working directory, removing noise and unifying format based on a user-provided trigger keyword.
- **resize_images.zsh**: Automatically resizes all images in the current working directory so the long side is 1024px, skipping images that are already smaller.
- **fetch_tags.py**: Fetches tags from Danbooru/Gelbooru using the MD5 in the image filename from the current working directory and writes them to a corresponding `.txt` file.
- **validate_dataset.zsh**: Validates image dataset completeness and quality by checking image files and corresponding tag files.
- **scrape_danbooru_aliases.zsh**: Scrapes all Danbooru tag aliases from the API and saves them to a CSV file for dataset tag normalization.

---

## 🛠️ Tool Usage & Requirements

### ⚙️ Setup

First, add this project's `/src/` directory to your PATH to run scripts from anywhere:

```bash
# Add to your shell configuration file (.bashrc, .zshrc, etc.)
export PATH="/path/to/image-dataset-prep-tools/src:$PATH"
```

After setup, navigate to any directory containing your dataset files and run the scripts directly.

### 1️⃣ process_txt_files.zsh

**Requirements:**

- `zsh` shell

**Function:**

- Batch processes all `.txt` tag files in the current working directory, cleans content based on a user-input trigger keyword, removes noise tags, and prepends `{trigger}` to each line.
- Automatically applies Danbooru tag aliases from `data/danbooru_tag_aliases.csv` to standardize tag names.
- Removes duplicate tags from each file after alias processing.

**Usage:**

```bash
# Navigate to your dataset directory first
cd /path/to/your/dataset

# Auto-detect trigger from directory name (e.g., 3_blue_flower -> blue_flower)
process_txt_files.zsh

# Or specify trigger word manually
process_txt_files.zsh "my_trigger"
```

- The script can auto-detect trigger words from directory names (format: `number_trigger_word`)
- Or you can provide a trigger keyword as a parameter
- Requires `data/danbooru_tag_aliases.csv` file for tag alias functionality.
- Original files will be overwritten. **Back up important files first!**

**Processing details:**

- Replaces all `(` with `\(` and `)` with `\)`.
- Removes standalone trigger keywords while preserving compound words (e.g., keeps `blue_flower` when trigger is `flower`).
- Removes commentary/commission-related noise tags.
- Cleans up redundant commas and spaces.
- Applies Danbooru tag aliases to standardize tag names.
- Removes duplicate tags from each file after alias processing.
- Prepends `{trigger}` to the beginning of each file's content.

---

### 2️⃣ resize_images.zsh

**Requirements:**

- `zsh` shell
- [ImageMagick](https://imagemagick.org/) (`magick` command)

**Function:**

- Resizes all `.jpg` and `.png` images in the current working directory so the short side is 1024px, keeping aspect ratio.
- Images with any side smaller than 1024px are skipped.

**Usage:**

```bash
# Navigate to your dataset directory first
cd /path/to/your/dataset
resize_images.zsh
```

- Original images will be overwritten. **Back up important files first!**

**Processing details:**

- Automatically detects landscape or portrait orientation and resizes the short side.
- Only processes `.jpg` and `.png` files.

---

### 3️⃣ fetch_tags.py

**Requirements:**

- Python 3.12+
- [`requests<3`](https://pypi.org/project/requests/)
  - If you use `uv run`, all requirements are managed automatically, no manual installation needed.
  - If you do not use `uv`, you must manually install dependencies with `pip install requests<3`.

**Function:**

- Scans the current working directory for images named `{id}_{md5}.{ext}` and fetches tags from Danbooru by MD5. If not found, falls back to Gelbooru.
- Tags are written to a `.txt` file with the same name as the image, comma-separated.

**Usage:**

```bash
# Navigate to your dataset directory first
cd /path/to/your/dataset
uv run fetch_tags.py
```

- No extra parameters needed; just run the script with uv run.
- Note: This script requires `uv` to manage Python dependencies automatically.

**Filename pattern:**

- Only processes files named `{id}_{md5}.{ext}` (supports jpg, jpeg, png, gif).
- The generated tag file will have the same name as the image, with a `.txt` extension.

**Notes:**

- 1-second delay between each image query to avoid being rate-limited.
- If neither site returns tags, an error will be shown in the logs.
- **API rate limits:** Fetching tags may encounter rate limiting; do not run the script in parallel.

---

### 4️⃣ validate_dataset.zsh

**Requirements:**

- `zsh` shell
- [ImageMagick](https://imagemagick.org/) (`magick identify` command)
- [czkawka_cli](https://github.com/qarmin/czkawka) (optional, for similarity detection)

**Function:**

- Validates image dataset completeness and quality by checking image files and corresponding tag files
- Automatically extracts trigger word from directory path or accepts it as parameter
- Detects duplicate tags within each .txt file using efficient comma-separated parsing
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
- Tag count is between 5-100 per file
- No duplicate tags within each file
- No orphaned .txt files exist
- Similar images detection (High similarity preset) - requires czkawka_cli

**Output colors:**

- Red: Errors that must be fixed
- Yellow: Warnings that should be reviewed
- Default: Informational messages
- Gray: Verbose details

---

### 5️⃣ scrape_danbooru_aliases.zsh

**Requirements:**

- `zsh` shell
- `curl` for HTTP requests
- `jq` for JSON parsing
- `bc` for rate limiting calculations
- Optional: `DANBOORU_LOGIN` and `DANBOORU_APIKEY` environment variables for authentication

**Function:**

- Scrapes all Danbooru tag aliases from the API and saves them to a CSV file
- Supports pagination to fetch complete dataset with a maximum of 1000 pages
- Data is sorted by tag count (most popular aliases first) for better relevance
- Implements proper rate limiting (10 requests/second max)
- Improved CSV data validation: as long as the API returns valid JSON and the CSV conversion is successful, the data is accepted (no longer misclassifies valid data as invalid)
- Designed for danbooru.donmai.us, easily configurable for test environments

**Usage:**

```bash
# Navigate to your working directory
cd /path/to/your/workspace

# Optional: Set authentication credentials
export DANBOORU_LOGIN="your_username"
export DANBOORU_APIKEY="your_api_key"

# Run the scraper
scrape_danbooru_aliases.zsh
```

**Output:**

- Creates `data/` directory in current working directory
- Generates CSV file: `danbooru_tag_aliases.csv`
- Data sorted by tag count for better relevance (most popular aliases first)
- Maximum 1000 pages to prevent excessive API usage
- CSV columns: id, antecedent_name, consequent_name, creator_id, forum_topic_id, status, created_at, updated_at, approver_id, forum_post_id, reason

**Safety:**

- Uses only GET requests (no DELETE or modification operations)
- Implements strict rate limiting to comply with API limits (10 requests/second)
- Authentication via environment variables only
- Proper error handling for network issues and API errors

---

## 🧪 Testing

This project uses [ShellSpec](https://shellspec.info/) for comprehensive BDD testing of all zsh scripts.

> [!NOTE]
> All test cases involving the `magick` command **must** mock `magick` to avoid failures on CI runners without ImageMagick installed.

### 📋 Test Coverage

- 🎯 **Target**: 75% minimum coverage for all zsh scripts
- 🧪 **Total Tests**: 44+ examples across all scripts
- 📊 **Framework**: ShellSpec with BDD approach
- 🔄 **CI/CD**: Automated testing on every commit

### 🛠️ Quick Start

```bash
# Install ShellSpec
curl -fsSL https://git.io/shellspec | sh

# Run all tests
cd spec/
shellspec

# Run with coverage
shellspec --kcov ../coverage
```

### 📖 Writing Tests

For detailed guidelines on writing effective BDD tests for zsh scripts, see our comprehensive [Testing Guideline](docs/testing-guideline.md).

### 🤝 Contributing

When adding new features:

1. Write tests first (TDD approach)
2. Follow our [Testing Guideline](docs/testing-guideline.md)
3. Ensure 75%+ coverage
4. Verify all existing tests pass

## 💡 Notes

- **Dependencies:**
  - All the zsh scripts require zsh shell.
  - `resize_images.zsh` requires ImageMagick.
  - `validate_dataset.zsh` requires ImageMagick and czkawka_cli (Optional).
  - `fetch_tags.py` requires `requests<3`, recommended to use uv for management.
  - `scrape_danbooru_aliases.zsh` requires curl, jq, and bc.

### Installing czkawka_cli (Optional)

For similarity detection functionality in `validate_dataset.zsh`, install [czkawka_cli](https://github.com/qarmin/czkawka)

---

## 🤖 Automated Data Updates

This repository includes automated weekly updates for the Danbooru tag aliases dataset via GitHub Actions.

### Workflow Features

- **Schedule**: Runs every Sunday at 02:00 UTC
- **Branch Management**: Uses `ci/update-data` branch for changes
- **Safe Operations**: Atomic file updates with temporary file handling
- **Automated PRs**: Creates pull requests for review before merging
- **Manual Trigger**: Can be run manually via GitHub Actions UI

### Automated Process

1. Checks out or creates the `ci/update-data` branch
2. Runs `scrape_danbooru_aliases.zsh` to fetch latest data
3. Commits changes with meaningful commit messages
4. Opens a pull request for review if changes are detected
5. Includes detailed PR description with update information

The automation ensures the dataset stays current while maintaining proper review processes.

---

## 📜 License

<img src="https://github.com/user-attachments/assets/f4d883c0-80d1-4980-a9f4-eebf31a28b02" alt="gplv3" width="300" />

[GNU GENERAL PUBLIC LICENSE Version 3](LICENSE)

Copyright (C) 2025 Jim Chen <Jim@ChenJ.im>.

This program is free software: you can redistribute it and/or modify it under the terms of the GNU General Public License as published by the Free Software Foundation, either version 3 of the License, or (at your option) any later version.

This program is distributed in the hope that it will be useful, but WITHOUT ANY WARRANTY; without even the implied warranty of MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE. See the GNU General Public License for more details.

You should have received a copy of the GNU General Public License along with this program. If not, see <https://www.gnu.org/licenses/>.
