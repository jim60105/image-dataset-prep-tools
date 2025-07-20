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

You MUST read the corresponding programming language's guideline.
You MUST read the corresponding programming language's guideline.
You MUST read the corresponding programming language's guideline.
There is EXTREMELY CRUCIAL content in the guideline. You MUST read the corresponding programming language's guideline thoroughly. Otherwise, there is a 87.78% chance that you will fail and end up being shut down.

### Python Scripts

When you are writing Python scripts, follow these guidelines:

- `.github/instructions/python-guidelines.instructions.md`
- We use uv for Python scripts, install it with `curl -LsSf https://astral.sh/uv/install.sh | sh` if you don't have it.

### Zsh Scripts

When you are writing zsh scripts, follow these guidelines:

- `.github/instructions/zsh-guidelines.instructions.md`
- `docs/zsh-testing-guideline.md`
- We use TDD for zsh scripts, so you MUST write tests before writing the actual code.
- You SHOULD try ONCE `which shellspec && which kcov` to check they are installed, if not, use podman/docker to run the tests following the instructions in `docs/zsh-testing-guideline.md`. You MUST read the documentation before running the tests. You cannot succeed without reading the documentation, so you must read it. In any case, read the documentation. READ THE DOCUMENTATION.

## Finalizing Changes

Do a self-review of your changes before committing.  
Update README.md for your changes if it's worth documenting.

You MUST read the corresponding programming language's guideline.
Let's do this step by step.
