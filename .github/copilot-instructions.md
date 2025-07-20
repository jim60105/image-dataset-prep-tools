# Image Dataset Preparation Tools

This project provides image dataset preparation tools for AI training workflows, with Python and zsh scripts that process files in the current working directory.

## Project Architecture

All scripts are designed to run from any directory via PATH, processing files in the current working directory rather than the script location. Use `Path.cwd()` for Python and relative patterns for zsh.

## License & Headers

All files include GPL-3.0-or-later license headers with Jim Chen copyright. See any existing files under src/ for head -n 20 for example.

    # Copyright (C) 2025 Jim Chen <Jim@ChenJ.im>, licensed under GPL-3.0-or-later
    #
    # This program is free software...(complete with Common GPLv3 header)

## Dependency Management

- Python: Use uv script dependencies block. NEVER run venv or configurePythonEnvironment, installPythonPackage tool.
- Document external tool requirements in usage sections

## Guidelines

Make sure to read the guidelines below when contributing to this project.

### Python Scripts

When you are writing Python scripts, follow these guidelines:

- `.github/instructions/python-guidelines.instructions.md`

### Zsh Scripts

When you are writing zsh scripts, follow these guidelines:

- `.github/instructions/zsh-guidelines.instructions.md`
- We use TDD for zsh scripts, so make sure to write tests before writing the actual code.
- `docs/zsh-testing-guideline.md`

## Finalizing Changes

Do a self-review of your changes before committing.  
Update README.md for your changes if it's worth documenting.

Let's do this step by step.
