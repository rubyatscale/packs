# typed: strict

require 'thor'

module UsePackwerk
  class CLI < Thor
    extend T::Sig

    desc "create packs/your_pack", "Create pack with name packs/your_pack"
    sig { params(pack_name: String).void }
    def create(pack_name)
      UsePackwerk.create_pack!(pack_name: pack_name)
    end

    desc "add_dependency packs/from_pack packs/to_pack", "Add packs/to_pack to packs/from_pack/package.yml list of dependencies"
    long_desc <<~LONG_DESC
      Use this to add a dependency between packs.

      When you use bin/use_packwerk add_dependency packs/from_pack packs/to_pack, this command will
      modify packs/from_pack/package.yml's list of dependencies and add packs/to_pack.

      This command will also sort the list and make it unique.
    LONG_DESC
    sig { params(from_pack: String, to_pack: String).void }
    def add_dependency(from_pack, to_pack)
      UsePackwerk.add_dependency!(
        pack_name: from_pack,
        dependency_name: to_pack
      )
    end

    desc "list_top_dependency_violations packs/your_pack", "List the top dependency violations of packs/your_pack"
    option :limit, type: :numeric, default: 10, aliases: :l, banner: 'Specify the limit of constants to analyze'
    sig { params(pack_name: String).void }
    def list_top_dependency_violations(pack_name)
      UsePackwerk.list_top_dependency_violations(
        pack_name: pack_name,
        limit: options[:limit]
      )
    end

    desc "list_top_privacy_violations packs/your_pack", "List the top privacy violations of packs/your_pack"
    option :limit, type: :numeric, default: 10, aliases: :l, banner: 'Specify the limit of constants to analyze'
    sig { params(pack_name: String).void }
    def list_top_privacy_violations(pack_name)
      UsePackwerk.list_top_privacy_violations(
        pack_name: pack_name,
        limit: options[:limit]
      )
    end

    desc "make_public path/to/file.rb path/to/directory", "Pass in a space-separated list of file or directory paths to make public"
    sig { params(paths: String).void }
    def make_public(*paths)
      UsePackwerk.make_public!(
        paths_relative_to_root: paths,
        per_file_processors: [UsePackwerk::RubocopPostProcessor.new, UsePackwerk::CodeOwnershipPostProcessor.new],
      )
    end

    desc "move packs/destination_pack path/to/file.rb path/to/directory", "Pass in a destination pack and a space-separated list of file or directory paths to move to the destination pack"
    sig { params(pack_name: String, paths: String).void }
    def move(pack_name, *paths)
      UsePackwerk.move_to_pack!(
        pack_name: pack_name,
        paths_relative_to_root: paths,
        per_file_processors: [UsePackwerk::RubocopPostProcessor.new, UsePackwerk::CodeOwnershipPostProcessor.new],
      )
    end

    desc "move_to_parent packs/parent_pack packs/child_pack", "Pass in a parent pack and another pack to be made as a child to the parent pack!"
    sig { params(parent_name: String, pack_name: String).void }
    def move_to_parent(parent_name, pack_name)
      UsePackwerk.move_to_parent!(
        parent_name: parent_name,
        pack_name: pack_name,
        per_file_processors: [UsePackwerk::RubocopPostProcessor.new, UsePackwerk::CodeOwnershipPostProcessor.new],
      )
    end
  end
end
