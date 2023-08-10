# Packs

Packs is a gem that helps in creating and maintaining packs. It exists to help perform some basic operations needed for pack setup and configuration. It provides a basic ruby file packager utility for [`packwerk`](https://github.com/Shopify/packwerk/). It assumes you are using [`packs-rails`](https://github.com/rubyatscale/packs-rails) to organize your packages.

## Usage
Make sure to run `bundle binstub use_packs` to generate `bin/packs` within your application.

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

## List the top dependency violations of packs/your_pack
`bin/packs list_top_dependency_violations packs/your_pack`

Want to see who is depending on you? Not sure how your pack's code is being used in an unstated way

You can use this command to list the top dependency violations.

If no pack name is passed in, this will list out violations across all packs.

## List the top privacy violations of packs/your_pack
`bin/packs list_top_privacy_violations packs/your_pack`

Want to create interfaces? Not sure how your pack's code is being used?

You can use this command to list the top privacy violations.

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

## Visualize packs
`bin/packs visualize [ packs/my_pack packs/my_other_pack ]`

## Rename a pack
`bin/packs rename`

## Set packs/child_pack as a child of packs/parent_pack
`bin/packs move_to_parent packs/child_pack packs/parent_pack `


## Releasing
Releases happen automatically through github actions once a version update is committed to `main`.

## Discussions, Issues, Questions, and More
To keep things organized, here are some recommended homes:

### Issues:
https://github.com/rubyatscale/use_packs/issues

### Questions:
https://github.com/rubyatscale/use_packs/discussions/categories/q-a

### General discussions:
https://github.com/rubyatscale/use_packs/discussions/categories/general

### Ideas, new features, requests for change:
https://github.com/rubyatscale/use_packs/discussions/categories/ideas

### Showcasing your work:
https://github.com/rubyatscale/use_packs/discussions/categories/show-and-tell
