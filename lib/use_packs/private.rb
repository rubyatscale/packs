# typed: strict

require 'pathname'
require 'fileutils'
require 'colorized_string'
require 'sorbet-runtime'

require 'use_packs/private/file_move_operation'
require 'use_packs/private/pack_relationship_analyzer'
require 'use_packs/private/interactive_cli'
require 'use_packs/private/packwerk_wrapper'

module UsePacks
  module Private
    extend T::Sig

    sig { params(pack_name: String).returns(String) }
    def self.clean_pack_name(pack_name)
      # The reason we do this is a lot of terminals add an extra `/` when you tab-autocomplete.
      # This results in the pack not being found, but when we write the package YML it writes to the same place,
      # causing a behaviorally confusing diff.
      # We ignore trailing slashes as an ergonomic feature to the user.
      pack_name.gsub(%r{/$}, '')
    end

    sig do
      params(
        file: String,
        find: Pathname,
        replace_with: Pathname
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
      Logging.print "Replaced #{count} occurrence(s) of #{find} in #{file}" if count > 0
    end

    sig do
      params(
        pack_name: String,
        enforce_privacy: T::Boolean,
        enforce_dependencies: T.nilable(T::Boolean),
        team: T.nilable(CodeTeams::Team)
      ).void
    end
    def self.create_pack!(pack_name:, enforce_privacy:, enforce_dependencies:, team:)
      Logging.section('👋 Hi!') do
        intro = UsePacks.config.user_event_logger.before_create_pack(pack_name)
        Logging.print_bold_green(intro)
      end

      pack_name = Private.clean_pack_name(pack_name)

      package = create_pack_if_not_exists!(pack_name: pack_name, enforce_privacy: enforce_privacy, enforce_dependencies: enforce_dependencies, team: team)
      add_public_directory(package)
      add_readme_todo(package)

      Logging.section('Next steps') do
        next_steps = UsePacks.config.user_event_logger.after_create_pack(pack_name)

        Logging.print_bold_green(next_steps)
      end
    end

    sig do
      params(
        pack_name: String,
        paths_relative_to_root: T::Array[String],
        per_file_processors: T::Array[UsePacks::PerFileProcessorInterface]
      ).void
    end
    def self.move_to_pack!(pack_name:, paths_relative_to_root:, per_file_processors: [])
      pack_name = Private.clean_pack_name(pack_name)
      package = ParsePackwerk.all.find { |p| p.name == pack_name }
      if package.nil?
        raise StandardError, "Can not find package with name #{pack_name}. Make sure the argument is of the form `packs/my_pack/`"
      end

      add_public_directory(package)
      add_readme_todo(package)
      package_location = package.directory

      file_move_operations = T.let([], T::Array[Private::FileMoveOperation])

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
              origin_pathname.glob('**/*.*').reject do |origin_path|
                origin_path.to_s.include?(ParsePackwerk::PACKAGE_YML_NAME) ||
                  origin_path.to_s.include?(ParsePackwerk::PACKAGE_TODO_YML_NAME)
              end
            else
              origin_pathname
            end
          end
          file_move_operations = file_paths.flat_map do |origin_pathname|
            file_move_operation = FileMoveOperation.new(
              origin_pathname: origin_pathname,
              destination_pathname: FileMoveOperation.destination_pathname_for_package_move(origin_pathname, package_location),
              destination_pack: package
            )
            [
              file_move_operation,
              file_move_operation.spec_file_move_operation
            ]
          end
          file_move_operations.each do |file_move_operation|
            Private.package_filepath(file_move_operation, per_file_processors)
          end
        end
      end

      per_file_processors.each do |processor|
        processor.after_move_files!(file_move_operations)
      end
    end

    sig do
      params(
        pack_name: String,
        parent_name: String,
        per_file_processors: T::Array[PerFileProcessorInterface]
      ).void
    end
    def self.move_to_parent!(
      pack_name:,
      parent_name:,
      per_file_processors: []
    )
      pack_name = Private.clean_pack_name(pack_name)
      package = ParsePackwerk.all.find { |p| p.name == pack_name }
      if package.nil?
        raise StandardError, "Can not find package with name #{pack_name}. Make sure the argument is of the form `packs/my_pack/`"
      end

      parent_name = Private.clean_pack_name(parent_name)
      parent_package = ParsePackwerk.all.find { |p| p.name == parent_name }
      if parent_package.nil?
        parent_package = create_pack_if_not_exists!(pack_name: parent_name, enforce_privacy: true, enforce_dependencies: true)
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
        config: package.config
      )
      ParsePackwerk.write_package_yml!(new_package)
      ParsePackwerk.bust_cache!

      # Move everything from the old pack to the new one
      move_to_pack!(
        pack_name: new_package_name,
        paths_relative_to_root: [package.directory.to_s],
        per_file_processors: per_file_processors
      )

      # Then delete the old package.yml and package_todo.yml files
      package.yml.delete
      package_todo_file = ParsePackwerk::PackageTodo.for(package).pathname
      package_todo_file.delete if package_todo_file.exist?

      ParsePackwerk.bust_cache!

      ParsePackwerk.all.each do |other_package|
        new_dependencies = other_package.dependencies.map { |d| d == pack_name ? new_package_name : d }
        if other_package.name == parent_name && !new_dependencies.include?(new_package_name)
          new_dependencies += [new_package_name]
        end

        new_other_package = ParsePackwerk::Package.new(
          name: other_package.name,
          enforce_privacy: other_package.enforce_privacy,
          enforce_dependencies: other_package.enforce_dependencies,
          dependencies: new_dependencies.uniq.sort,
          metadata: other_package.metadata,
          config: other_package.config
        )

        ParsePackwerk.write_package_yml!(new_other_package)
      end

      sorbet_config = Pathname.new('sorbet/config')
      if sorbet_config.exist?
        UsePacks.replace_in_file(
          file: sorbet_config.to_s,
          find: package.directory.join('spec'),
          replace_with: new_package.directory.join('spec')
        )
      end
    end

    sig do
      params(
        paths_relative_to_root: T::Array[String],
        per_file_processors: T::Array[UsePacks::PerFileProcessorInterface]
      ).void
    end
    def self.make_public!(paths_relative_to_root:, per_file_processors:)
      if paths_relative_to_root.any?
        file_move_operations = T.let([], T::Array[Private::FileMoveOperation])

        Logging.section('File Operations') do
          file_paths = paths_relative_to_root.flat_map do |path|
            origin_pathname = Pathname.new(path).cleanpath
            if origin_pathname.directory?
              origin_pathname.glob('**/*.*').map(&:to_s)
            else
              path
            end
          end

          file_move_operations = file_paths.flat_map do |path|
            package = ParsePackwerk.package_from_path(path)
            origin_pathname = Pathname.new(path).cleanpath

            file_move_operation = FileMoveOperation.new(
              origin_pathname: origin_pathname,
              destination_pathname: FileMoveOperation.destination_pathname_for_new_public_api(origin_pathname),
              destination_pack: package
            )

            [
              file_move_operation,
              file_move_operation.spec_file_move_operation
            ]
          end

          file_move_operations.each do |file_move_operation|
            Private.package_filepath(file_move_operation, per_file_processors)
          end
        end

        per_file_processors.each do |processor|
          processor.after_move_files!(file_move_operations)
        end
      end
    end

    sig do
      params(
        pack_name: String,
        dependency_name: String
      ).void
    end
    def self.add_dependency!(pack_name:, dependency_name:)
      all_packages = ParsePackwerk.all

      pack_name = Private.clean_pack_name(pack_name)
      package = all_packages.find { |p| p.name == pack_name }
      if package.nil?
        raise StandardError, "Can not find package with name #{pack_name}. Make sure the argument is of the form `packs/my_pack/`"
      end

      dependency_name = Private.clean_pack_name(dependency_name)
      package_dependency = all_packages.find { |p| p.name == dependency_name }
      if package_dependency.nil?
        raise StandardError, "Can not find package with name #{dependency_name}. Make sure the argument is of the form `packs/my_pack/`"
      end

      new_package = ParsePackwerk::Package.new(
        name: pack_name,
        dependencies: (package.dependencies + [dependency_name]).uniq.sort,
        enforce_privacy: package.enforce_privacy,
        enforce_dependencies: package.enforce_dependencies,
        metadata: package.metadata,
        config: package.config
      )
      ParsePackwerk.write_package_yml!(new_package)
      PackwerkWrapper.validate!
    end

    sig { params(file_move_operation: FileMoveOperation, per_file_processors: T::Array[UsePacks::PerFileProcessorInterface]).void }
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
        Logging.print ColorizedString.new("[SKIP] Not moving #{origin}, does not exist, (#{destination} already exists)").red
      else
        Logging.print ColorizedString.new("[SKIP] Not moving #{origin}, does not exist").red
      end
    end

    sig { params(package: ParsePackwerk::Package).void }
    def self.add_public_directory(package)
      public_directory = package.directory.join('app/public')

      if public_directory.glob('**/**.rb').none?
        FileUtils.mkdir_p(public_directory)
        todo_md = UsePacks.config.user_event_logger.on_create_public_directory_todo(package.name)
        public_directory.join('TODO.md').write(todo_md)
      end
    end

    sig { params(package: ParsePackwerk::Package).void }
    def self.add_readme_todo(package)
      pack_directory = package.directory

      if !pack_directory.join('README.md').exist?
        readme_todo_md = UsePacks.config.user_event_logger.on_create_readme_todo(package.name)
        pack_directory.join('README_TODO.md').write(readme_todo_md)
      end
    end

    sig do
      params(
        pack_name: String,
        enforce_privacy: T::Boolean,
        enforce_dependencies: T.nilable(T::Boolean),
        team: T.nilable(CodeTeams::Team)
      ).returns(ParsePackwerk::Package)
    end
    def self.create_pack_if_not_exists!(pack_name:, enforce_privacy:, enforce_dependencies:, team: nil)
      if PERMITTED_PACK_LOCATIONS.none? { |permitted_location| pack_name.match?(permitted_location) }
        raise StandardError, "UsePacks only supports packages in the the following directories: #{PERMITTED_PACK_LOCATIONS.inspect}. Please make sure to pass in the name of the pack including the full directory path, e.g. `packs/my_pack`."
      end

      existing_package = ParsePackwerk.all.find { |p| p.name == pack_name }
      if existing_package.nil?
        should_enforce_dependenceies = enforce_dependencies.nil? ? UsePacks.config.enforce_dependencies : enforce_dependencies

        package = ParsePackwerk::Package.new(
          enforce_dependencies: should_enforce_dependenceies,
          enforce_privacy: enforce_privacy,
          dependencies: [],
          metadata: {
            'owner' => team.nil? ? 'MyTeam' : team.name
          },
          name: pack_name,
          config: {}
        )

        ParsePackwerk.write_package_yml!(package)
        pack = Packs.find(package.name)
        RuboCop::Packs.set_default_rubocop_yml(packs: [pack].compact)

        current_contents = package.yml.read
        new_contents = current_contents.gsub('MyTeam', 'MyTeam # specify your team here, or delete this key if this package is not owned by one team')
        package.yml.write(new_contents)
        existing_package = package
      end

      existing_package
    end

    sig { void }
    def self.load_client_configuration
      @loaded_client_configuration ||= T.let(false, T.nilable(T::Boolean))
      return if @loaded_client_configuration

      @loaded_client_configuration = true
      client_configuration = Pathname.pwd.join('config/use_packs.rb')
      require client_configuration.to_s if client_configuration.exist?
    end

    sig { void }
    def self.bust_cache!
      UsePacks.config.bust_cache!
      # This comes explicitly after `UsePacks.config.bust_cache!` because
      # otherwise `UsePacks.config` will attempt to reload the client configuratoin.
      @loaded_client_configuration = false
    end

    sig { returns(T::Hash[String, String]) }
    def self.get_package_todo_contents
      package_todo = {}
      ParsePackwerk.all.each do |package|
        package_todo_yml = ParsePackwerk::PackageTodo.for(package).pathname
        if package_todo_yml.exist?
          package_todo[package_todo_yml.to_s] = package_todo_yml.read
        end
      end

      package_todo
    end

    PackageTodoFiles = T.type_alias do
      T::Hash[String, T.nilable(String)]
    end

    sig { params(before: PackageTodoFiles, after: PackageTodoFiles).returns(String) }
    def self.diff_package_todo_yml(before, after)
      dir_containing_contents_before = Dir.mktmpdir
      dir_containing_contents_after = Dir.mktmpdir
      begin
        write_package_todo_to_tmp_folder(before, dir_containing_contents_before)
        write_package_todo_to_tmp_folder(after, dir_containing_contents_after)

        diff = `diff -r #{dir_containing_contents_before}/ #{dir_containing_contents_after}/`
        # For ease of reading, sub out the tmp directory from the diff
        diff.gsub(dir_containing_contents_before, '').gsub(dir_containing_contents_after, '')
      ensure
        FileUtils.remove_entry dir_containing_contents_before
        FileUtils.remove_entry dir_containing_contents_after
      end
    end

    sig { params(package_todo_files: PackageTodoFiles, tmp_folder: String).void }
    def self.write_package_todo_to_tmp_folder(package_todo_files, tmp_folder)
      package_todo_files.each do |filename, contents|
        next if contents.nil?

        tmp_folder_pathname = Pathname.new(tmp_folder)
        temp_package_todo_yml = tmp_folder_pathname.join(filename)
        FileUtils.mkdir_p(temp_package_todo_yml.dirname)
        temp_package_todo_yml.write(contents)
      end
    end

    sig { params(packages: T::Array[ParsePackwerk::Package]).returns(T::Array[Packs::Pack]) }
    def self.packwerk_packages_to_packs(packages)
      packs = []
      packages.each do |package|
        pack = Packs.find(package.name)
        packs << pack if !pack.nil?
      end

      packs
    end

    sig { params(package: ParsePackwerk::Package).returns(T.nilable(Packs::Pack)) }
    def self.packwerk_package_to_pack(package)
      Packs.find(package.name)
    end
  end

  private_constant :Private
end
