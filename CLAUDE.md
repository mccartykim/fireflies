# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## Project Overview

This is a Gleam project named "fireflies". Gleam is a type-safe functional programming language that compiles to Erlang or JavaScript.

## Development Commands

### Essential Commands
- `gleam run` - Run the main function
- `gleam test` - Run all tests
- `gleam build` - Build the project
- `gleam check` - Type check without building
- `gleam format` - Format all source code

### Testing
- `gleam test` - Run tests on Erlang (default)
- `gleam test --target javascript` - Run tests on JavaScript
- Test files must be in `test/` directory and test functions must end with `_test`

### Code Quality
- `gleam format --check` - Check if code is formatted (used in CI)
- `gleam build --warnings-as-errors` - Build with warnings as errors

### Dependencies
- `gleam deps download` - Download dependencies (run after cloning)
- `gleam add <package>` - Add a dependency
- `gleam remove <package>` - Remove a dependency
- `gleam update` - Update dependencies

## Project Structure

```
fireflies/
├── src/              # Source code
│   └── fireflies.gleam    # Main module with main() function
├── test/             # Tests
│   └── fireflies_test.gleam  # Test suite
├── gleam.toml        # Project configuration
└── build/            # Build artifacts (gitignored)
```

## Architecture Notes

- Entry point: `src/fireflies.gleam` contains the `main()` function
- Testing: Uses gleeunit framework, test functions must end with `_test`
- Dependencies: gleam_stdlib (standard library) and gleeunit (dev dependency)
- The project can compile to both Erlang BEAM and JavaScript targets

## CI/CD Workflow

The GitHub Actions workflow runs on all pushes and PRs:
1. Downloads dependencies
2. Runs tests
3. Checks code formatting

Ensure your code passes these checks before pushing:
```bash
gleam deps download
gleam test
gleam format --check src test
```