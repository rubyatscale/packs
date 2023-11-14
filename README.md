# packs

`packs` are a specification for an extensible packaging system to help modularize Ruby applications.

A `pack` (short for `package`) is a folder of Ruby code with a `package.yml` at the root that is intended to represent a well-modularized domain.

This gem provides a development CLI, `bin/packs`, to make using `packs` easier.

# Configuration
By default, this library will look for `packs` in the folder `packs/*/package.yml` (as well as nested packs at `packs/*/*/package.yml`). To change where `packs` are located, create a `packs.yml` file in the root of your project:
```yml
pack_paths:
  - "{packs,utilities,deprecated}/*" # packs with multiple roots!
  - "{packs,utilities,deprecated}/*/*" # nested packs!
  - gems/* # gems can be packs too!
```

# Ecosystem
The rest of the [rubyatscale](https://github.com/rubyatscale) ecosystem is intended to help make using packs and improving the boundaries between them more clear.

Here are some example integrations with `packs`:
- [`packs-specification`](https://github.com/rubyatscale/packs-specification) is a low-dependency gem that allows your production environment to query simple information about packs
- [`packs-rails`](https://github.com/rubyatscale/packs-rails) can be used to integrate `packs` into your `rails` application
- [`rubocop-packs`](https://github.com/rubyatscale/rubocop-packs) contains cops to improve boundaries around `packs` 
- [`packwerk`](https://github.com/Shopify/packwerk) and [`packwerk-extensions`](https://github.com/rubyatscale/packwerk-extensions) help you describe and constrain your package graph in terms of dependencies between packs and pack public API
- [`code_ownership`](https://github.com/rubyatscale/code_ownership) gives your application the capability to determine the owner of a pack
- [`pack_stats`](https://github.com/rubyatscale/pack_stats) makes it easy to send metrics about pack adoption and modularization to your favorite metrics provider, such as DataDog (which has built-in support).

# How is a pack different from a gem?
A ruby [`gem`](https://guides.rubygems.org/what-is-a-gem/) is the Ruby community solution for packaging and distributing Ruby code. A gem is a great place to start new projects, and a great end state for code that's been extracted from an existing codebase. `packs` are intended to help gradually modularize an application that has some conceptual boundaries, but is not yet ready to be factored into gems.

## Usage
1. Add the gem to your Gemfile and do a `bundle install`
```
gem 'packs-rails'
gem 'packs'
```

2. Initialize packwerk
```
bundle binstub packwerk
bin/packwerk init
```

3. Make sure to run `bundle binstub packs` to generate `bin/packs` within your application.

## CLI Documentation
## Describe available commands or one specific command
`bin/packs help [COMMAND]`

## Create pack with name packs/your_pack
`bin/packs create packs/your_pack`

## Add packs/to_pack to packs/from_pack/package.yml list of dependencies
`bin/packs add_dependency packs/from_pack packs/to_pack`

Use this to add a dependency between packs.

When you use bin/packs add_dependency packs/from_pack packs/to_pack, this command will
modify packs/from_pack/package.yml's list of dependencies and add packs/to_pack.

This command will also sort the list and make it unique.

## List the top violations of a specific type for packs/your_pack.
`bin/packs list_top_violations type [ packs/your_pack ]`

Possible types are: dependency, privacy, architecture.

Want to see who is depending on you? Not sure how your pack's code is being used in an unstated way? You can use this command to list the top dependency violations.

Want to create interfaces? Not sure how your pack's code is being used? You can use this command to list the top privacy violations.

Want to focus on the big picture first? You can use this command to list the top architecture violations.

If no pack name is passed in, this will list out violations across all packs.

## Make files or directories public API
`bin/packs make_public path/to/file.rb path/to/directory`

This moves a file or directory to public API (that is -- the `app/public` folder).

Make sure there are no spaces between the comma-separated list of paths of directories.

## Move files or directories from one pack to another
`bin/packs move packs/destination_pack path/to/file.rb path/to/directory`

This is used for moving files into a pack (the pack must already exist).
Note this works for moving files to packs from the monolith or from other packs

Make sure there are no spaces between the comma-separated list of paths of directories.

## Lint `package_todo.yml` files to check for formatting issues
`bin/packs lint_package_todo_yml_files`

## Lint `package.yml` files
`bin/packs lint_package_yml_files [ packs/my_pack packs/my_other_pack ]`

## Run bin/packwerk validate (detects cycles)
`bin/packs validate`

## Run bin/packwerk check
`bin/packs check [ packs/my_pack ]`

## Run bin/packwerk update-todo
`bin/packs update`

## Get info about size and violations for packs
`bin/packs get_info [ packs/my_pack packs/my_other_pack ]`

## Rename a pack
`bin/packs rename`

## Set packs/child_pack as a child of packs/parent_pack
`bin/packs move_to_parent packs/child_pack packs/parent_pack `


## Releasing
Releases happen automatically through github actions once a version update is committed to `main`.

## Discussions, Issues, Questions, and More
To keep things organized, here are some recommended homes:

### Issues:
https://github.com/rubyatscale/packs/issues

### Questions:
https://github.com/rubyatscale/packs/discussions/categories/q-a

### General discussions:
https://github.com/rubyatscale/packs/discussions/categories/general

### Ideas, new features, requests for change:
https://github.com/rubyatscale/packs/discussions/categories/ideas

### Showcasing your work:
https://github.com/rubyatscale/packs/discussions/categories/show-and-tell
