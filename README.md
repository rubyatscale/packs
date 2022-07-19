# UsePackwerk

UsePackwerk is a gem that helps in creating and maintaining packs. It exists to help perform some basic operations needed for pack setup and configuration. It provides a basic ruby file packager utility for [`packwerk`](https://github.com/Shopify/packwerk/). It assumes you are using [`stimpack`](https://github.com/rubyatscale/stimpack) to organize your packages.

## Usage
### General Help
`bin/use_packwerk --help`

### Pack Creation
`bin/use_packwerk create packs/your_pack_name_here`

### Moving files to packs
`bin/use_packwerk move packs/your_pack_name_here path/to/file.rb path/to/directory`
This is used for moving files into a pack (the pack must already exist).
Note this works for moving files to packs from the monolith or from other packs

Make sure there are no spaces between the comma-separated list of paths of directories.

### Moving a file to public API
`bin/use_packwerk make_public path/to/file.rb path/to/directory`
This moves a file or directory to public API (that is -- the `app/public` folder).

Make sure there are no spaces between the comma-separated list of paths of directories.

### Listing top privacy violations
`bin/use_packwerk list_top_privacy_violations packs/my_pack`
Want to create interfaces? Not sure how your pack's code is being used?

You can use this command to list the top privacy violations.

If no pack name is passed in, this will list out violations across all packs.

### Listing top dependency violations
`bin/use_packwerk list_top_dependency_violations packs/my_pack`
Want to see who is depending on you? Not sure how your pack's code is being used in an unstated way

You can use this command to list the top dependency violations.

If no pack name is passed in, this will list out violations across all packs.

### Adding a dependency
`bin/use_packwerk add_pack_dependency packs/my_pack packs/dependency_pack_name`

This can be used to quickly modify a `package.yml` file and add a dependency. It also cleans up the list of dependencies to sort the list and remove redundant entries.

## Discussions, Issues, Questions, and More
To keep things organized, here are some recommended homes:

### Issues:
https://github.com/Gusto/use_packwerk/issues

### Questions:
https://github.com/Gusto/use_packwerk/discussions/categories/q-a

### General discussions:
https://github.com/Gusto/use_packwerk/discussions/categories/general

### Ideas, new features, requests for change:
https://github.com/Gusto/use_packwerk/discussions/categories/ideas

### Showcasing your work:
https://github.com/Gusto/use_packwerk/discussions/categories/show-and-tell
