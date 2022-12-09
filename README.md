# UsePacks

UsePacks is a gem that helps in creating and maintaining packs. It exists to help perform some basic operations needed for pack setup and configuration. It provides a basic ruby file packager utility for [`packwerk`](https://github.com/Shopify/packwerk/). It assumes you are using [`stimpack`](https://github.com/rubyatscale/stimpack) to organize your packages.

## Usage
### General Help
`bin/packs --help` or just `bin/packs` to enter interactive mode.

### Pack Creation
`bin/packs create packs/your_pack_name_here`

### Moving files to packs
`bin/packs move packs/your_pack_name_here path/to/file.rb path/to/directory`
This is used for moving files into a pack (the pack must already exist).
Note this works for moving files to packs from the monolith or from other packs

Make sure there are no spaces between the comma-separated list of paths of directories.

### Moving a file to public API
`bin/packs make_public path/to/file.rb,path/to/directory`
This moves a file or directory to public API (that is -- the `app/public` folder).

Make sure there are no spaces between the comma-separated list of paths of directories.

### Listing top privacy violations
`bin/packs list_top_privacy_violations packs/my_pack`
Want to create interfaces? Not sure how your pack's code is being used?

You can use this command to list the top privacy violations.

If no pack name is passed in, this will list out violations across all packs.

### Listing top dependency violations
`bin/packs list_top_dependency_violations packs/my_pack`
Want to see who is depending on you? Not sure how your pack's code is being used in an unstated way

You can use this command to list the top dependency violations.

If no pack name is passed in, this will list out violations across all packs.

### Adding a dependency
`bin/packs add_dependency packs/my_pack packs/dependency_pack_name`

This can be used to quickly modify a `package.yml` file and add a dependency. It also cleans up the list of dependencies to sort the list and remove redundant entries.

### Setting up Spring

[Spring](https://github.com/rails/spring) is a preloader for Rails. Although `use_packs` itself does not use `Rails`, this can help speed up running commands like `bin/packs` by caching the bundle.
Firstly, spring needs to know about the `bin/packs` command when spring is loading. To do that, add `require 'use_packs/spring_command'` to `config/spring.rb` in your application.
Secondly, to enable Spring, first run `bin/spring binstub packs` which will "springify" the generated binstub.

### Releasing
Releases happen automatically through github actions once a version update is committed to `main`.

## Discussions, Issues, Questions, and More
To keep things organized, here are some recommended homes:

### Issues:
https://github.com/Gusto/use_packs/issues

### Questions:
https://github.com/Gusto/use_packs/discussions/categories/q-a

### General discussions:
https://github.com/Gusto/use_packs/discussions/categories/general

### Ideas, new features, requests for change:
https://github.com/Gusto/use_packs/discussions/categories/ideas

### Showcasing your work:
https://github.com/Gusto/use_packs/discussions/categories/show-and-tell
