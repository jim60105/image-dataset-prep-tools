# Image Dataset Preparation Tools

This project provides image dataset preparation tools for AI training workflows, with Python and zsh scripts that process files in the current working directory.

## Project Architecture

All scripts are designed to run from any directory via PATH, processing files in the current working directory rather than the script location. Use `Path.cwd()` for Python and relative patterns for zsh.

## Python Guidelines

- Follow PEP 8 with 79-character line limit
- Use type hints with `typing` module imports
- All scripts are designed to run separately. No project setup. Use `uv run --script` for dependency management
- Configure logging with timestamps: `%(asctime)s - %(levelname)s - %(message)s`
- Handle HTTP requests with proper error handling and timeout=10
- Use pathlib.Path for file operations
- Comments and docstrings in English

### Shebang & Metadata for uv Scripts
To make a Python script executable with uv, add this as the first line (no leading whitespace before ! mark):

    #!/usr/bin/env -S uv run --script

Then run:

    chmod +x script.py

#### Declaring Python version and dependencies
Add a TOML metadata block after the shebang to specify Python version and dependencies:

    #!/usr/bin/env -S uv run --script
    # /// script
    # requires-python = ">=3.12"
    # dependencies = [
    #   "requests<3",
    # ]
    # ///

This allows direct execution via `./script.py` and works with uv's dependency management and inline metadata.

## Zsh Guidelines

- Use `#!/bin/zsh` shebang
- Set `setopt nullglob` for safe glob patterns
- Use `[[ ]]` for conditionals, `(( ))` for arithmetic
- Include file existence checks: `[[ ! -f "$file" ]] && continue`
- Echo progress messages for user feedback
- Handle user input with `read` command
- Comments in English

## License & Headers

All files include GPL-3.0-or-later license headers with Jim Chen copyright. See any existing files for head -n 20 for example.

    # Copyright (C) 2025 Jim Chen <Jim@ChenJ.im>, licensed under GPL-3.0-or-later
    #
    # This program is free software...(complete with Common GPLv3 header)

Use conventional commit format with "GitHub Copilot<bot@ChenJ.im>" as author when committing (committer unchanged).

## Dependency Management

- Python: Use uv script dependencies block. NEVER run venv or configurePythonEnvironment, installPythonPackage tool.
- Document external tool requirements in usage sections

## File Processing Patterns

Scripts process specific filename patterns:
- `fetch_tags.py`: `{id}_{md5}.{ext}` for images
- `resize_images.zsh`: `*.jpg *.png` files
- `process_txt_files.zsh`: `*.txt` files

Always validate file existence and patterns before processing.
After you make any modifications, update README.md for your changes.
Let's do this step by step.
