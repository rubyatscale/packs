# typed: strict

require 'pathname'
require 'fileutils'
require 'colorized_string'
require 'sorbet-runtime'

require 'use_packwerk/private/file_move_operation'
require 'use_packwerk/private/pack_relationship_analyzer'

module UsePackwerk
  module Private
    extend T::Sig

    sig { params(pack_name: String).returns(String) }
    def self.clean_pack_name(pack_name)
      # The reason we do this is a lot of terminals add an extra `/` when you tab-autocomplete.
      # This results in the pack not being found, but when we write the package YML it writes to the same place,
      # causing a behaviorally confusing diff.
      # We ignore trailing slashes as an ergonomic feature to the user.
      pack_name.gsub(/\/$/, '')
    end

    sig do
      params(
        file: String,
        find: Pathname,
        replace_with: Pathname,
      ).void
    end
    def self.replace_in_file(file:, find:, replace_with:)
      file = Pathname.new(file)
      return if !file.exist?
      count = 0
      file.write(file.read.gsub(find.to_s) do
        count += 1
        replace_with.to_s
      end)
      Logging.print "Replaced #{count} occurrence(s) of #{find} in #{file.to_s}" if count > 0
    end

    sig do
      params(
        pack_name: String,
        enforce_privacy: T::Boolean,
        enforce_dependencies: T.nilable(T::Boolean)
      ).void
    end
    def self.create_pack!(pack_name:, enforce_privacy:, enforce_dependencies:)
      Logging.section('👋 Hi!') do
        intro = <<~INTRO
          You are creating a pack, which is great. Check out #{UsePackwerk.config.documentation_link} for more info!

          Please bring any questions or issues you have in your development process to #ruby-modularity or #product-infrastructure.
          We'd be happy to try to help through pairing, accepting feedback, changing our process, changing our tools, and more.
        INTRO
        Logging.print_bold_green(intro)
      end

      pack_name = Private.clean_pack_name(pack_name)

      package = create_pack_if_not_exists!(pack_name: pack_name, enforce_privacy: enforce_privacy, enforce_dependencies: enforce_dependencies)
      add_public_directory(package)
      add_readme_todo(package)

      Logging.section('Next steps') do
        next_steps = <<~NEXT_STEPS
          Your next steps might be:

          1) Move files into your pack with `bin/use_packwerk move #{pack_name} path/to/file.rb`

          2) Run `bin/packwerk update-deprecations` to update the violations. Make sure to run `spring stop` if you've added new load paths (new top-level directories) in your pack.

          3) Update TODO lists for rubocop implemented protections. See #{UsePackwerk.config.documentation_link} for more info

          4) Expose public API in #{pack_name}/app/public. Try `bin/use_packwerk make_public #{pack_name}/path/to/file.rb`

          5) Update your readme at #{pack_name}/README.md
        NEXT_STEPS

        Logging.print_bold_green(next_steps)
      end
    end

    sig do
      params(
        pack_name: String,
        paths_relative_to_root: T::Array[String],
        per_file_processors: T::Array[UsePackwerk::PerFileProcessorInterface]
      ).void
    end
    def self.move_to_pack!(pack_name:, paths_relative_to_root:, per_file_processors: [])
      pack_name = Private.clean_pack_name(pack_name)
      package = ParsePackwerk.all.find { |package| package.name == pack_name }
      if package.nil?
        raise StandardError.new("Can not find package with name #{pack_name}. Make sure the argument is of the form `packs/my_pack/`")
      end

      Logging.section('👋 Hi!') do
        intro = <<~INTRO
          You are moving a file to a pack, which is great. Check out #{UsePackwerk.config.documentation_link} for more info!

          Please bring any questions or issues you have in your development process to #ruby-modularity or #product-infrastructure.
          We'd be happy to try to help through pairing, accepting feedback, changing our process, changing our tools, and more.
        INTRO
        Logging.print_bold_green(intro)
      end

      add_public_directory(package)
      add_readme_todo(package)
      package_location = package.directory

      if paths_relative_to_root.any?
        Logging.section('File Operations') do
          file_paths = paths_relative_to_root.flat_map do |path|
            origin_pathname = Pathname.new(path).cleanpath
            # Note -- we used to `mv` over whole directories, rather than splatting out their contents and merging individual files.
            # The main advantage to moving whole directories is that it's a bit faster and a bit less verbose
            # However, this ended up being tricky and caused complexity to flow down later parts of the implementation.
            # Notably:
            # 1) The `mv` operation doesn't merge directories, so if the destination already has the same directory, then the mv operation
            # will overwrite
            # 2) We could get around this possibly with `cp_r` (https://ruby-doc.org/stdlib-1.9.3/libdoc/fileutils/rdoc/FileUtils.html#method-c-cp_r),
            # but we'd also have to delete the origin destination. On top of this, we still need to splat things out later on so that we can do
            # per file processor operations, and that has some complexity of its own. The simplest thing here would be to simply glob everything out.
            #
            # For now, we sacrifice some small level of speed and conciseness in favor of simpler implementation.
            # Later, if we choose to go back to moving whole directories at a time, it should be a refactor and all tests should still pass
            #
            if origin_pathname.directory?
              origin_pathname.glob('**/*.*')
            else
              origin_pathname
            end
          end
          file_move_operations = file_paths.map do |origin_pathname|
            FileMoveOperation.new(
              origin_pathname: origin_pathname,
              destination_pathname: FileMoveOperation.destination_pathname_for_package_move(origin_pathname, package_location),
              destination_pack: package,
            )
          end
          file_move_operations.each do |file_move_operation|
            Private.package_filepath(file_move_operation, per_file_processors)
            Private.package_filepath_spec(file_move_operation, per_file_processors)
          end
        end
      end

      per_file_processors.each do |per_file_processor|
        per_file_processor.print_final_message!
      end

      Logging.section('Next steps') do
        next_steps = <<~NEXT_STEPS
          Your next steps might be:

          1) Run `bin/packwerk update-deprecations` to update the violations. Make sure to run `spring stop` if you've added new load paths (new top-level directories) in your pack.

          2) Update TODO lists for rubocop implemented protections. See #{UsePackwerk.config.documentation_link} for more info

          3) Touch base with each team who owns files involved in this move

          4) Expose public API in #{pack_name}/app/public. Try `bin/use_packwerk make_public #{pack_name}/path/to/file.rb`

          5) Update your readme at #{pack_name}/README.md
        NEXT_STEPS

        Logging.print_bold_green(next_steps)
      end
    end

  sig do
    params(
      pack_name: String,
      parent_name: String,
      per_file_processors: T::Array[PerFileProcessorInterface],
    ).void
  end
  def self.move_to_parent!(
    pack_name:,
    parent_name:,
    per_file_processors: []
  )
    Logging.section('👋 Hi!') do
      intro = <<~INTRO
        You are moving one pack to be a child of a different pack.. Check out #{UsePackwerk.config.documentation_link} for more info!

        Please bring any questions or issues you have in your development process to #ruby-modularity or #product-infrastructure.
        We'd be happy to try to help through pairing, accepting feedback, changing our process, changing our tools, and more.
      INTRO
      Logging.print_bold_green(intro)
    end

    pack_name = Private.clean_pack_name(pack_name)
    package = ParsePackwerk.all.find { |package| package.name == pack_name }
    if package.nil?
      raise StandardError.new("Can not find package with name #{pack_name}. Make sure the argument is of the form `packs/my_pack/`")
    end

    parent_name = Private.clean_pack_name(parent_name)
    parent_package = ParsePackwerk.all.find { |package| package.name == parent_name }
    if parent_package.nil?
      raise StandardError.new("Can not find package with name #{parent_name}. Make sure the argument is of the form `packs/my_pack/`")
    end

    # First we create a new pack that has the exact same properties of the old one!
    package_last_name = package.directory.basename
    new_package_name = parent_package.directory.join(package_last_name).to_s
 
    new_package = ParsePackwerk::Package.new(
      name: new_package_name,
      enforce_privacy: package.enforce_dependencies,
      enforce_dependencies: package.enforce_dependencies,
      dependencies: package.dependencies,
      metadata: package.metadata,
    )
    ParsePackwerk.write_package_yml!(new_package)
    ParsePackwerk.bust_cache!

    # Move everything from the old pack to the new one
    self.move_to_pack!(
      pack_name: new_package_name,
      paths_relative_to_root: [package.directory.to_s],
      per_file_processors: per_file_processors,
    )

    # Add a dependency from parent to child
    self.add_dependency!(pack_name: parent_name, dependency_name: new_package_name)

    # Delete the old package.yml
    package.yml.delete

    # Delete the old deprecated_references file
    ParsePackwerk::DeprecatedReferences.for(package).pathname.delete

    Logging.section('Next steps') do
      next_steps = <<~NEXT_STEPS
        Your next steps might be:

        1) Delete the old pack when things look good: `rm -rf #{package.directory}`

        2) Run `bin/packwerk update-deprecations` to update the violations. Make sure to run `spring stop` first.

        3) Update your readme at #{new_package_name}/README.md
      NEXT_STEPS

      Logging.print_bold_green(next_steps)
    end
  end

    sig do
      params(
        paths_relative_to_root: T::Array[String],
        per_file_processors: T::Array[UsePackwerk::PerFileProcessorInterface]
      ).void
    end
    def self.make_public!(paths_relative_to_root:, per_file_processors:)
      Logging.section('Making files public') do
        intro = <<~INTRO
          You are moving some files into public API. See #{UsePackwerk.config.documentation_link} for other utilities!
        INTRO
        Logging.print_bold_green(intro)
      end

      if paths_relative_to_root.any?
        Logging.section('File Operations') do
          file_paths = paths_relative_to_root.flat_map do |path|
            origin_pathname = Pathname.new(path).cleanpath
            if origin_pathname.directory?
              origin_pathname.glob('**/*.*').map(&:to_s)
            else
              path
            end
          end


          file_move_operations = file_paths.map do |path|
            package = T.must(ParsePackwerk.package_from_path(path))
            origin_pathname = Pathname.new(path).cleanpath

            FileMoveOperation.new(
              origin_pathname: origin_pathname,
              destination_pathname: FileMoveOperation.destination_pathname_for_new_public_api(origin_pathname),
              destination_pack: package,
            )
          end

          file_move_operations.each do |file_move_operation|
            Private.package_filepath(file_move_operation, per_file_processors)
            Private.package_filepath_spec(file_move_operation, per_file_processors)
          end
        end
      end
      
      Logging.section('Next steps') do
        next_steps = <<~NEXT_STEPS
          Your next steps might be:

          1) Run `bin/packwerk update-deprecations` to update the violations. Make sure to run `spring stop` if you've added new load paths (new top-level directories) in your pack.

          2) Update TODO lists for rubocop implemented protections. See #{UsePackwerk.config.documentation_link} for more info

          3) Work to migrate clients of private API to your new public API

          4) Update your README at packs/your_package_name/README.md
        NEXT_STEPS

        Logging.print_bold_green(next_steps)
      end
    end

    sig do
      params(
        pack_name: String,
        dependency_name: String
      ).void
    end
    def self.add_dependency!(pack_name:, dependency_name:)
      Logging.section('Adding a dependency') do
        intro = <<~INTRO
          You are adding a dependency. See #{UsePackwerk.config.documentation_link} for other utilities!
        INTRO
        Logging.print_bold_green(intro)
      end

      all_packages = ParsePackwerk.all

      pack_name = Private.clean_pack_name(pack_name)
      package = all_packages.find { |package| package.name == pack_name }
      if package.nil?
        raise StandardError.new("Can not find package with name #{pack_name}. Make sure the argument is of the form `packs/my_pack/`")
      end

      dependency_name = Private.clean_pack_name(dependency_name)
      package_dependency = all_packages.find { |package| package.name == dependency_name }
      if package_dependency.nil?
        raise StandardError.new("Can not find package with name #{dependency_name}. Make sure the argument is of the form `packs/my_pack/`")
      end

      new_package = ParsePackwerk::Package.new(
        name: pack_name,
        dependencies: (package.dependencies + [dependency_name]).uniq.sort,
        enforce_privacy: package.enforce_privacy,
        enforce_dependencies: package.enforce_dependencies,
        metadata: package.metadata,
      )
      ParsePackwerk.write_package_yml!(new_package)
      
      Logging.section('Next steps') do
        next_steps = <<~NEXT_STEPS
          Your next steps might be:

          1) Run `bin/packwerk validate` to ensure you haven't introduced a cyclic dependency

          2) Run `bin/packwerk update-deprecations` to update the violations.
        NEXT_STEPS

        Logging.print_bold_green(next_steps)
      end
    end

    sig { params(file_move_operation: FileMoveOperation, per_file_processors: T::Array[UsePackwerk::PerFileProcessorInterface]).void }
    def self.package_filepath(file_move_operation, per_file_processors)
      per_file_processors.each do |per_file_processor|
        if file_move_operation.origin_pathname.exist?
          per_file_processor.before_move_file!(file_move_operation)
        end
      end

      origin = file_move_operation.origin_pathname
      destination = file_move_operation.destination_pathname
      idempotent_mv(origin, destination)
    end

    sig { params(file_move_operation: FileMoveOperation, per_file_processors: T::Array[UsePackwerk::PerFileProcessorInterface]).void }
    def self.package_filepath_spec(file_move_operation, per_file_processors)
      package_filepath(file_move_operation.spec_file_move_operation, per_file_processors)
    end

    sig { params(origin: Pathname, destination: Pathname).void }
    def self.idempotent_mv(origin, destination)
      if origin.exist? && destination.exist?
        Logging.print ColorizedString.new("[SKIP] Not moving #{origin}, #{destination} already exists").red
      elsif origin.exist? && !destination.exist?
        destination.dirname.mkpath

        Logging.print "Moving file #{origin} to #{destination}"
        # use git mv so that git knows that it was a move
        FileUtils.mv(origin, destination)
      elsif !origin.exist? && destination.exist?
        Logging.print ColorizedString.new("[SKIP] Not moving #{origin.to_s}, does not exist, (#{destination.to_s} already exists)").red
      else
        Logging.print ColorizedString.new("[SKIP] Not moving #{origin.to_s}, does not exist").red
      end
    end

    sig { params(package: ParsePackwerk::Package).void  }
    def self.add_public_directory(package)
      public_directory = package.directory.join('app/public')

      if public_directory.glob('**/**.rb').none?
        FileUtils.mkdir_p(public_directory)
        todo_md = <<~TODO
          This directory holds your public API!

          Any classes, constants, or modules that you want other packs to use and you intend to support should go in here.
          Anything that is considered private should go in other folders.

          If another pack uses classes, constants, or modules that are not in your public folder, it will be considered a "privacy violation" by packwerk.
          You can prevent other packs from using private API by using package_protections.

          Want to find how your private API is being used today?
          Try running: `bin/use_packwerk list_top_privacy_violations #{package.name}`

          Want to move something into this folder?
          Try running: `bin/use_packwerk make_public #{package.name}/path/to/file.rb`

          One more thing -- feel free to delete this file and replace it with a README.md describing your package in the main package directory.

          See #{UsePackwerk.config.documentation_link} for more info!
        TODO
        public_directory.join('TODO.md').write(todo_md)
      end
    end

    sig { params(package: ParsePackwerk::Package).void  }
    def self.add_readme_todo(package)
      pack_directory = package.directory

      if !pack_directory.join('README.md').exist?
        readme_todo_md = <<~TODO
          Welcome to `#{package.name}`!

          If you're the author, please consider replacing this file with a README.md, which may contain:
          - What your pack is and does
          - How you expect people to use your pack
          - Example usage of your pack's public API (which lives in `#{package.name}/app/public`)
          - Limitations, risks, and important considerations of usage
          - How to get in touch with eng and other stakeholders for questions or issues pertaining to this pack (note: it is recommended to add ownership in `#{package.name}/package.yml` under the `owner` metadata key)
          - What SLAs/SLOs (service level agreements/objectives), if any, your package provides
          - When in doubt, keep it simple
          - Anything else you may want to include!

          README.md files are under version control and should change as your public API changes. 

          See #{UsePackwerk.config.documentation_link} for more info!
        TODO
        pack_directory.join('README_TODO.md').write(readme_todo_md)
      end
    end

    sig do
      params(
        pack_name: String,
        enforce_privacy: T::Boolean,
        enforce_dependencies: T.nilable(T::Boolean)
      ).returns(ParsePackwerk::Package)
    end
    def self.create_pack_if_not_exists!(pack_name:, enforce_privacy:, enforce_dependencies:)
      if PERMITTED_PACK_LOCATIONS.none? { |permitted_location| pack_name.start_with?(permitted_location) }
        raise StandardError.new("UsePackwerk only supports packages in the the following directories: #{PERMITTED_PACK_LOCATIONS.inspect}. Please make sure to pass in the name of the pack including the full directory path, e.g. `packs/my_pack`.")
      end

      existing_package = ParsePackwerk.all.find { |package| package.name == pack_name }

      package_location = Pathname.new(pack_name)

      if existing_package.nil?
        should_enforce_dependenceies = enforce_dependencies.nil? ? UsePackwerk.config.enforce_dependencies : enforce_dependencies

        package = ParsePackwerk::Package.new(
          enforce_dependencies: should_enforce_dependenceies,
          enforce_privacy: enforce_privacy,
          dependencies: [],
          metadata: {
            'owner' => 'MyTeam'
          },
          name: pack_name,
        )

        ParsePackwerk.write_package_yml!(package)
        PackageProtections.set_defaults!([package], verbose: false)
        package = rewrite_package_with_original_packwerk_values(package)

        current_contents = package.yml.read
        new_contents = current_contents.gsub("MyTeam", "MyTeam # specify your team here, or delete this key if this package is not owned by one team")
        package.yml.write(new_contents)
        existing_package = package
      end

      existing_package
    end

    sig { params(original_package: ParsePackwerk::Package).returns(ParsePackwerk::Package) }
    def self.rewrite_package_with_original_packwerk_values(original_package)
      ParsePackwerk.bust_cache!
      package_with_protection_defaults = T.must(ParsePackwerk.all.find { |package| package.name == original_package.name })
      # PackageProtections also sets `enforce_privacy` and `enforce_dependency` to be true, so we set these back down to their original values
      package = ParsePackwerk::Package.new(
        enforce_dependencies: original_package.enforce_dependencies,
        enforce_privacy: original_package.enforce_privacy,
        dependencies: original_package.dependencies,
        metadata: package_with_protection_defaults.metadata,
        name: original_package.name,
      )

      ParsePackwerk.write_package_yml!(package)
      package
    end
  end

  private_constant :Private
end
