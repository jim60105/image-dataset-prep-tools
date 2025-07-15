# Image Dataset Preparation Tools

This project provides several practical tools for image dataset preparation. These scripts are designed for pre-processing datasets before AI training.

---

## Table of Contents

-   [Overview](#overview)
-   [Tool Usage & Requirements](#tool-usage--requirements)
    -   [1. process_txt_files.zsh](#1-processtxtfileszsh)
    -   [2. resize_images.zsh](#2-resizeimageszsh)
    -   [3. fetch_tags.py](#3-fetchtagspy)
-   [FAQ & Notes](#faq--notes)

---

## Overview

-   **process_txt_files.zsh**: Batch cleans and standardizes all `.txt` tag files in the current directory, removing noise and unifying format based on a user-provided trigger keyword.
-   **resize_images.zsh**: Automatically resizes all images in the folder so the long side is 1024px, skipping images that are already smaller.
-   **fetch_tags.py**: Fetches tags from Danbooru/Gelbooru using the MD5 in the image filename and writes them to a corresponding `.txt` file.

---

## Tool Usage & Requirements

### 1. process_txt_files.zsh

**Requirements:**

-   `zsh` shell

**Function:**

-   Batch processes all `.txt` tag files in the current directory, cleans content based on a user-input trigger keyword, removes noise tags, and prepends `1girl, {trigger}` to each line.

**Usage:**

```bash
zsh process_txt_files.zsh
```

-   The script will prompt for a trigger keyword, then process all `.txt` files automatically.
-   Original files will be overwritten. **Back up important files first!**

**Processing details:**

-   Replaces all `(` with `\(` and `)` with `\)`.
-   Removes `1girl`, the trigger keyword, and commentary/commission-related noise tags.
-   Cleans up redundant commas and spaces.
-   Prepends `1girl, {trigger}` to the beginning of each file's content.

---

### 2. resize_images.zsh

**Requirements:**

-   `zsh` shell
-   [ImageMagick](https://imagemagick.org/) (`magick` command)

**Function:**

-   Resizes all `.jpg` and `.png` images in the current directory so the long side is 1024px, keeping aspect ratio.
-   Images with both sides smaller than 1024px are skipped.

**Usage:**

```bash
zsh resize_images.zsh
```

-   Original images will be overwritten. **Back up important files first!**

**Processing details:**

-   Automatically detects landscape or portrait orientation and resizes the long side.
-   Only processes `.jpg` and `.png` files.

---

### 3. fetch_tags.py

**Requirements:**

-   Python 3.11+
-   [`requests<3`](https://pypi.org/project/requests/)
    -   If you use `uv run`, all requirements are managed automatically, no manual installation needed.
    -   If you do not use `uv`, you must manually install dependencies with `pip install requests<3`.

**Function:**

-   Scans the current directory for images named `{id}_{md5}.{ext}` and fetches tags from Danbooru by MD5. If not found, falls back to Gelbooru.
-   Tags are written to a `.txt` file with the same name as the image, comma-separated.

**Usage:**

```bash
uv run fetch_tags.py
```

-   No extra parameters needed; just run the script.

**Filename pattern:**

-   Only processes files named `{id}_{md5}.{ext}` (supports jpg, jpeg, png, gif).
-   The generated tag file will have the same name as the image, with a `.txt` extension.

**Notes:**

-   1-second delay between each image query to avoid being rate-limited.
-   If neither site returns tags, an error will be shown in the logs.

---

## Notes

-   **Files will be overwritten:** All three tools overwrite original files. **Always back up important data first!**
-   **Dependency installation:**
    -   `resize_images.zsh` requires ImageMagick.
    -   `fetch_tags.py` requires `requests<3`, recommended to use uv for management.
-   **API rate limits:** `fetch_tags.py` may have rate limiting; do not run the script in parallel.

---

## 📜 License

<img src="https://github.com/user-attachments/assets/f4d883c0-80d1-4980-a9f4-eebf31a28b02" alt="gplv3" width="300" />

[GNU GENERAL PUBLIC LICENSE Version 3](LICENSE)

This program is free software: you can redistribute it and/or modify it under the terms of the GNU General Public License as published by the Free Software Foundation, either version 3 of the License, or (at your option) any later version.

This program is distributed in the hope that it will be useful, but WITHOUT ANY WARRANTY; without even the implied warranty of MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE. See the GNU General Public License for more details.

You should have received a copy of the GNU General Public License along with this program. If not, see <https://www.gnu.org/licenses/>.
