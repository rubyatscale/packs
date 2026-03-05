# AGENTS.md

This file provides guidance to AI coding agents when working with code in this repository.

## What this project is

`packs` is a Ruby gem that provides the specification and development CLI for the packs packaging system — a way to modularize Ruby applications. It provides `bin/packs` commands to create packs, add dependencies, and manage pack configuration.

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
- `lib/packs/` — core classes: `Pack` (represents a single package), `Configuration`, `Formatter`, and CLI command implementations
- `bin/packs` — CLI executable; uses the library to expose commands like `create`, `add_dependency`, `move`
- `spec/` — RSpec tests; `spec/fixtures/` contains sample Ruby application structures used in integration tests
