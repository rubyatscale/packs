# typed: strict

module Packs
  module UserEventLogger
    extend T::Sig
    extend T::Helpers

    abstract!

    sig { params(pack_name: String).returns(String) }
    def before_create_pack(pack_name)
      <<~MSG
        You are creating a pack, which is great. Check out #{documentation_link} for more info!
      MSG
    end

    sig { params(pack_name: String).returns(String) }
    def after_create_pack(pack_name)
      <<~MSG
        Your next steps might be:

        1) Move files into your pack with `bin/packs move #{pack_name} path/to/file.rb`

        2) Run `bin/packwerk update-todo` to update the violations. Make sure to run `spring stop` if you've added new load paths (new top-level directories) in your pack.

        3) Expose public API in #{pack_name}/#{ParsePackwerk::DEFAULT_PUBLIC_PATH}. Try `bin/packs make_public #{pack_name}/path/to/file.rb`

        4) Update your readme at #{pack_name}/README.md
      MSG
    end

    sig { params(pack_name: String).returns(String) }
    def before_move_to_pack(pack_name)
      <<~MSG
        You are moving a file to a pack, which is great. Check out #{documentation_link} for more info!
      MSG
    end

    sig { params(pack_name: String).returns(String) }
    def after_move_to_pack(pack_name)
      <<~MSG
        Your next steps might be:

        1) Run `bin/packwerk update-todo` to update the violations. Make sure to run `spring stop` if you've added new load paths (new top-level directories) in your pack.

        2) Touch base with each team who owns files involved in this move

        3) Expose public API in #{pack_name}/#{ParsePackwerk::DEFAULT_PUBLIC_PATH}. Try `bin/packs make_public #{pack_name}/path/to/file.rb`

        4) Update your readme at #{pack_name}/README.md
      MSG
    end

    sig { returns(String) }
    def before_make_public
      <<~MSG
        You are moving some files into public API. See #{documentation_link} for other utilities!
      MSG
    end

    sig { returns(String) }
    def after_make_public
      <<~MSG
        Your next steps might be:

        1) Run `bin/packwerk update-todo` to update the violations. Make sure to run `spring stop` if you've added new load paths (new top-level directories) in your pack.

        2) Work to migrate clients of private API to your new public API

        3) Update your README at packs/your_package_name/README.md
      MSG
    end

    sig { params(pack_name: String).returns(String) }
    def before_add_dependency(pack_name)
      <<~MSG
        You are adding a dependency. See #{documentation_link} for other utilities!
      MSG
    end

    sig { params(pack_name: String).returns(String) }
    def after_add_dependency(pack_name)
      <<~MSG
        Your next steps might be:

        1) Run `bin/packwerk update-todo` to update the violations.
      MSG
    end

    sig { params(pack_name: String).returns(String) }
    def before_move_to_parent(pack_name)
      <<~MSG
        You are moving one pack to be a child of a different pack. Check out #{documentation_link} for more info!
      MSG
    end

    sig { params(pack_name: String).returns(String) }
    def after_move_to_parent(pack_name)
      <<~MSG
        Your next steps might be:

        1) Delete the old pack when things look good: `git rm -r #{pack_name}`

        2) Run `bin/packwerk update-todo` to update the violations. Make sure to run `spring stop` first.
      MSG
    end

    sig { params(pack_name: String).returns(String) }
    def before_move_to_folder(pack_name)
      <<~MSG
        You are moving one pack to a new directory. Check out #{documentation_link} for more info!
      MSG
    end

    sig { params(pack_name: String).returns(String) }
    def after_move_to_folder(pack_name)
      <<~MSG
        Your next steps might be:

        1) Delete the old pack when things look good: `git rm -r #{pack_name}`

        2) Run `bin/packwerk update-todo` to update the violations. Make sure to run `spring stop` first.
      MSG
    end

    sig { params(pack_name: String).returns(String) }
    def on_create_public_directory_todo(pack_name)
      <<~MSG
        This directory holds your public API!

        Any classes, constants, or modules that you want other packs to use and you intend to support should go in here.
        Anything that is considered private should go in other folders.

        If another pack uses classes, constants, or modules that are not in your public folder, it will be considered a "privacy violation" by packwerk.
        You can prevent other packs from using private API by using packwerk.

        Want to find how your private API is being used today?
        Try running: `bin/packs list_top_violations privacy #{pack_name}`

        Want to move something into this folder?
        Try running: `bin/packs make_public #{pack_name}/path/to/file.rb`

        One more thing -- feel free to delete this file and replace it with a README.md describing your package in the main package directory.

        See #{documentation_link} for more info!
      MSG
    end

    sig { params(pack_name: String).returns(String) }
    def on_create_readme_todo(pack_name)
      <<~MSG
        Welcome to `#{pack_name}`!

        If you're the author, please consider replacing this file with a README.md, which may contain:
        - What your pack is and does
        - How you expect people to use your pack
        - Example usage of your pack's public API (which lives in `#{pack_name}/#{ParsePackwerk::DEFAULT_PUBLIC_PATH}`)
        - Limitations, risks, and important considerations of usage
        - How to get in touch with eng and other stakeholders for questions or issues pertaining to this pack (note: it is recommended to add ownership in `#{pack_name}/package.yml` under the `owner` metadata key)
        - What SLAs/SLOs (service level agreements/objectives), if any, your package provides
        - When in doubt, keep it simple
        - Anything else you may want to include!

        README.md files are under version control and should change as your public API changes.#{' '}

        See #{documentation_link} for more info!
      MSG
    end

    sig { params(type: String, pack_name: T.nilable(String), limit: Integer).returns(String) }
    def before_list_top_violations(type, pack_name, limit)
      if pack_name.nil?
        <<~PACK_CONTENT
          You are listing top #{limit} #{type} violations for all packs. See #{documentation_link} for other utilities!
          Pass in a limit to display more or less, e.g. `bin/packs list_top_violations #{type} #{pack_name} -l 1000`

          This script is intended to help you find which of YOUR pack's private classes, constants, or modules other packs are using the most.
          Anything not in pack_name/#{ParsePackwerk::DEFAULT_PUBLIC_PATH} is considered private API.
        PACK_CONTENT
      else
        <<~PACK_CONTENT
          You are listing top #{limit} #{type} violations for #{pack_name}. See #{documentation_link} for other utilities!
          Pass in a limit to display more or less, e.g. `bin/packs list_top_violations #{type} #{pack_name} -l 1000`

          This script is intended to help you find which of YOUR pack's private classes, constants, or modules other packs are using the most.
          Anything not in #{pack_name}/#{ParsePackwerk::DEFAULT_PUBLIC_PATH} is considered private API.
        PACK_CONTENT
      end
    end

    sig { returns(String) }
    def documentation_link
      'https://github.com/rubyatscale/packs#readme'
    end
  end
end
