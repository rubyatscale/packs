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

  sig do
    params(
      pack_name: String,
      enforce_privacy: T::Boolean,
      enforce_dependencies: T.nilable(T::Boolean)
    ).void
  end
  def self.create_pack!(
    pack_name:,
    enforce_privacy: true,
    enforce_dependencies: nil
  )
    Private.create_pack!(
      pack_name: pack_name,
      enforce_privacy: enforce_privacy,
      enforce_dependencies: enforce_dependencies
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
      intro = <<~INTRO
        You are moving a file to a pack, which is great. Check out #{UsePackwerk.config.documentation_link} for more info!

        Please bring any questions or issues you have in your development process to #ruby-modularity or #product-infrastructure.
        We'd be happy to try to help through pairing, accepting feedback, changing our process, changing our tools, and more.
      INTRO
      Logging.print_bold_green(intro)
    end

    Private.move_to_pack!(
      pack_name: pack_name,
      paths_relative_to_root: paths_relative_to_root,
      per_file_processors: per_file_processors
    )

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
      paths_relative_to_root: T::Array[String],
      per_file_processors: T::Array[PerFileProcessorInterface]
    ).void
  end
  def self.make_public!(
    paths_relative_to_root: [],
    per_file_processors: []
  )
    Logging.section('Making files public') do
      intro = <<~INTRO
        You are moving some files into public API. See #{UsePackwerk.config.documentation_link} for other utilities!
      INTRO
      Logging.print_bold_green(intro)
    end

    Private.make_public!(
      paths_relative_to_root: paths_relative_to_root,
      per_file_processors: per_file_processors
    )

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
  def self.add_dependency!(
    pack_name:,
    dependency_name:
  )
    Logging.section('Adding a dependency') do
      intro = <<~INTRO
        You are adding a dependency. See #{UsePackwerk.config.documentation_link} for other utilities!
      INTRO
      Logging.print_bold_green(intro)
    end

    Private.add_dependency!(
      pack_name: pack_name,
      dependency_name: dependency_name
    )

    Logging.section('Next steps') do
      next_steps = <<~NEXT_STEPS
        Your next steps might be:

        1) Run `bin/packwerk validate` to ensure you haven't introduced a cyclic dependency

        2) Run `bin/packwerk update-deprecations` to update the violations.
      NEXT_STEPS

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
      intro = <<~INTRO
        You are moving one pack to be a child of a different pack. Check out #{UsePackwerk.config.documentation_link} for more info!

        Please bring any questions or issues you have in your development process to #ruby-modularity or #product-infrastructure.
        We'd be happy to try to help through pairing, accepting feedback, changing our process, changing our tools, and more.
      INTRO
      Logging.print_bold_green(intro)
    end

    Private.move_to_parent!(
      pack_name: pack_name,
      parent_name: parent_name,
      per_file_processors: per_file_processors
    )

    Logging.section('Next steps') do
      next_steps = <<~NEXT_STEPS
        Your next steps might be:

        1) Delete the old pack when things look good: `rm -rf #{pack_name}`

        2) Run `bin/packwerk update-deprecations` to update the violations. Make sure to run `spring stop` first.
      NEXT_STEPS

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
end
