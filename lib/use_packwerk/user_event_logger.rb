# typed: strict

module UsePackwerk
  module UserEventLogger
    extend T::Sig
    extend T::Helpers

    abstract!

    sig { params(pack_name: String).returns(String) }
    def before_create_pack(pack_name)
      <<~MSG
        You are creating a pack, which is great. Check out #{UsePackwerk.config.documentation_link} for more info!

        Please bring any questions or issues you have in your development process to #ruby-modularity or #product-infrastructure.
        We'd be happy to try to help through pairing, accepting feedback, changing our process, changing our tools, and more.
      MSG
    end

    sig { params(pack_name: String).returns(String) }
    def after_create_pack(pack_name)
      <<~MSG
        Your next steps might be:

        1) Move files into your pack with `bin/use_packwerk move #{pack_name} path/to/file.rb`

        2) Run `bin/packwerk update-deprecations` to update the violations. Make sure to run `spring stop` if you've added new load paths (new top-level directories) in your pack.

        3) Update TODO lists for rubocop implemented protections. See #{UsePackwerk.config.documentation_link} for more info

        4) Expose public API in #{pack_name}/app/public. Try `bin/use_packwerk make_public #{pack_name}/path/to/file.rb`

        5) Update your readme at #{pack_name}/README.md
      MSG
    end

    sig { params(pack_name: String).returns(String) }
    def before_move_to_pack(pack_name)
      <<~MSG
        You are moving a file to a pack, which is great. Check out #{UsePackwerk.config.documentation_link} for more info!

        Please bring any questions or issues you have in your development process to #ruby-modularity or #product-infrastructure.
        We'd be happy to try to help through pairing, accepting feedback, changing our process, changing our tools, and more.
      MSG
    end

    sig { params(pack_name: String).returns(String) }
    def after_move_to_pack(pack_name)
      <<~MSG
        Your next steps might be:

        1) Run `bin/packwerk update-deprecations` to update the violations. Make sure to run `spring stop` if you've added new load paths (new top-level directories) in your pack.

        2) Update TODO lists for rubocop implemented protections. See #{UsePackwerk.config.documentation_link} for more info

        3) Touch base with each team who owns files involved in this move

        4) Expose public API in #{pack_name}/app/public. Try `bin/use_packwerk make_public #{pack_name}/path/to/file.rb`

        5) Update your readme at #{pack_name}/README.md
      MSG
    end
  end
end
