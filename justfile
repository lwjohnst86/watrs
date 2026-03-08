@_default:
  just --list

# Build the full package, including any checks and documentation.
run-all: format check test build

# Build the book and serve it.
serve-book: 
  # Install via `cargo install mdbook`
  mdbook serve --open

# Run all checks.
check: check-spelling check-urls check-fmt check-cargo check-clippy

# Run linters and checkers.
check-spelling:
  # Install via `cargo install typos`
  typos

# Check that URLs work
check-urls:
    lychee . \
      --verbose \
      --extensions md

# Checks with clippy.
check-clippy:
  cargo clippy -- \
    -W clippy::pedantic \
    -W clippy::nursery \
    -W clippy::unwrap_used

# Checks with cargo.
check-cargo:
  cargo check
  
# Checks with rustfmt.
check-fmt:
  cargo fmt --check

# Run formatters
format: format-rs format-md

# Format the code and fix issues.
format-rs:
  cargo fix
  cargo clippy --fix
  cargo fmt

# Format Markdown files
format-md:
  uvx rumdl fmt .

# Run tests and check the documentation.
test: test-src test-docs

# Run all build recipes.
build: build-docs build-package

# Build the documentation.
build-docs:
  mdbook build
  cargo doc

# Build the package.
build-package:
  cargo build

# Run the tests in the `src/` or `tests/` directories.
test-src:
  cargo test
  
# Run tests on or in the documentation.
test-docs:
  mdbook test

# Run the CLI commands, just for the help.
test-cli-help:
  cargo run -- --help
  cargo run -- start --help
  cargo run -- stop --help
  cargo run -- edit --help
  cargo run -- stats --help
  cargo run -- today --help

# Run the CLI commands to see if they work.
test-cli:
  cargo run -- start test_project --tags tag1,tag2
  cargo run -- stop
  cargo run -- edit
  cargo run -- stats projects
  cargo run -- stats projects --unit week --number-of-units 2 --include-tags
  cargo run -- stats tags --unit month --number-of-units 1
  cargo run -- today
