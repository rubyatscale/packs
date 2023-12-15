# typed: strict

require 'pathname'
require 'fileutils'
require 'tmpdir'
require 'rainbow'
require 'sorbet-runtime'

require 'packs/private/file_move_operation'
require 'packs/private/pack_relationship_analyzer'
require 'packs/private/interactive_cli'

require 'date'

module Packs
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
        enforce_dependencies: T.nilable(T::Boolean),
        enforce_privacy: T::Boolean,
        enforce_architecture: T::Boolean,
        team: T.nilable(CodeTeams::Team)
      ).void
    end
    def self.create_pack!(pack_name:, enforce_dependencies:, enforce_privacy:, enforce_architecture:, team:)
      Logging.section('👋 Hi!') do
        intro = Packs.config.user_event_logger.before_create_pack(pack_name)
        Logging.print_bold_green(intro)
      end

      pack_name = Private.clean_pack_name(pack_name)

      package = create_pack_if_not_exists!(
        pack_name: pack_name,
        enforce_dependencies: enforce_dependencies,
        enforce_privacy: enforce_privacy,
        enforce_architecture: enforce_architecture,
        team: team
      )
      add_public_directory(package) if package.enforce_privacy
      add_readme_todo(package)

      Logging.section('Next steps') do
        next_steps = Packs.config.user_event_logger.after_create_pack(pack_name)

        Logging.print_bold_green(next_steps)
      end
    end

    sig do
      params(
        pack_name: String,
        paths_relative_to_root: T::Array[String],
        per_file_processors: T::Array[Packs::PerFileProcessorInterface]
      ).void
    end
    def self.move_to_pack!(pack_name:, paths_relative_to_root:, per_file_processors: [])
      pack_name = Private.clean_pack_name(pack_name)
      package = ParsePackwerk.all.find { |p| p.name == pack_name }
      if package.nil?
        raise StandardError, "Can not find package with name #{pack_name}. Make sure the argument is of the form `packs/my_pack/`"
      end

      add_public_directory(package) if package.enforce_privacy
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

      add_readme_todo(package)

      per_file_processors.each do |processor|
        processor.after_move_files!(file_move_operations)
      end
    end

    sig do
      params(
        pack_name: String,
        destination: String,
        per_file_processors: T::Array[PerFileProcessorInterface]
      ).void
    end
    def self.move_to_folder!(pack_name:, destination:, per_file_processors: [Packs::RubocopPostProcessor.new, Packs::CodeOwnershipPostProcessor.new])
      pack_name = Private.clean_pack_name(pack_name)
      package = ParsePackwerk.all.find { |p| p.name == pack_name }
      if package.nil?
        raise StandardError, "Can not find package with name #{pack_name}. Make sure the argument is of the form `packs/my_pack/`"
      end

      # First we create a new pack that has the exact same properties of the old one!
      package_last_name = package.directory.basename
      new_package_name = File.join(destination, package_last_name)

      new_package = ParsePackwerk::Package.new(
        name: new_package_name,
        enforce_dependencies: package.enforce_dependencies,
        enforce_privacy: package.enforce_privacy,
        enforce_architecture: package.enforce_architecture,
        dependencies: package.dependencies,
        violations: package.violations,
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

        new_config = other_package.config.dup
        if new_config['ignored_dependencies']
          new_config['ignored_dependencies'] = new_config['ignored_dependencies'].map do |d|
            d == pack_name ? new_package_name : d
          end
        end

        new_other_package = ParsePackwerk::Package.new(
          name: other_package.name,
          enforce_dependencies: other_package.enforce_dependencies,
          enforce_privacy: other_package.enforce_privacy,
          enforce_architecture: other_package.enforce_architecture,
          dependencies: new_dependencies.uniq.sort,
          violations: other_package.violations,
          metadata: other_package.metadata,
          config: new_config
        )

        ParsePackwerk.write_package_yml!(new_other_package)
      end

      sorbet_config = Pathname.new('sorbet/config')
      if sorbet_config.exist?
        Packs.replace_in_file(
          file: sorbet_config.to_s,
          find: package.directory.join('spec'),
          replace_with: new_package.directory.join('spec')
        )
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
        parent_package = create_pack_if_not_exists!(
          pack_name: parent_name,
          enforce_dependencies: true,
          enforce_privacy: true,
          enforce_architecture: true
        )
      end

      # First we create a new pack that has the exact same properties of the old one!
      package_last_name = package.directory.basename
      new_package_name = parent_package.directory.join(package_last_name).to_s

      new_package = ParsePackwerk::Package.new(
        name: new_package_name,
        enforce_privacy: package.enforce_privacy,
        enforce_dependencies: package.enforce_dependencies,
        enforce_architecture: package.enforce_architecture,
        dependencies: package.dependencies,
        violations: package.violations,
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

        new_config = other_package.config.dup
        if new_config['ignored_dependencies']
          new_config['ignored_dependencies'] = new_config['ignored_dependencies'].map do |d|
            d == pack_name ? new_package_name : d
          end
        end

        if other_package.name == parent_name &&
           !new_dependencies.include?(new_package_name) &&
           !new_config['ignored_dependencies']&.include?(new_package_name)
          new_dependencies += [new_package_name]
        end

        new_other_package = ParsePackwerk::Package.new(
          name: other_package.name,
          enforce_dependencies: other_package.enforce_dependencies,
          enforce_privacy: other_package.enforce_privacy,
          enforce_architecture: other_package.enforce_architecture,
          dependencies: new_dependencies.uniq.sort,
          violations: other_package.violations,
          metadata: other_package.metadata,
          config: new_config
        )

        ParsePackwerk.write_package_yml!(new_other_package)
      end

      sorbet_config = Pathname.new('sorbet/config')
      if sorbet_config.exist?
        Packs.replace_in_file(
          file: sorbet_config.to_s,
          find: package.directory.join('spec'),
          replace_with: new_package.directory.join('spec')
        )
      end
    end

    sig do
      params(
        paths_relative_to_root: T::Array[String],
        per_file_processors: T::Array[Packs::PerFileProcessorInterface]
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
        enforce_architecture: package.enforce_architecture,
        enforce_dependencies: package.enforce_dependencies,
        violations: package.violations,
        metadata: package.metadata,
        config: package.config
      )
      ParsePackwerk.write_package_yml!(new_package)
      Packs.validate
    end

    sig { params(file_move_operation: FileMoveOperation, per_file_processors: T::Array[Packs::PerFileProcessorInterface]).void }
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
        Logging.print Rainbow("[SKIP] Not moving #{origin}, #{destination} already exists").red
      elsif origin.exist? && !destination.exist?
        destination.dirname.mkpath

        Logging.print "Moving file #{origin} to #{destination}"
        # use git mv so that git knows that it was a move
        FileUtils.mv(origin, destination)
      elsif !origin.exist? && destination.exist?
        Logging.print Rainbow("[SKIP] Not moving #{origin}, does not exist, (#{destination} already exists)").red
      else
        # We could choose to print this in a `--verbose` mode. For now, we find that printing this text in red confuses folks more than it informs them.
        # This is because it's perfectly common for a spec to not exist for a file, so at best it's a warning.
        # Logging.print Rainbow("[SKIP] Not moving #{origin}, does not exist").red
      end
    end

    sig { params(package: ParsePackwerk::Package).void }
    def self.add_public_directory(package)
      public_directory = package.directory.join(package.public_path)

      if public_directory.glob('**/**.rb').none?
        FileUtils.mkdir_p(public_directory)
        todo_md = Packs.config.user_event_logger.on_create_public_directory_todo(package.name)
        public_directory.join('TODO.md').write(todo_md)
      end
    end

    sig { params(package: ParsePackwerk::Package).void }
    def self.add_readme_todo(package)
      pack_directory = package.directory

      if !pack_directory.join('README.md').exist?
        readme_todo_md = Packs.config.user_event_logger.on_create_readme_todo(package.name)
        pack_directory.join('README_TODO.md').write(readme_todo_md)
      end
    end

    sig do
      params(
        pack_name: String,
        enforce_dependencies: T.nilable(T::Boolean),
        enforce_privacy: T::Boolean,
        enforce_architecture: T::Boolean,
        team: T.nilable(CodeTeams::Team)
      ).returns(ParsePackwerk::Package)
    end
    def self.create_pack_if_not_exists!(pack_name:, enforce_dependencies:, enforce_privacy:, enforce_architecture:, team: nil)
      allowed_locations = Packs::Specification.config.pack_paths
      if allowed_locations.none? { |location| File.fnmatch(location, pack_name) }
        raise StandardError, "Packs only supports packages in the the following directories: #{allowed_locations}. Please make sure to pass in the name of the pack including the full directory path, e.g. `packs/my_pack`."
      end

      existing_package = ParsePackwerk.all.find { |p| p.name == pack_name }
      if existing_package.nil?
        should_enforce_dependencies = enforce_dependencies.nil? ? Packs.config.enforce_dependencies : enforce_dependencies

        # TODO: This should probably be `if defined?(CodeOwnership) && CodeOwnership.configured?`
        # but we'll need to add an API to CodeOwnership to do this
        if Pathname.new('config/code_ownership.yml').exist?
          config = {
            'owner' => team.nil? ? 'MyTeam' : team.name
          }
        else
          config = {}
        end

        package = ParsePackwerk::Package.new(
          enforce_dependencies: should_enforce_dependencies || false,
          enforce_privacy: enforce_privacy,
          enforce_architecture: enforce_architecture,
          dependencies: [],
          violations: [],
          metadata: {},
          name: pack_name,
          config: config
        )

        ParsePackwerk.write_package_yml!(package)

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
      client_configuration = Pathname.pwd.join('config/packs.rb')
      require client_configuration.to_s if client_configuration.exist?
    end

    sig { void }
    def self.bust_cache!
      Packs.config.bust_cache!
      # This comes explicitly after `Packs.config.bust_cache!` because
      # otherwise `Packs.config` will attempt to reload the client configuratoin.
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

    sig do
      params(
        packs: T::Array[Packs::Pack],
        format: Symbol,
        types: T::Array[Symbol],
        include_date: T::Boolean
      ).void
    end
    def self.get_info(packs: Packs.all, format: :detail, types: %i[privacy dependency architecture], include_date: false)
      require 'csv' if format == :csv

      today = Date.today.iso8601
      violations = {
        inbound: {},
        outbound: {}
      }

      package_by_name = {}

      ParsePackwerk.all.each do |p|
        package_by_name[p.name] = p
        p.violations.each do |violation|
          violations[:outbound][p.name] ||= []
          violations[:outbound][p.name] << violation
          violations[:inbound][violation.to_package_name] ||= []
          violations[:inbound][violation.to_package_name] << violation
        end
      end

      all = {
        inbound: T.let([], T::Array[ParsePackwerk::Violation]),
        outbound: T.let([], T::Array[ParsePackwerk::Violation])
      }
      packs.each do |pack|
        all[:inbound] += violations[:inbound][pack.name] || []
        all[:outbound] += violations[:outbound][pack.name] || []
      end

      case format
      when :csv
        headers = ['Date', 'Pack name', 'Owned by', 'Size', 'Public API']
        headers.delete('Date') unless include_date
        types.each do |type|
          headers << "Inbound #{type} violations"
          headers << "Outbound #{type} violations"
        end
        puts CSV.generate_line(headers)
      else # :detail
        puts "Date: #{today}" if include_date
        types.each do |type|
          inbound_count = all[:inbound].select { _1.type.to_sym == type }.sum { |v| v.files.count }
          outbound_count = all[:outbound].select { _1.type.to_sym == type }.sum { |v| v.files.count }
          puts "There are #{inbound_count} total inbound #{type} violations"
          puts "There are #{outbound_count} total outbound #{type} violations"
        end
      end

      packs.sort_by { |p| -p.relative_path.glob('**/*.rb').count }.each do |pack|
        owner = CodeOwnership.for_package(pack)

        row = {
          date: today,
          pack_name: pack.name,
          owner: owner.nil? ? 'No one' : owner.name,
          size: pack.relative_path.glob('**/*.rb').count,
          public_api: pack.relative_path.join(package_by_name[pack.name].public_path)
        }

        row.delete(:date) unless include_date

        types.each do |type|
          key = ['inbound', type, 'violations'].join('_').to_sym
          row[key] = (violations[:inbound][pack.name] || []).select { _1.type.to_sym == type }.sum { |v| v.files.count }
          key = ['outbound', type, 'violations'].join('_').to_sym
          row[key] = (violations[:outbound][pack.name] || []).select { _1.type.to_sym == type }.sum { |v| v.files.count }
        end

        case format
        when :csv
          puts CSV.generate_line(row.values)
        else # :detail
          puts "\n=========== Info about: #{row[:pack_name]}"

          puts "Date: #{row[:date]}" if include_date
          puts "Owned by: #{row[:owner]}"
          puts "Size: #{row[:size]} ruby files"
          puts "Public API: #{row[:public_api]}"
          types.each do |type|
            key = ['inbound', type, 'violations'].join('_').to_sym
            puts "There are #{row[key]} inbound #{type} violations"
            key = ['outbound', type, 'violations'].join('_').to_sym
            puts "There are #{row[key]} outbound #{type} violations"
          end
        end
      end
    end

    sig { void }
    def self.lint_package_todo_yml_files!
      contents_before = Private.get_package_todo_contents
      Packs.update
      contents_after = Private.get_package_todo_contents
      diff = Private.diff_package_todo_yml(contents_before, contents_after)

      if diff == ''
        # No diff generated by `update-todo`
        exit_with true
      else
        output = <<~OUTPUT
          All `package_todo.yml` files must be up-to-date and that no diff is generated when running `bin/packwerk update-todo`.
          This helps ensure a high quality signal in other engineers' PRs when inspecting new violations by ensuring there are no unrelated changes.

          There are three main reasons there may be a diff:
          1) Most likely, you may have stale violations, meaning there are old violations that no longer apply.
          2) You may have some sort of auto-formatter set up somewhere (e.g. something that reformats YML files) that is, for example, changing double quotes to single quotes. Ensure this is turned off for these auto-generated files.
          3) You may have edited these files manually. It's recommended to use the `bin/packwerk update-todo` command to make changes to `package_todo.yml` files.

          In all cases, you can run `bin/packwerk update-todo` to update these files.

          Here is the diff generated after running `update-todo`:
          ```
          #{diff}
          ```

        OUTPUT

        puts output
        Packs.config.on_package_todo_lint_failure.call(output)
        exit_with false
      end
    end

    sig { params(packs: T::Array[Packs::Pack]).void }
    def self.lint_package_yml_files!(packs)
      packs.each do |p|
        packwerk_package = ParsePackwerk.find(p.name)
        next if packwerk_package.nil?

        new_metadata = packwerk_package.metadata
        new_config = packwerk_package.config

        # Move metadata owner key to top-level
        existing_owner = new_config['owner'] || new_metadata.delete('owner')
        new_config['owner'] = existing_owner if !existing_owner.nil?

        if new_metadata.empty?
          new_config.delete('metadata')
        end

        new_package = packwerk_package.with(
          config: new_config,
          metadata: new_metadata,
          dependencies: packwerk_package.dependencies.uniq.sort
        )

        ParsePackwerk.write_package_yml!(new_package)
      end
    end

    sig { params(config: T::Hash[T.anything, T.anything]).returns(T::Hash[T.anything, T.anything]) }
    def self.sort_keys(config)
      sort_order = ParsePackwerk.key_sort_order
      config.to_a.sort_by { |key, _value| T.unsafe(sort_order).index(key) }.to_h
    end

    sig { returns(String) }
    def self.rename_pack
      <<~WARNING
        We do not yet have an automated API for this.

        Follow these steps:
        1. Rename the `packs/your_pack` directory to the name of the new pack, `packs/new_pack_name
        2. Replace references to `- packs/your_pack` in `package.yml` files with `- packs/new_pack_name`
        3. Rerun `bin/packwerk update-todo` to update violations
        4. Run `bin/codeownership validate` to update ownership information
        5. Please let us know if anything is missing.
      WARNING
    end

    # This function exists to give us something to stub in test
    sig { params(code: T::Boolean).void }
    def self.exit_with(code)
      exit code
    end

    # This function exists to give us something to stub in test
    sig { params(command: String).returns(T::Boolean) }
    def self.system_with(command)
      T.cast(system(command), T::Boolean)
    end
  end

  private_constant :Private
end
