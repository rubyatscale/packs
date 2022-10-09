# typed: strict

# Ruby internal requires
require 'fileutils'

# External gem requires
require 'colorized_string'

# Internal gem requires
require 'parse_packwerk'
require 'code_teams'
require 'code_ownership'
require 'package_protections'

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
end
