---
applyTo: '**/*.py'
---
# Python Code Guidelines

## General Coding Standards

* All code comments must be written in **English**.
* Documentation and user interface text are authored in **English**.
* Function names follow the `snake_case` convention.
* Class names follow `PascalCase`.
* Constants use `UPPER_CASE`.
* Avoid Indent Hadouken, use fail first and early return.
* The use of @deprecated is prohibited. Whenever you want to use @deprecated, simply remove it and directly modify any place where it is used.
* Instead of concentrating on backward compatibility, greater importance is given to removing unnecessary designs. When a module is no longer utilized, remove it. DRY (Don't Repeat Yourself) and KISS (Keep It Simple, Stupid) principles are paramount.
* Any unimplemented code or tests must be marked with `//TODO` comment.
* Unless the requirements or user asks you to implement in phases, using TODO is prohibited. TODO means there is still unfinished work. You are required to complete your work.

## Project-Specific Guidelines

* Follow PEP 8 with 100-character line limit (project preference over 79-character default)
* Use type hints with `typing` module imports
* All scripts are designed to run separately. No project setup. Use `uv run --script` for dependency management
* Configure logging with timestamps: `%(asctime)s - %(levelname)s - %(message)s`
* Handle HTTP requests with proper error handling and timeout=10
* Use pathlib.Path for file operations
* Comments and docstrings in English

## Script Execution & Dependencies

### Script Headers & License

Use GPL-3.0-or-later license headers with Jim Chen copyright:

```zsh
#!/usr/bin/env -S uv run --script
# /// script
# requires-python = ">=3.12"
# dependencies = [
#   "requests<3",
# ]
# ///
"""
Copyright (C) 2025 Jim Chen <Jim@ChenJ.im>, licensed under GPL-3.0-or-later

This program is free software: you can redistribute it and/or modify
it under the terms of the GNU General Public License as published by
the Free Software Foundation, either version 3 of the License, or
 (at your option) any later version.

This program is distributed in the hope that it will be useful,
but WITHOUT ANY WARRANTY; without even the implied warranty of
MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
GNU General Public License for more details.

You should have received a copy of the GNU General Public License
along with this program.  If not, see <https://www.gnu.org/licenses/>.
"""
```

### Shebang & Metadata for uv Scripts

To make a Python script executable with uv, add this as the first line (no leading whitespace before ! mark):

```python
#!/usr/bin/env -S uv run --script
```

Then run:

```bash
chmod +x script.py
```

### Declaring Python version and dependencies

Add a TOML metadata block after the shebang to specify Python version and dependencies:

```python
#!/usr/bin/env -S uv run --script
# /// script
# requires-python = ">=3.12"
# dependencies = [
#   "requests<3",
# ]
# ///
```

This allows direct execution via `./script.py` and works with uv's dependency management and inline metadata.

## Testing

* Use `pytest` for running tests and make sure this project is testable.
* Place tests in the `tests` folder; any test files located in the project root directory are considered temporary and should be deleted.
* Follow the testing principles and practices outlined in [Test Guidelines](../../docs/python-testing-guidelines.md)` if there is one.

## Logging & Code Quality

* Always use Python's standard `logging` module for all log output.
* Always `black --line-length=100 --skip-string-normalization` and `flake8` the submitting files and fix any warnings before submitting any code. Do not lint the whole project, only the files you are submitting. Use the `.flake8` configuration file in the root directory for linting. Fix not only the errors but also styling warnings.
