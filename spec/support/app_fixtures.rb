# typed: false

RSpec.shared_context 'app fixtures' do
  # let(:complex_app) do
  #   write_file('.rubocop_todo.yml', <<~CONTENTS)
  #     # This is an application-specific file that is used to test post-processing abilities
  #     ---
  #     Some/Cop/Does/Not/Matter:
  #       Exclude:
  #       - app/services/horse_like/zebra.rb
  #       - app/services/fish_like/small_ones/goldfish.rb
  #       - app/services/dog_like/golden_retriever.rb
  #     Layout/BeginEndAlignment:
  #       Exclude:
  #       - app/services/fish_like/small_ones/goldfish.rb
  #       - app/services/fish_like/big_ones/whale.rb
  #   CONTENTS

  #   write_file('app/services/horse_like/donkey.rb', <<~CONTENTS)
  #     # typed: strict
  #     # so rubocop does not complain
  #     def empty_function; end
  #   CONTENTS

  #   write_file('app/services/horse_like/horse.rb', <<~CONTENTS)
  #     # typed: strict
  #     # so rubocop does not complain
  #     def empty_function; end
  #   CONTENTS

  #   write_file('app/services/horse_like/zebra.rb', <<~CONTENTS)
  #     # typed: strict
  #     # so rubocop does not complain
  #     def empty_function; end
  #   CONTENTS

  #   write_file('app/services/fish_like/small_ones/goldfish.rb', <<~CONTENTS)
  #     # typed: strict
  #     # so rubocop does not complain
  #     def empty_function; end
  #   CONTENTS

  #   write_file('app/services/fish_like/small_ones/seahorse.rb', <<~CONTENTS)
  #     # typed: strict
  #     # so rubocop does not complain
  #     def empty_function; end
  #   CONTENTS

  #   write_file('app/services/fish_like/big_ones/whale.rb', <<~CONTENTS)
  #     # typed: strict
      
  #   CONTENTS

  #   write_file('app/services/dog_like/golden_retriever.rb', <<~CONTENTS)
  #     # typed: strict
  #     require 'app/services/horse_like/zebra'
  #   CONTENTS

  #   write_file('config/teams/art/artists.yml', <<~CONTENTS)
  #     mission: Art
  #     name: Artists
  #   CONTENTS

  #   write_file('config/teams/food/chefs.yml', <<~CONTENTS)
  #     mission: Food
  #     name: Chefs
  #     owned_globs:
  #       - app/services/owned_by_chefs_2/**/**
  #   CONTENTS

  #   write_file('package.yml', <<~CONTENTS)
  #     enforce_dependencies: true
  #     enforce_privacy: true
  #   CONTENTS

  #   write_file('spec/lib/tasks/my_task_spec.rb', <<~CONTENTS)
  #     # left empty intentionally
  #   CONTENTS

  #   write_file('spec/services/horse_like/donkey_spec.rb', <<~CONTENTS)
  #     # typed: true
  #     # so rubocop does not complain
  #     def empty_function; end
  #   CONTENTS

  #   write_file('spec/services/fish_like/big_ones/whale_spec.rb', <<~CONTENTS)
  #     # typed: strict
  #     # so rubocop does not complain
  #     def empty_function; end
  #   CONTENTS

  #   write_file('spec/services/dog_like/golden_retriever_spec.rb', <<~CONTENTS)
  #     # typed: strict
  #     'app/services/horse_like/zebra'
  #   CONTENTS

  #   write_file('packs/organisms/app/services/bird_like/swan.rb', <<~CONTENTS)
  #     # typed: strict
  #     # so rubocop does not complain
  #     def empty_function; end
  #   CONTENTS

  #   write_file('packs/organisms/app/services/bird_like/eagle.rb', <<~CONTENTS)
  #     # typed: strict
  #     # so rubocop does not complain
  #     def empty_function; end
  #   CONTENTS

  #   write_file('packs/organisms/app/services/bug_like/fly.rb', <<~CONTENTS)
  #     # typed: strict
  #     # so rubocop does not complain
  #     def empty_function; end
  #   CONTENTS

  #   write_file('packs/organisms/spec/lib/tasks/my_organism_task_spec.rb', <<~CONTENTS)
  #     # left empty intentionally
  #   CONTENTS

  #   write_file('packs/organisms/spec/services/bird_like/eagle_spec.rb', <<~CONTENTS)
  #     # typed: strict
  #     # so rubocop does not complain
  #     def empty_function; end
  #   CONTENTS

  #   write_file('packs/organisms/spec/services/bug_like/fly_spec.rb', <<~CONTENTS)
  #     # typed: strict
  #     # so rubocop does not complain
  #     def empty_function; end
  #   CONTENTS

  #   write_file('packs/organisms/lib/tasks/my_organism_task.rake', <<~CONTENTS)
  #     # left empty intentionally
  #   CONTENTS

  #   write_file('lib/tasks/my_task.rake', <<~CONTENTS)
  #     # left empty intentionally
  #   CONTENTS

  #   write_file('config/code_ownership.yml', <<~CONTENTS)
  #     # This is an application-specific file that is used to test post-processing abilities
  #     owned_globs:
  #       - '{app,components,config,frontend,lib,packs,spec}/**/*.{rb,rake,js,jsx,ts,tsx}'
  #     unowned_globs:
  #       - app/services/horse_like/donkey.rb
  #       - app/services/fish_like/small_ones/goldfish.rb
  #       - app/services/fish_like/big_ones/whale.rb
  #       - app/services/dog_like/golden_retriever.rb
  #       - packs/organisms/app/services/bird_like/eagle.rb
  #       - packs/organisms/app/services/bird_like/swan.rb
  #       - packs/organisms/app/services/bug_like/fly.rb
  #   CONTENTS

  #   write_file('packs/organisms/package.yml', <<~CONTENTS)
  #     enforce_privacy: true
  #     enforce_dependencies: true
  #     metadata:
  #       protections:
  #         prevent_this_package_from_violating_its_stated_dependencies: fail_on_new
  #         prevent_other_packages_from_using_this_packages_internals: fail_on_new
  #         prevent_this_package_from_exposing_an_untyped_api: fail_on_new
  #         prevent_this_package_from_creating_other_namespaces: fail_on_new
  #   CONTENTS

  #   write_file('gems/my_gem/app/services/my_gem_service.rb', <<~CONTENTS)
  #     # typed: strict
  #     # so rubocop does not complain
  #     def empty_function; end
  #   CONTENTS

  #   write_file('gems/my_gem/app/services/my_gem_service.rb', <<~CONTENTS)
  #     # typed: strict
  #     # so rubocop does not complain
  #     def empty_function; end
  #   CONTENTS

  #   write_file('gems/my_gem/package.yml', <<~CONTENTS)
  #     enforce_privacy: true
  #     enforce_dependencies: true
  #     metadata:
  #       protections:
  #         prevent_this_package_from_violating_its_stated_dependencies: fail_on_new
  #         prevent_other_packages_from_using_this_packages_internals: fail_on_new
  #         prevent_this_package_from_exposing_an_untyped_api: fail_on_new
  #         prevent_this_package_from_creating_other_namespaces: fail_on_new
  #   CONTENTS

  #   write_file('packs/organisms/birds/package.yml', <<~CONTENTS)
  #     enforce_privacy: true
  #     enforce_dependencies: true
  #     metadata:
  #       protections:
  #         prevent_this_package_from_violating_its_stated_dependencies: fail_on_new
  #         prevent_other_packages_from_using_this_packages_internals: fail_on_new
  #         prevent_this_package_from_exposing_an_untyped_api: fail_on_new
  #         prevent_this_package_from_creating_other_namespaces: fail_on_new
  #   CONTENTS

  #   write_file('packs/organisms/birds/app/services/emu.rb', <<~CONTENTS)
  #   CONTENTS
  #   write_file('packs/organisms/birds/spec/services/emu_spec.rb', <<~CONTENTS)
  #     # typed: true
  #     # so rubocop does not complain
  #     def empty_function; end
  #   CONTENTS
  # end

  let(:app_with_nothing_in_public_dir) do
    write_file('packs/organisms/app/services/swan.rb', <<~CONTENTS)
      # typed: strict
      # so rubocop does not complain
      def empty_function; end
    CONTENTS

    write_file('packs/organisms/app/services/goose.rb', <<~CONTENTS)
    CONTENTS

    write_file('packs/organisms/package.yml', <<~CONTENTS)
      enforce_privacy: true
      enforce_dependencies: true
      metadata:
        protections:
          prevent_this_package_from_violating_its_stated_dependencies: fail_on_new
          prevent_other_packages_from_using_this_packages_internals: fail_on_new
          prevent_this_package_from_exposing_an_untyped_api: fail_on_new
          prevent_this_package_from_creating_other_namespaces: fail_on_new
    CONTENTS

    write_file('.rubocop_todo.yml', <<~CONTENTS)
      # This is an application-specific file that is used to test post-processing abilities
      ---
      Layout/BeginEndAlignment:
        Exclude:
        - packs/organisms/app/services/swan.rb
    CONTENTS
  end

  let(:app_with_file_in_public_dir) do
    write_file('packs/organisms/app/public/swan.rb', <<~CONTENTS)
      # typed: strict
      # so rubocop does not complain
      def empty_function; end
    CONTENTS

    write_file('packs/organisms/app/services/other_bird.rb', <<~CONTENTS)
      # typed: strict
      # so rubocop does not complain
      def empty_function; end
    CONTENTS

    write_file('packs/organisms/package.yml', <<~CONTENTS)
      enforce_privacy: true
      enforce_dependencies: true
      metadata:
        protections:
          prevent_this_package_from_violating_its_stated_dependencies: fail_on_new
          prevent_other_packages_from_using_this_packages_internals: fail_on_new
          prevent_this_package_from_exposing_an_untyped_api: fail_on_new
          prevent_this_package_from_creating_other_namespaces: fail_on_new    
    CONTENTS
  end

  let(:app_with_files_and_directories_with_same_names) do
    write_file('package.yml', <<~CONTENTS)
      enforce_privacy: true
      enforce_dependencies: true
      metadata:
        protections:
          prevent_this_package_from_violating_its_stated_dependencies: fail_on_new
          prevent_other_packages_from_using_this_packages_internals: fail_on_new
          prevent_this_package_from_exposing_an_untyped_api: fail_on_new
          prevent_this_package_from_creating_other_namespaces: fail_on_new
    CONTENTS

    write_file('app/services/salads/types/cobb.rb', <<~CONTENTS)
      # typed: strict
      # so rubocop does not complain
      def empty_function; end
    CONTENTS

    write_file('spec/services/salads/types/cobb_spec.rb', <<~CONTENTS)
      # typed: strict
      # so rubocop does not complain
      def empty_function; end
    CONTENTS

    write_file('packs/food/app/public/tomato.rb', <<~CONTENTS)
      # typed: strict
      # so rubocop does not complain
      def empty_function; end
    CONTENTS

    write_file('packs/food/app/public/salad.rb', <<~CONTENTS)
      # typed: strict
      # so rubocop does not complain
      def empty_function; end
      
    CONTENTS

    write_file('packs/food/app/workers/tomato.rb', <<~CONTENTS)
      # typed: strict
      # so rubocop does not complain
      def empty_function; end
    CONTENTS

    write_file('packs/food/app/services/salads/dressing.rb', <<~CONTENTS)
      # typed: strict
      # so rubocop does not complain
      def empty_function; end
    CONTENTS

    write_file('packs/food/app/services/salad.rb', <<~CONTENTS)
      # typed: strict
      # so rubocop does not complain
      def empty_function; end
    CONTENTS

    write_file('packs/food/package.yml', <<~CONTENTS)
      enforce_privacy: true
      enforce_dependencies: true
      metadata:
        protections:
          prevent_this_package_from_violating_its_stated_dependencies: fail_on_new
          prevent_other_packages_from_using_this_packages_internals: fail_on_new
          prevent_this_package_from_exposing_an_untyped_api: fail_on_new
          prevent_this_package_from_creating_other_namespaces: fail_on_new
    CONTENTS

    write_file('packs/food/spec/public/tomato_spec.rb', <<~CONTENTS)
      # typed: strict
      # so rubocop does not complain
      def empty_function; end
    CONTENTS

    write_file('packs/food/spec/services/salads/dressing_spec.rb', <<~CONTENTS)
      # typed: strict
      # so rubocop does not complain
      def empty_function; end
    CONTENTS

    write_file('packs/food/spec/services/salad_spec.rb', <<~CONTENTS)
      # typed: strict
      # so rubocop does not complain
      def empty_function; end
    CONTENTS

    write_file('packs/organisms/app/public/tomato.rb', <<~CONTENTS)
      # typed: strict
      # so rubocop does not complain
      def empty_function; end
    CONTENTS

    write_file('packs/organisms/app/services/vulture.rb', <<~CONTENTS)
      # typed: strict
      # so rubocop does not complain
      def empty_function; end
    CONTENTS

    write_file('packs/organisms/app/services/other_bird.rb', <<~CONTENTS)
      # typed: strict
      # so rubocop does not complain
      def empty_function; end
    CONTENTS

    write_file('packs/organisms/app/services/eagle.rb', <<~CONTENTS)
      # typed: strict
      # so rubocop does not complain
      def empty_function; end
    CONTENTS

    write_file('packs/organisms/package.yml', <<~CONTENTS)
      enforce_privacy: true
      enforce_dependencies: true
      metadata:
        protections:
          prevent_this_package_from_violating_its_stated_dependencies: fail_on_new
          prevent_other_packages_from_using_this_packages_internals: fail_on_new
          prevent_this_package_from_exposing_an_untyped_api: fail_on_new
          prevent_this_package_from_creating_other_namespaces: fail_on_new
    CONTENTS
  end

  let(:app_with_no_public_dir) do
    write_file('packs/organisms/app/services/swan.rb', <<~CONTENTS)
      # typed: strict
      # so rubocop does not complain
      def empty_function; end
    CONTENTS

    write_file('packs/organisms/package.yml', <<~CONTENTS)
      enforce_privacy: true
      enforce_dependencies: true
      metadata:
        protections:
          prevent_this_package_from_violating_its_stated_dependencies: fail_on_new
          prevent_other_packages_from_using_this_packages_internals: fail_on_new
          prevent_this_package_from_exposing_an_untyped_api: fail_on_new
          prevent_this_package_from_creating_other_namespaces: fail_on_new
    CONTENTS
  end

  let(:app_with_lots_of_violations) do
    write_file('deprecated_references.yml', <<~CONTENTS)
      # This file contains a list of dependencies that are not part of the long term plan for ..
      # We should generally work to reduce this list, but not at the expense of actually getting work done.
      #
      # You can regenerate this file using the following command:
      #
      # bundle exec packwerk update-deprecations .
      ---
      "packs/food":
        "Salad":
          violations:
          - privacy
          files:
          - random_monolith_file.rb
    CONTENTS

    write_file('package.yml', <<~CONTENTS)
      enforce_privacy: true
      enforce_dependencies: true
      metadata:
        protections:
          prevent_this_package_from_violating_its_stated_dependencies: fail_on_new
          prevent_other_packages_from_using_this_packages_internals: fail_on_new
          prevent_this_package_from_exposing_an_untyped_api: fail_on_new
          prevent_this_package_from_creating_other_namespaces: fail_on_new
    CONTENTS

    write_file('packs/food/deprecated_references.yml', <<~CONTENTS)
      # This file contains a list of dependencies that are not part of the long term plan for ..
      # We should generally work to reduce this list, but not at the expense of actually getting work done.
      #
      # You can regenerate this file using the following command:
      #
      # bundle exec packwerk update-deprecations .
      ---
      ".":
        "RandomMonolithFile":
          violations:
          - privacy
          - dependency
          files:
          - packs/organisms/app/public/swan.rb
          - packs/organisms/app/services/other_bird.rb
      "packs/organisms":
        "OtherBird":
          violations:
          - dependency
          - privacy
          files:
          - packs/food/app/public/burger.rb
        "Eagle":
          violations:
          - dependency
          - privacy
          files:
          - packs/food/app/public/burger.rb
        "Vulture":
          violations:
          - dependency
          - privacy
          files:
          - packs/food/app/public/burger.rb
          - packs/food/app/services/salad.rb
    CONTENTS

    write_file('packs/food/app/public/burger.rb', <<~CONTENTS)
      # typed: strict
      # so rubocop does not complain
      def empty_function; end
    CONTENTS

    write_file('packs/food/app/services/salad.rb', <<~CONTENTS)
      # typed: strict
      # so rubocop does not complain
      def empty_function; end
    CONTENTS

    write_file('packs/food/package.yml', <<~CONTENTS)
      enforce_privacy: true
      enforce_dependencies: true
      metadata:
        protections:
          prevent_this_package_from_violating_its_stated_dependencies: fail_on_new
          prevent_other_packages_from_using_this_packages_internals: fail_on_new
          prevent_this_package_from_exposing_an_untyped_api: fail_on_new
          prevent_this_package_from_creating_other_namespaces: fail_on_new
    CONTENTS

    write_file('packs/organisms/deprecated_references.yml', <<~CONTENTS)
      # This file contains a list of dependencies that are not part of the long term plan for ..
      # We should generally work to reduce this list, but not at the expense of actually getting work done.
      #
      # You can regenerate this file using the following command:
      #
      # bundle exec packwerk update-deprecations .
      ---
      ".":
        "RandomMonolithFile":
          violations:
          - privacy
          - dependency
          files:
          - packs/organisms/app/public/swan.rb
          - packs/organisms/app/services/other_bird.rb
      "packs/food":
        "Burger":
          violations:
          - dependency
          files:
          - packs/organisms/app/public/swan.rb
          - packs/organisms/app/services/other_bird.rb
        "Salad":
          violations:
          - privacy
          - dependency
          files:
          - packs/organisms/app/public/swan.rb
          - packs/organisms/app/services/other_bird.rb
    CONTENTS

    write_file('packs/organisms/app/public/swan.rb', <<~CONTENTS)
      # typed: strict
      # so rubocop does not complain
      def empty_function; end
    CONTENTS

    write_file('packs/organisms/app/services/vulture.rb', <<~CONTENTS)
      # typed: strict
      # so rubocop does not complain
      def empty_function; end
    CONTENTS

    write_file('packs/organisms/app/services/other_bird.rb', <<~CONTENTS)
      # typed: strict
      # so rubocop does not complain
      def empty_function; end

    write_file('packs/organisms/app/services/eagle.rb', <<~CONTENTS)
      # typed: strict
      # so rubocop does not complain
      def empty_function; end
    CONTENTS

    write_file('packs/organisms/package.yml', <<~CONTENTS)
      enforce_privacy: true
      enforce_dependencies: true
      metadata:
        protections:
          prevent_this_package_from_violating_its_stated_dependencies: fail_on_new
          prevent_other_packages_from_using_this_packages_internals: fail_on_new
          prevent_this_package_from_exposing_an_untyped_api: fail_on_new
          prevent_this_package_from_creating_other_namespaces: fail_on_new
    CONTENTS

    write_file('random_monolith_file.rb', <<~CONTENTS)
      # typed: strict
      # so rubocop does not complain
      def empty_function; end
    CONTENTS
  end
end
