# Advanced Usage
## Pack Maintenance
### Setting Privacy
```ruby
UsePackwerk.create_pack!(
    # This determines whether your package.yml in your new package will enforce privacy. See packwerk documentation for more details on this attribute.
    # This is an optional parameter (default is true). See https://github.com/Gusto/use_packwerk/discussions/19
    enforce_privacy: false,
    # ... other parameters
)
```

### Per-file Processors
Your application may have specific needs when moving files. `UsePackwerk` gives a way to inject application-specific behavior into the file move process.

You can pass in an array of application specific behavior into the `per_file_processors` parameter of the main method.

See `rubocop_post_processor.rb` as an example of renaming files in `.rubocop_todo.yml` automatically, which is something you may want to do (as you do not want to fix all style errors when you're just moving a file).

# First-Time Configuration (per repo, not per developer)
If you install binstubs, it allows simpler commands: `bin/use_packwerk` rather than `bundle exec use_packwerk`.

Install binstubs using:
`bundle binstubs use_packwerk`
