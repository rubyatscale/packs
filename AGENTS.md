This file provides guidance to AI coding agents when working with code in this repository.

## What this project is

`packs` is a Ruby gem that provides the development CLI for the packs packaging system — a way to modularize Ruby applications. It provides `bin/packs` commands to create packs, move files between packs, add dependencies, and manage pack configuration.

## Commands

```bash
bundle install

# Run all tests (RSpec)
bundle exec rspec

# Run a single spec file
bundle exec rspec spec/path/to/spec.rb

# Lint
bundle exec rubocop
bundle exec rubocop -a  # auto-correct

# Type checking (Sorbet)
bundle exec srb tc
```

## Architecture

- `lib/packs.rb` — public API entry point
- `lib/packs/` — core library: `Configuration`, `CLI` (Thor-based command definitions), post-processors (`RubocopPostProcessor`, `CodeOwnershipPostProcessor`, `UpdateReferencesPostProcessor`), and the `UserEventLogger` interface
- `lib/packs/private/` — internal implementation; `interactive_cli/` contains the interactive TUI mode
- `bin/packs` — CLI executable; runs the interactive mode when called with no arguments, otherwise dispatches to `Packs::CLI` commands like `create`, `add_dependency`, `move`, `validate`, `check`
- `spec/` — RSpec tests; tests use temporary directories created via `packs/rspec/support` rather than static fixtures
