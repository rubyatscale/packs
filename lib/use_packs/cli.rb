# typed: strict

require 'thor'

module UsePacks
  class CLI < Thor
    extend T::Sig

    desc 'create packs/your_pack', 'Create pack with name packs/your_pack'
    sig { params(pack_name: String).void }
    def create(pack_name)
      UsePacks.create_pack!(pack_name: pack_name)
    end

    desc 'add_dependency packs/from_pack packs/to_pack', 'Add packs/to_pack to packs/from_pack/package.yml list of dependencies'
    long_desc <<~LONG_DESC
      Use this to add a dependency between packs.

      When you use bin/packs add_dependency packs/from_pack packs/to_pack, this command will
      modify packs/from_pack/package.yml's list of dependencies and add packs/to_pack.

      This command will also sort the list and make it unique.
    LONG_DESC
    sig { params(from_pack: String, to_pack: String).void }
    def add_dependency(from_pack, to_pack)
      UsePacks.add_dependency!(
        pack_name: from_pack,
        dependency_name: to_pack
      )
    end

    desc 'list_top_dependency_violations packs/your_pack', 'List the top dependency violations of packs/your_pack'
    long_desc <<~LONG_DESC
      Want to see who is depending on you? Not sure how your pack's code is being used in an unstated way

      You can use this command to list the top dependency violations.

      If no pack name is passed in, this will list out violations across all packs.
    LONG_DESC
    option :limit, type: :numeric, default: 10, aliases: :l, banner: 'Specify the limit of constants to analyze'
    sig { params(pack_name: String).void }
    def list_top_dependency_violations(pack_name)
      UsePacks.list_top_dependency_violations(
        pack_name: pack_name,
        limit: options[:limit]
      )
    end

    desc 'list_top_privacy_violations packs/your_pack', 'List the top privacy violations of packs/your_pack'
    long_desc <<~LONG_DESC
      Want to create interfaces? Not sure how your pack's code is being used?

      You can use this command to list the top privacy violations.

      If no pack name is passed in, this will list out violations across all packs.
    LONG_DESC
    option :limit, type: :numeric, default: 10, aliases: :l, banner: 'Specify the limit of constants to analyze'
    sig { params(pack_name: String).void }
    def list_top_privacy_violations(pack_name)
      UsePacks.list_top_privacy_violations(
        pack_name: pack_name,
        limit: options[:limit]
      )
    end

    desc 'make_public path/to/file.rb path/to/directory', 'Pass in a space-separated list of file or directory paths to make public'
    long_desc <<~LONG_DESC
      This moves a file or directory to public API (that is -- the `app/public` folder).

      Make sure there are no spaces between the comma-separated list of paths of directories.
    LONG_DESC
    sig { params(paths: String).void }
    def make_public(*paths)
      UsePacks.make_public!(
        paths_relative_to_root: paths,
        per_file_processors: [UsePacks::RubocopPostProcessor.new, UsePacks::CodeOwnershipPostProcessor.new]
      )
    end

    desc 'move packs/destination_pack path/to/file.rb path/to/directory', 'Pass in a destination pack and a space-separated list of file or directory paths to move to the destination pack'
    long_desc <<~LONG_DESC
      This is used for moving files into a pack (the pack must already exist).
      Note this works for moving files to packs from the monolith or from other packs

      Make sure there are no spaces between the comma-separated list of paths of directories.
    LONG_DESC
    sig { params(pack_name: String, paths: String).void }
    def move(pack_name, *paths)
      UsePacks.move_to_pack!(
        pack_name: pack_name,
        paths_relative_to_root: paths,
        per_file_processors: [UsePacks::RubocopPostProcessor.new, UsePacks::CodeOwnershipPostProcessor.new]
      )
    end

    desc 'lint_package_todo_yml_files', 'Ensures `package_todo.yml` files are up to date'
    sig { void }
    def lint_package_todo_yml_files
      UsePacks.lint_package_todo_yml_files!
    end

    desc 'lint_package_yml_files [ packs/my_pack packs/my_other_pack ]', 'Lint `package.yml` files'
    sig { params(pack_names: String).void }
    def lint_package_yml_files(*pack_names)
      UsePacks.lint_package_yml_files!(parse_pack_names(pack_names))
    end

    desc 'validate', 'Run bin/packwerk validate (detects cycles)'
    sig { void }
    def validate
      system('bin/packwerk validate')
    end

    desc 'check [ packs/my_pack ]', 'Run bin/packwerk check'
    sig { params(paths: String).void }
    def check(*paths)
      UsePacks.execute(['check', *paths])
    end

    desc 'update', 'Run bin/packwerk update-todo'
    sig { void }
    def update
      system('bin/packwerk update-todo')
    end

    desc 'regenerate_rubocop_todo [ packs/my_pack packs/my_other_pack ]', "Regenerate packs/*/#{RuboCop::Packs::PACK_LEVEL_RUBOCOP_TODO_YML} for one or more packs"
    sig { params(pack_names: String).void }
    def regenerate_rubocop_todo(*pack_names)
      RuboCop::Packs.regenerate_todo(packs: parse_pack_names(pack_names))
    end

    desc 'get_info [ packs/my_pack packs/my_other_pack ]', 'Get info about size and violations for packs'
    sig { params(pack_names: String).void }
    def get_info(*pack_names)
      Private.get_info(packs: parse_pack_names(pack_names))
    end

    desc 'visualize [ packs/my_pack packs/my_other_pack ]', 'Visualize packs'
    sig { params(pack_names: String).void }
    def visualize(*pack_names)
      Private.visualize(packs: parse_pack_names(pack_names))
    end

    desc 'rename', 'Rename a pack'
    sig { void }
    def rename
      puts Private.rename_pack
    end

    desc 'move_to_parent packs/child_pack packs/parent_pack ', 'Sets packs/child_pack as a child of packs/parent_pack'
    sig { params(child_pack_name: String, parent_pack_name: String).void }
    def move_to_parent(child_pack_name, parent_pack_name)
      UsePacks.move_to_parent!(
        parent_name: parent_pack_name,
        pack_name: child_pack_name,
        per_file_processors: [UsePacks::RubocopPostProcessor.new, UsePacks::CodeOwnershipPostProcessor.new]
      )
    end

    private

    # This is used by thor to know that these private methods are not intended to be CLI commands
    no_commands do
      sig { params(pack_names: T::Array[String]).returns(T::Array[Packs::Pack]) }
      def parse_pack_names(pack_names)
        pack_names.empty? ? Packs.all : pack_names.map { |p| Packs.find(p.gsub(%r{/$}, '')) }.compact
      end
    end
  end
end
