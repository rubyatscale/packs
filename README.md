# UsePacks

UsePacks is a gem that helps in creating and maintaining packs. It exists to help perform some basic operations needed for pack setup and configuration. It provides a basic ruby file packager utility for [`packwerk`](https://github.com/Shopify/packwerk/). It assumes you are using [`stimpack`](https://github.com/rubyatscale/stimpack) to organize your packages.

## Usage
Make sure to run `bundle binstub use_packs` to generate `bin/packs` within your application.

## CLI Documentation
`bin/packs --help` or just `bin/packs` to enter interactive mode.

### Pack Creation
`bin/packs create packs/your_pack_name_here`

### Moving files to packs
`bin/packs move packs/your_pack_name_here path/to/file.rb path/to/directory`

### Moving a file to public API
`bin/packs make_public path/to/file.rb,path/to/directory`

### Listing top privacy violations
`bin/packs list_top_privacy_violations packs/my_pack`

### Listing top dependency violations
`bin/packs list_top_dependency_violations packs/my_pack`

### Adding a dependency
`bin/packs add_dependency packs/my_pack packs/dependency_pack_name`

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
