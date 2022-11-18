# typed: strict

# Ruby internal requires
require 'fileutils'

# External gem requires
require 'colorized_string'

# Internal gem requires
require 'parse_packwerk'
require 'code_teams'
require 'code_ownership'
require 'rubocop-packs'

# Private implementation requires
require 'use_packwerk/private'
require 'use_packwerk/per_file_processor_interface'
require 'use_packwerk/rubocop_post_processor'
require 'use_packwerk/code_ownership_post_processor'
require 'use_packwerk/logging'
require 'use_packwerk/configuration'
require 'use_packwerk/cli'

module UsePackwerk
  extend T::Sig

  PERMITTED_PACK_LOCATIONS = T.let(%w[
                                     gems
                                     components
                                     packs
                                   ], T::Array[String])

  sig { void }
  def self.start_interactive_mode!
    Private::InteractiveCli.start!
  end

  sig do
    params(
      pack_name: String,
      enforce_privacy: T::Boolean,
      enforce_dependencies: T.nilable(T::Boolean),
      team: T.nilable(CodeTeams::Team)
    ).void
  end
  def self.create_pack!(
    pack_name:,
    enforce_privacy: true,
    enforce_dependencies: nil,
    team: nil
  )
    Private.create_pack!(
      pack_name: pack_name,
      enforce_privacy: enforce_privacy,
      enforce_dependencies: enforce_dependencies,
      team: team
    )
  end

  sig do
    params(
      pack_name: String,
      paths_relative_to_root: T::Array[String],
      per_file_processors: T::Array[PerFileProcessorInterface]
    ).void
  end
  def self.move_to_pack!(
    pack_name:,
    paths_relative_to_root: [],
    per_file_processors: []
  )
    Logging.section('👋 Hi!') do
      intro = UsePackwerk.config.user_event_logger.before_move_to_pack(pack_name)
      Logging.print_bold_green(intro)
    end

    Private.move_to_pack!(
      pack_name: pack_name,
      paths_relative_to_root: paths_relative_to_root,
      per_file_processors: per_file_processors
    )

    Logging.section('Next steps') do
      next_steps = UsePackwerk.config.user_event_logger.after_move_to_pack(pack_name)
      Logging.print_bold_green(next_steps)
    end
  end

  sig do
    params(
      paths_relative_to_root: T::Array[String],
      per_file_processors: T::Array[PerFileProcessorInterface]
    ).void
  end
  def self.make_public!(
    paths_relative_to_root: [],
    per_file_processors: []
  )
    Logging.section('Making files public') do
      intro = UsePackwerk.config.user_event_logger.before_make_public
      Logging.print_bold_green(intro)
    end

    Private.make_public!(
      paths_relative_to_root: paths_relative_to_root,
      per_file_processors: per_file_processors
    )

    Logging.section('Next steps') do
      next_steps = UsePackwerk.config.user_event_logger.after_make_public
      Logging.print_bold_green(next_steps)
    end
  end

  sig do
    params(
      pack_name: String,
      dependency_name: String
    ).void
  end
  def self.add_dependency!(
    pack_name:,
    dependency_name:
  )
    Logging.section('Adding a dependency') do
      intro = UsePackwerk.config.user_event_logger.before_add_dependency(pack_name)
      Logging.print_bold_green(intro)
    end

    Private.add_dependency!(
      pack_name: pack_name,
      dependency_name: dependency_name
    )

    Logging.section('Next steps') do
      next_steps = UsePackwerk.config.user_event_logger.after_add_dependency(pack_name)
      Logging.print_bold_green(next_steps)
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
    Logging.section('👋 Hi!') do
      intro = UsePackwerk.config.user_event_logger.before_move_to_parent(pack_name)
      Logging.print_bold_green(intro)
    end

    Private.move_to_parent!(
      pack_name: pack_name,
      parent_name: parent_name,
      per_file_processors: per_file_processors
    )

    Logging.section('Next steps') do
      next_steps = UsePackwerk.config.user_event_logger.after_move_to_parent(pack_name)

      Logging.print_bold_green(next_steps)
    end
  end

  sig do
    params(
      pack_name: T.nilable(String),
      limit: Integer
    ).void
  end
  def self.list_top_privacy_violations(
    pack_name:,
    limit:
  )
    Private::PackRelationshipAnalyzer.list_top_privacy_violations(
      pack_name,
      limit
    )
  end

  sig do
    params(
      pack_name: T.nilable(String),
      limit: Integer
    ).void
  end
  def self.list_top_dependency_violations(
    pack_name:,
    limit:
  )
    Private::PackRelationshipAnalyzer.list_top_dependency_violations(
      pack_name,
      limit
    )
  end

  sig do
    params(
      file: String,
      find: Pathname,
      replace_with: Pathname
    ).void
  end
  def self.replace_in_file(file:, find:, replace_with:)
    Private.replace_in_file(
      file: file,
      find: find,
      replace_with: replace_with
    )
  end

  sig { void }
  def self.bust_cache!
    Private.bust_cache!
  end

  #
  # execute_command is like `run` except it does not `exit`
  #
  sig { params(argv: T.untyped, formatter: T.nilable(Packwerk::OffensesFormatter)).void }
  def self.execute(argv, formatter = nil)
    Private::PackwerkWrapper.with_safe_exit_if_no_files_found do
      Private::PackwerkWrapper.packwerk_cli(formatter).execute_command(argv)
    end
  end

  sig { params(files: T::Array[String]).returns(T::Array[Packwerk::ReferenceOffense]) }
  def self.get_offenses_for_files(files)
    formatter = Private::PackwerkWrapper::OffensesAggregatorFormatter.new
    Private::PackwerkWrapper.packwerk_cli_execute_safely(['check', *files], formatter)
    formatter.aggregated_offenses.compact
  end

  sig { params(files: T::Array[String]).returns(T::Array[Packwerk::ReferenceOffense]) }
  def self.get_offenses_for_files_by_package(files)
    packages = Private::PackwerkWrapper.package_names_for_files(files)
    argv = ['check', '--packages', packages.join(',')]
    formatter = Private::PackwerkWrapper::OffensesAggregatorFormatter.new
    Private::PackwerkWrapper.packwerk_cli_execute_safely(argv, formatter)
    formatter.aggregated_offenses.compact
  end

  sig { void }
  def self.lint_deprecated_references_yml_files!
    contents_before = Private.get_deprecated_references_contents
    UsePackwerk.execute(['update-deprecations'])
    contents_after = Private.get_deprecated_references_contents
    diff = Private.diff_deprecated_references_yml(contents_before, contents_after)

    if diff == ''
      # No diff generated by `update-deprecations`
      exit 0
    else
      output = <<~OUTPUT
        All `deprecated_references.yml` files must be up-to-date and that no diff is generated when running `bin/packwerk update-deprecations`.
        This helps ensure a high quality signal in other engineers' PRs when inspecting new violations by ensuring there are no unrelated changes.

        There are three main reasons there may be a diff:
        1) Most likely, you may have stale violations, meaning there are old violations that no longer apply.
        2) You may have some sort of auto-formatter set up somewhere (e.g. something that reformats YML files) that is, for example, changing double quotes to single quotes. Ensure this is turned off for these auto-generated files.
        3) You may have edited these files manually. It's recommended to use the `bin/packwerk update-deprecations` command to make changes to `deprecated_references.yml` files.

        In all cases, you can run `bin/packwerk update-deprecations` to update these files.

        Here is the diff generated after running `update-deprecations`:
        ```
        #{diff}
        ```

      OUTPUT

      puts output
      UsePackwerk.config.on_deprecated_references_lint_failure.call(output)

      exit 1
    end
  end

  sig { params(packs: T::Array[ParsePackwerk::Package]).void }
  def self.lint_package_yml_files!(packs)
    packs.each do |p|
      new_package = ParsePackwerk::Package.new(
        name: p.name,
        enforce_privacy: p.enforce_privacy,
        enforce_dependencies: p.enforce_dependencies,
        dependencies: p.dependencies.uniq.sort,
        metadata: p.metadata
      )
      ParsePackwerk.write_package_yml!(new_package)
    end
  end
end
