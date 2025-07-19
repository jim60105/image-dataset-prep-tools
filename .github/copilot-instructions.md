# Image Dataset Preparation Tools

This project provides image dataset preparation tools for AI training workflows, with Python and zsh scripts that process files in the current working directory.

## Project Architecture

All scripts are designed to run from any directory via PATH, processing files in the current working directory rather than the script location. Use `Path.cwd()` for Python and relative patterns for zsh.

## License & Headers

All files include GPL-3.0-or-later license headers with Jim Chen copyright. See any existing files for head -n 20 for example.

    # Copyright (C) 2025 Jim Chen <Jim@ChenJ.im>, licensed under GPL-3.0-or-later
    #
    # This program is free software...(complete with Common GPLv3 header)

Use conventional commit format with "GitHub Copilot<bot@ChenJ.im>" as author when committing (committer unchanged).

## Dependency Management

- Python: Use uv script dependencies block. NEVER run venv or configurePythonEnvironment, installPythonPackage tool.
- Document external tool requirements in usage sections

After you make any modifications, update README.md for your changes.
Let's do this step by step.
