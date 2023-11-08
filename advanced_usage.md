# Advanced Usage
## Pack Maintenance
### Setting Privacy
```ruby
Packs.create_pack!(
    # This determines whether your package.yml in your new package will enforce privacy. See packwerk documentation for more details on this attribute.
    # This is an optional parameter (default is true). See https://github.com/Gusto/packs/discussions/19
    enforce_privacy: false,
    # ... other parameters
)
```

### Per-file Processors
Your application may have specific needs when moving files. `Packs` gives a way to inject application-specific behavior into the file move process.

You can pass in an array of application specific behavior into the `per_file_processors` parameter of the main method.

See `rubocop_post_processor.rb` as an example of renaming files in `.rubocop_todo.yml` automatically, which is something you may want to do (as you do not want to fix all style errors when you're just moving a file).

When moving packs you can update all references to the pack's path by using the UpdateReferencesPostProcessor. This uses [ripgrep](https://github.com/BurntSushi/ripgrep/tree/master) (if it is installed).

# First-Time Configuration (per repo, not per developer)
If you install binstubs, it allows simpler commands: `bin/packs` rather than `bundle exec packs`.

Install binstubs using:
`bundle binstubs packs`
