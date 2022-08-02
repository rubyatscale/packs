# typed: false
RSpec.describe UsePackwerk do
  def get_packages
    ParsePackwerk.all
  end

  def expect_files_to_exist(files)
    files.each do |file|
      expect(File.file?(file)).to (eq true), "Test failed: expected #{file} to now exist, but it does not"
    end
  end

  def expect_files_to_not_exist(files)
    files.each do |file|
      expect(File.file?(file)).to (eq false), "Test failed: expected #{file} to no longer exist, since it should have been moved"
    end
  end

  let(:packages) { get_packages }

  let(:only_nonroot_package) do
    non_root_packages = packages.select{ |p| p.name != ParsePackwerk::ROOT_PACKAGE_NAME }
    expect(non_root_packages.count).to eq 1
    non_root_packages.first
  end


  def bust_cache_and_configure_code_ownership!
    CodeOwnership.bust_caches!
  end

  before do
    CodeTeams.bust_caches!
    UsePackwerk.configure do |config|
      config.enforce_dependencies = true
    end
    bust_cache_and_configure_code_ownership!
  end

  describe '.create_pack!' do
    let(:pack_name) { 'packs/my_sick_new_pack' }

    let(:create_pack) do
      UsePackwerk.create_pack!(pack_name: pack_name)
    end

    # Right now, `UsePackwerk` only supports `packs`, `gems`, or `components` as the home for packwerk packages
    context 'pack name does not include `packs` prefix' do
      let(:pack_name) { 'my_sick_new_pack' }

      it 'errors' do
        expect { create_pack }.to raise_error("UsePackwerk only supports packages in the the following directories: [\"gems\", \"components\", \"packs\"]. Please make sure to pass in the name of the pack including the full directory path, e.g. `packs/my_pack`.")
      end
    end

    it 'creates a package.yml correctly' do
      create_pack

      expect(only_nonroot_package.name).to eq('packs/my_sick_new_pack')
      expect(only_nonroot_package.enforce_privacy).to eq(true)
      expect(only_nonroot_package.enforce_dependencies).to eq(true)
      expect(only_nonroot_package.dependencies).to eq([])
      expect(only_nonroot_package.metadata).to eq({ 'owner' => 'MyTeam', 'protections' => {"prevent_other_packages_from_using_this_packages_internals"=>"fail_on_new", "prevent_this_package_from_creating_other_namespaces"=>"fail_on_new", "prevent_this_package_from_exposing_an_untyped_api"=>"fail_on_new", "prevent_this_package_from_violating_its_stated_dependencies"=>"fail_on_new"} })

      expected = <<~EXPECTED
        enforce_dependencies: true
        enforce_privacy: true
        metadata:
          owner: MyTeam # specify your team here, or delete this key if this package is not owned by one team
          protections:
            prevent_this_package_from_violating_its_stated_dependencies: fail_on_new
            prevent_other_packages_from_using_this_packages_internals: fail_on_new
            prevent_this_package_from_exposing_an_untyped_api: fail_on_new
            prevent_this_package_from_creating_other_namespaces: fail_on_new
      EXPECTED

      expect(only_nonroot_package.yml.read).to eq expected
    end

    context 'use packwerk is configured to not enforce dependencies by default' do
      before { UsePackwerk.configure { |config| config.enforce_dependencies = false } }

      it 'creates a package.yml correctly' do
        create_pack

        expected_package = ParsePackwerk::Package.new(
          name: 'packs/my_sick_new_pack',
          enforce_privacy: true,
          enforce_dependencies: false,
          dependencies: [],
          metadata: { 'owner' => 'MyTeam', 'protections' => {"prevent_other_packages_from_using_this_packages_internals"=>"fail_on_new", "prevent_this_package_from_creating_other_namespaces"=>"fail_on_new", "prevent_this_package_from_exposing_an_untyped_api"=>"fail_on_new", "prevent_this_package_from_violating_its_stated_dependencies"=>"fail_on_new"} },
        )

        expect(only_nonroot_package.name).to eq(expected_package.name)
        expect(only_nonroot_package.enforce_privacy).to eq(expected_package.enforce_privacy)
        expect(only_nonroot_package.enforce_dependencies).to eq(expected_package.enforce_dependencies)
        expect(only_nonroot_package.dependencies).to eq(expected_package.dependencies)
        expect(only_nonroot_package.metadata).to eq(expected_package.metadata)
      end
    end

    context 'pack already exists and has content' do      
      before do
        write_file('packs/food/package.yml', <<~CONTENTS)
          enforce_privacy: true
          enforce_dependencies: true
          dependencies:
            - packs/some_other_pack
          metadata:
            protections:
              prevent_this_package_from_exposing_an_untyped_api: fail_never
              prevent_this_package_from_violating_its_stated_dependencies: fail_on_new
              prevent_other_packages_from_using_this_packages_internals: fail_on_new
              prevent_this_package_from_creating_other_namespaces: fail_on_new
        CONTENTS
      end


      it 'is idempotent' do
        expect(packages.count).to eq 1
        existing_package = packages.first
        expect(existing_package.dependencies).to eq(['packs/some_other_pack'])
        expect(existing_package.metadata).to eq({
          'protections' => {
            'prevent_this_package_from_exposing_an_untyped_api' => 'fail_never',
            'prevent_this_package_from_violating_its_stated_dependencies' => 'fail_on_new',
            'prevent_other_packages_from_using_this_packages_internals' => 'fail_on_new',
            'prevent_this_package_from_creating_other_namespaces' => 'fail_on_new',
          }
        })
        UsePackwerk.create_pack!(pack_name: 'packs/food/')
        new_packages = get_packages
        expect(new_packages.count).to eq 1
        new_package = new_packages.first

        expect(new_package.name).to eq(existing_package.name)
        expect(new_package.enforce_privacy).to eq(existing_package.enforce_privacy)
        expect(new_package.enforce_dependencies).to eq(existing_package.enforce_dependencies)
        expect(new_package.dependencies).to eq(existing_package.dependencies)
        expect(new_package.metadata).to eq(existing_package.metadata)
      end
    end

    it 'automatically adds the owner metadata key' do
      create_pack

      expect(only_nonroot_package.metadata['owner']).to eq 'MyTeam'
      package_yml_contents = only_nonroot_package.yml.read
      expect(package_yml_contents).to include ('owner: MyTeam # specify your team here, or delete this key if this package is not owned by one team')
    end

    context 'pack is in gems' do
      let(:pack_name) { 'gems/my_sick_new_pack' }

      it 'creates the pack' do
        create_pack
        expect(only_nonroot_package.name).to eq('gems/my_sick_new_pack')
      end
    end
  end

  describe '.move_to_pack!' do
    let(:pack_name) { 'packs/animals' }

    let(:create_pack) do
      UsePackwerk.create_pack!(
        pack_name: pack_name,
      )
    end

    before do
      allow(CodeOwnership).to receive(:for_package).and_return(nil)
    end

    let(:move_to_pack) do
      UsePackwerk.move_to_pack!(
        pack_name: pack_name,
        paths_relative_to_root: [
          # Files in monolith
          'app/services/horse_like',
          'app/services/fish_like/small_ones',
          'app/services/fish_like/big_ones',
          'app/services/dog_like/golden_retriever.rb',
          # Files in packs
          'packs/organisms/app/services/bird_like/eagle.rb',
          'packs/organisms/app/services/bird_like/swan.rb',
          'packs/organisms/app/services/bug_like/fly.rb',
        ],
        per_file_processors: [UsePackwerk::RubocopPostProcessor.new, UsePackwerk::CodeOwnershipPostProcessor.new],
      )
    end

    context 'pack not yet created' do
      it 'errors' do
        expect { move_to_pack }.to raise_error("Can not find package with name packs/animals. Make sure the argument is of the form `packs/my_pack/`")
      end
    end

    it 'can move files from a monolith into a package' do
      complex_app

      expected_files_before = [
        # Files in monolith
        'app/services/horse_like/zebra.rb',
        'app/services/horse_like/donkey.rb',
        'app/services/horse_like/horse.rb',
        'app/services/horse_like/zebra.rb',
        'app/services/fish_like/small_ones/goldfish.rb',
        'app/services/fish_like/small_ones/seahorse.rb',
        'app/services/fish_like/big_ones/whale.rb',
        # Specs in monolith
        'spec/services/dog_like/golden_retriever_spec.rb',
        'spec/services/fish_like/big_ones/whale_spec.rb',
        'spec/services/horse_like/donkey_spec.rb',
      ]

      expect_files_to_exist expected_files_before

      create_pack
      move_to_pack

      expect_files_to_not_exist expected_files_before

      expected_files_after = [
        'packs/animals/app/services/horse_like/zebra.rb',
        'packs/animals/app/services/horse_like/donkey.rb',
        'packs/animals/app/services/horse_like/horse.rb',
        'packs/animals/app/services/horse_like/zebra.rb',
        'packs/animals/app/services/fish_like/small_ones/goldfish.rb',
        'packs/animals/app/services/fish_like/small_ones/seahorse.rb',
        'packs/animals/app/services/fish_like/big_ones/whale.rb',
        'packs/animals/spec/services/dog_like/golden_retriever_spec.rb',
        'packs/animals/spec/services/fish_like/big_ones/whale_spec.rb',
        'packs/animals/spec/services/horse_like/donkey_spec.rb',
      ]

      expect_files_to_exist expected_files_after
    end

    it 'can move files from one pack to another pack' do
      complex_app

      expected_files_before = [
        # Files in packs
        'packs/organisms/app/services/bird_like/eagle.rb',
        'packs/organisms/app/services/bird_like/swan.rb',
        'packs/organisms/app/services/bug_like/fly.rb',
        # Specs in packs
        'packs/organisms/spec/services/bird_like/eagle_spec.rb',
        'packs/organisms/spec/services/bug_like/fly_spec.rb',
      ]

      expect_files_to_exist expected_files_before

      create_pack
      move_to_pack

      expect_files_to_not_exist expected_files_before

      expected_files_after = [
        'packs/animals/app/services/bird_like/eagle.rb',
        'packs/animals/app/services/bird_like/swan.rb',
        'packs/animals/app/services/bug_like/fly.rb',
        'packs/animals/spec/services/bird_like/eagle_spec.rb',
        'packs/animals/spec/services/bug_like/fly_spec.rb',
      ]

      expect_files_to_exist expected_files_after
    end

    context 'directory moves have trailing slashes' do
      let(:move_to_pack) do
        UsePackwerk.move_to_pack!(
          pack_name: pack_name,
          paths_relative_to_root: [
            # Files in monolith
            'app/services/horse_like/',
            'app/services/fish_like/small_ones/',
            'app/services/fish_like/big_ones/',
            'app/services/dog_like/golden_retriever.rb',
            # Files in packs
            'packs/organisms/app/services/bird_like/eagle.rb',
            'packs/organisms/app/services/bird_like/swan.rb',
            'packs/organisms/app/services/bug_like/fly.rb',
          ],
          per_file_processors: [UsePackwerk::RubocopPostProcessor.new, UsePackwerk::CodeOwnershipPostProcessor.new],
        )
      end

      it 'can move files from one pack to another pack' do
        complex_app

        expected_files_before = [
          # Files in packs
          'packs/organisms/app/services/bird_like/eagle.rb',
          'packs/organisms/app/services/bird_like/swan.rb',
          'packs/organisms/app/services/bug_like/fly.rb',
          # Specs in packs
          'packs/organisms/spec/services/bird_like/eagle_spec.rb',
          'packs/organisms/spec/services/bug_like/fly_spec.rb',
        ]

        expect_files_to_exist expected_files_before

        create_pack
        move_to_pack

        expect_files_to_not_exist expected_files_before

        expected_files_after = [
          'packs/animals/app/services/bird_like/eagle.rb',
          'packs/animals/app/services/bird_like/swan.rb',
          'packs/animals/app/services/bug_like/fly.rb',
          'packs/animals/spec/services/bird_like/eagle_spec.rb',
          'packs/animals/spec/services/bug_like/fly_spec.rb',
        ]

        expect_files_to_exist expected_files_after
      end
    end

    describe 'RubocopPostProcessor' do
      it 'modifies an application-specific file, .rubocop_todo.yml, correctly' do
        complex_app

        before_rubocop_todo = File.read(Pathname.new('.rubocop_todo.yml'))

        expect(before_rubocop_todo).to include '- app/services/horse_like/zebra.rb'
        expect(before_rubocop_todo).to include '- app/services/fish_like/small_ones/goldfish.rb'
        expect(before_rubocop_todo).to include '- app/services/dog_like/golden_retriever.rb'
        expect(before_rubocop_todo).to include '- app/services/fish_like/small_ones/goldfish.rb'
        expect(before_rubocop_todo).to include '- app/services/fish_like/big_ones/whale.rb'

        create_pack
        move_to_pack

        after_rubocop_todo = File.read(Pathname.new('.rubocop_todo.yml'))

        expect(after_rubocop_todo).to_not include '- app/services/horse_like/zebra.rb'
        expect(after_rubocop_todo).to_not include '- app/services/fish_like/small_ones/goldfish.rb'
        expect(after_rubocop_todo).to_not include '- app/services/dog_like/golden_retriever.rb'
        expect(after_rubocop_todo).to_not include '- app/services/fish_like/small_ones/goldfish.rb'
        expect(after_rubocop_todo).to_not include '- app/services/fish_like/big_ones/whale.rb'

        expect(after_rubocop_todo).to include '- packs/animals/app/services/horse_like/zebra.rb'
        expect(after_rubocop_todo).to include '- packs/animals/app/services/fish_like/small_ones/goldfish.rb'
        expect(after_rubocop_todo).to include '- packs/animals/app/services/dog_like/golden_retriever.rb'
        expect(after_rubocop_todo).to include '- packs/animals/app/services/fish_like/small_ones/goldfish.rb'
        expect(after_rubocop_todo).to include '- packs/animals/app/services/fish_like/big_ones/whale.rb'
      end

      context 'origin pack has a pack-level .rubocop_todo.yml, destination pack does not' do
        before do
          write_file('packs/organisms/.rubocop_todo.yml', <<~CONTENTS)
            ---
            Some/Cop/Does/Not/Matter:
              Exclude:
              - packs/organisms/app/services/horse_like/zebra.rb
              - packs/organisms/app/services/fish_like/small_ones/goldfish.rb'
              - packs/organisms/app/services/fish_like/small_ones/tiny_fish.rb'
            Layout/BeginEndAlignment:
              Exclude:
              - packs/organisms/app/services/horse_like/zebra.rb
              - packs/organisms/app/services/fish_like/small_ones/goldfish.rb'
          CONTENTS
        end

        it 'creates a .rubocop_todo.yml in the destination pack' do
          complex_app

          before_origin_pack_rubocop_todo = Pathname.new('packs/organisms/.rubocop_todo.yml')
          before_destination_pack_rubocop_todo = Pathname.new('packs/animals/.rubocop_todo.yml')

          expect(YAML.load(before_origin_pack_rubocop_todo.read)).to eq({
            "Some/Cop/Does/Not/Matter"=>
              {"Exclude"=>
                ["packs/organisms/app/services/bug_like/fly.rb",
                "packs/organisms/app/services/bird_like/eagle.rb",
                "packs/organisms/app/services/fish_like/small_ones/tiny_fish.rb"]},
            "Layout/BeginEndAlignment"=>
              {"Exclude"=>
                ["packs/organisms/app/services/bug_like/fly.rb", "packs/organisms/app/services/bird_like/eagle.rb"]}
          })
          expect(before_destination_pack_rubocop_todo).to_not exist

          create_pack
          move_to_pack

          after_origin_pack_rubocop_todo = Pathname.new('packs/organisms/.rubocop_todo.yml')
          after_destination_pack_rubocop_todo = Pathname.new('packs/animals/.rubocop_todo.yml')

          expect(YAML.load(after_origin_pack_rubocop_todo.read)).to eq({
            "Some/Cop/Does/Not/Matter"=>
              {"Exclude"=>
                ["packs/organisms/app/services/fish_like/small_ones/tiny_fish.rb"]}
          })

          expect(YAML.load(after_destination_pack_rubocop_todo.read)).to eq({
            "Some/Cop/Does/Not/Matter"=>
              {"Exclude"=>
                ["packs/animals/app/services/bug_like/fly.rb", "packs/animals/app/services/bird_like/eagle.rb"]},
            "Layout/BeginEndAlignment"=>
              {"Exclude"=>
                ["packs/animals/app/services/bug_like/fly.rb", "packs/animals/app/services/bird_like/eagle.rb"]}
          })

        end
      end

      context 'origin and destination pack both have .rubocop_todo.yml' do
        before do
          write_file('packs/organisms/.rubocop_todo.yml', <<~CONTENTS)
            ---
            Some/Cop/Does/Not/Matter:
              Exclude:
              - packs/organisms/app/services/horse_like/zebra.rb
              - packs/organisms/app/services/fish_like/small_ones/goldfish.rb'
              - packs/organisms/app/services/fish_like/small_ones/tiny_fish.rb'
            Layout/BeginEndAlignment:
              Exclude:
              - packs/organisms/app/services/horse_like/zebra.rb
              - packs/organisms/app/services/fish_like/small_ones/goldfish.rb'
          CONTENTS

          write_file('packs/organisms/.rubocop_todo.yml', <<~CONTENTS)
            ---
            Some/Cop/Does/Not/Matter:
              Exclude:
              - packs/animals/app/services/some_other_directory/some_file.rb
            Some/Other/Cop/Does/Not/Matter:
              Exclude:
              - packs/animals/app/services/some_other_directory/some_file.rb
            Layout/BeginEndAlignment:
              Exclude:
              - packs/animals/app/services/some_other_directory/some_file.rb
          CONTENTS
        end

        it 'creates a .rubocop_todo.yml in the destination pack' do
          complex_app

          before_origin_pack_rubocop_todo = Pathname.new('packs/organisms/.rubocop_todo.yml')
          before_destination_pack_rubocop_todo = Pathname.new('packs/animals/.rubocop_todo.yml')

          expect(YAML.load(before_origin_pack_rubocop_todo.read)).to eq({}) # should contain the above
          expect(YAML.load(before_destination_pack_rubocop_todo.read)).to eq({}) # should contain the above

          create_pack
          move_to_pack

          after_origin_pack_rubocop_todo = Pathname.new('packs/organisms/.rubocop_todo.yml')
          after_destination_pack_rubocop_todo = Pathname.new('packs/animals/.rubocop_todo.yml')

          expect(YAML.load(after_origin_pack_rubocop_todo.read)).to eq({}) # should be empty
          expect(YAML.load(after_destination_pack_rubocop_todo.read)).to eq({}) # should contain the above with changed names

        end
      end
    end

    it 'modifies an application-specific file, config/code_ownership.yml, correctly' do
      complex_app

      before_codeownership_yml = File.read(Pathname.new('config/code_ownership.yml'))

      expect(before_codeownership_yml).to include "- app/services/horse_like/donkey.rb"
      expect(before_codeownership_yml).to include "- app/services/fish_like/small_ones/goldfish.rb"
      expect(before_codeownership_yml).to include "- app/services/fish_like/big_ones/whale.rb"
      expect(before_codeownership_yml).to include "- app/services/dog_like/golden_retriever.rb"
      expect(before_codeownership_yml).to include "- packs/organisms/app/services/bird_like/eagle.rb"
      expect(before_codeownership_yml).to include "- packs/organisms/app/services/bird_like/swan.rb"
      expect(before_codeownership_yml).to include "- packs/organisms/app/services/bug_like/fly.rb"

      create_pack
      move_to_pack

      after_codeownership_yml = File.read(Pathname.new('config/code_ownership.yml'))

      expect(after_codeownership_yml).to_not include "- app/services/horse_like/donkey.rb"
      expect(after_codeownership_yml).to_not include "- app/services/fish_like/small_ones/goldfish.rb"
      expect(after_codeownership_yml).to_not include "- app/services/fish_like/big_ones/whale.rb"
      expect(after_codeownership_yml).to_not include "- app/services/dog_like/golden_retriever.rb"
      expect(after_codeownership_yml).to_not include "- packs/organisms/app/services/bird_like/eagle.rb"
      expect(after_codeownership_yml).to_not include "- packs/organisms/app/services/bird_like/swan.rb"
      expect(after_codeownership_yml).to_not include "- packs/organisms/app/services/bug_like/fly.rb"

      expect(after_codeownership_yml).to include "- packs/animals/app/services/horse_like/donkey.rb"
      expect(after_codeownership_yml).to include "- packs/animals/app/services/fish_like/small_ones/goldfish.rb"
      expect(after_codeownership_yml).to include "- packs/animals/app/services/fish_like/big_ones/whale.rb"
      expect(after_codeownership_yml).to include "- packs/animals/app/services/dog_like/golden_retriever.rb"
      expect(after_codeownership_yml).to include "- packs/animals/app/services/bird_like/eagle.rb"
      expect(after_codeownership_yml).to include "- packs/animals/app/services/bird_like/swan.rb"
      expect(after_codeownership_yml).to include "- packs/animals/app/services/bug_like/fly.rb"
    end

    context 'packs have folders of the same name' do
      before { app_with_files_and_directories_with_same_names }

      it 'merges the set of files in common folders' do
        expected_files_before = [
          # Files in food pack
          'packs/food/app/public/tomato.rb',
          'packs/food/app/services/salad.rb',
          'packs/food/app/services/salads/dressing.rb',
          'packs/food/spec/public/tomato_spec.rb',
          'packs/food/spec/services/salad_spec.rb',
          'packs/food/spec/services/salads/dressing_spec.rb',
          # Files in organisms pack
          'packs/organisms/app/public/tomato.rb',
          'packs/organisms/app/services/eagle.rb',
          'packs/organisms/app/services/other_bird.rb',
          'packs/organisms/app/services/vulture.rb',
          # Files in monolith
          'app/services/salads/types/cobb.rb',
          'spec/services/salads/types/cobb_spec.rb',
        ]

        expect_files_to_exist expected_files_before

        UsePackwerk.move_to_pack!(
          pack_name: 'packs/food',
          paths_relative_to_root: [
            'packs/organisms/app/services',
            'app/services'
          ],
        )

        expect_files_to_not_exist([
          'packs/organisms/app/services/eagle.rb',
          'packs/organisms/app/services/other_bird.rb',
          'packs/organisms/app/services/vulture.rb',
          'app/services/salads/types/cobb.rb',
          'spec/services/salads/types/cobb_spec.rb',
        ])

        expected_files_after = [
          'packs/food/app/public/tomato.rb',
          'packs/food/app/services/salad.rb',
          'packs/food/app/services/salads/dressing.rb',
          'packs/food/spec/public/tomato_spec.rb',
          'packs/food/spec/services/salad_spec.rb',
          'packs/food/spec/services/salads/dressing_spec.rb',
          'packs/food/app/services/eagle.rb',
          'packs/food/app/services/other_bird.rb',
          'packs/food/app/services/vulture.rb',
          'packs/food/app/services/salads/types/cobb.rb',
          'packs/food/spec/services/salads/types/cobb_spec.rb',
        ]

        expect_files_to_exist expected_files_after
      end
    end

    context 'packs have files of the same name' do
      before { app_with_files_and_directories_with_same_names }

      it 'leaves the origin and destination in the same place' do
        expected_files_before = [
          # Files in food pack
          'packs/food/app/public/tomato.rb',
          'packs/food/app/services/salad.rb',
          'packs/food/app/services/salads/dressing.rb',
          'packs/food/spec/public/tomato_spec.rb',
          'packs/food/spec/services/salad_spec.rb',
          'packs/food/spec/services/salads/dressing_spec.rb',
          # Files in organisms pack
          'packs/organisms/app/public/tomato.rb',
          'packs/organisms/app/services/eagle.rb',
          'packs/organisms/app/services/other_bird.rb',
          'packs/organisms/app/services/vulture.rb',
          # Files in monolith
          'app/services/salads/types/cobb.rb',
          'spec/services/salads/types/cobb_spec.rb',
        ]

        expect_files_to_exist expected_files_before

        UsePackwerk.move_to_pack!(
          pack_name: 'packs/food',
          paths_relative_to_root: [
            'packs/organisms/app/public',
          ],
        )

        expected_files_after = [
          'packs/food/app/public/tomato.rb',
          'packs/organisms/app/public/tomato.rb',
        ]

        expect_files_to_exist expected_files_after
      end
    end

    describe 'creating a TODO.md inside app/public' do
      let(:expected_todo) do
        <<~TODO
          This directory holds your public API!

          Any classes, constants, or modules that you want other packs to use and you intend to support should go in here.
          Anything that is considered private should go in other folders.

          If another pack uses classes, constants, or modules that are not in your public folder, it will be considered a "privacy violation" by packwerk.
          You can prevent other packs from using private API by using package_protections.

          Want to find how your private API is being used today?
          Try running: `bin/use_packwerk list_top_privacy_violations packs/organisms`

          Want to move something into this folder?
          Try running: `bin/use_packwerk make_public packs/organisms/path/to/file.rb`

          One more thing -- feel free to delete this file and replace it with a README.md describing your package in the main package directory.

          See #{UsePackwerk.config.documentation_link} for more info!
        TODO
      end

      let(:create_pack) do
        UsePackwerk.create_pack!(
          pack_name: 'packs/organisms',
          enforce_privacy: true,
        )
      end

      context 'app has public dir but nothing inside of it' do
        before { app_with_nothing_in_public_dir }

        it 'adds a TODO.md file letting someone know what to do with it' do
          create_pack
          actual_todo = packages.first.directory.join('app/public/TODO.md').read
          expect(actual_todo).to eq expected_todo
        end
      end

      context 'app has no public dir' do
        before { app_with_no_public_dir }

        it 'adds a TODO.md file letting someone know what to do with it' do
          create_pack
          actual_todo = packages.first.directory.join('app/public/TODO.md').read
          expect(actual_todo).to eq expected_todo
        end
      end

      context 'app with one file in public dir' do
        before { app_with_file_in_public_dir }

        it 'adds a TODO.md file letting someone know what to do with it' do
          create_pack
          todo_file = packages.first.directory.join('app/public/TODO.md')
          expect(todo_file.exist?).to eq false
        end
      end
    end

    describe 'setting the README' do
      let(:expected_readme_todo) do
        <<~EXPECTED
          Welcome to `packs/organisms`!

          If you're the author, please consider replacing this file with a README.md, which may contain:
          - What your pack is and does
          - How you expect people to use your pack
          - Example usage of your pack's public API (which lives in `packs/organisms/app/public`)
          - Limitations, risks, and important considerations of usage
          - How to get in touch with eng and other stakeholders for questions or issues pertaining to this pack (note: it is recommended to add ownership in `packs/organisms/package.yml` under the `owner` metadata key)
          - What SLAs/SLOs (service level agreements/objectives), if any, your package provides
          - When in doubt, keep it simple
          - Anything else you may want to include!

          README.md files are under version control and should change as your public API changes. 

          See #{UsePackwerk.config.documentation_link} for more info!
        EXPECTED
      end

      let(:create_pack) do
        UsePackwerk.create_pack!(
          pack_name: 'packs/organisms',
          enforce_privacy: true,
        )
      end

      context 'app has no packs' do
        before do
          write_file('package.yml', <<~CONTENTS)
            enforce_privacy: true
            enforce_dependencies: true
          CONTENTS
        end

        it 'adds a README_TODO.md file as a placeholder' do
          create_pack

          actual_readme_todo = only_nonroot_package.directory.join('README_TODO.md')
          expect(actual_readme_todo.read).to eq expected_readme_todo
        end
      end

      context 'app has one pack without a README' do
        before do
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

        it 'adds a README_TODO.md file as a placeholder' do
          create_pack
          actual_readme_todo = packages.first.directory.join('README_TODO.md')
          expect(actual_readme_todo.read).to eq expected_readme_todo
        end
      end

      context 'app has one pack with an outdated README_TODO.md' do
        before do
          write_file('packs/organisms/README_TODO.md', <<~CONTENTS)
            This is outdated!
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

        it 'adds a README_TODO.md file as a placeholder' do
          actual_readme_todo = packages.first.directory.join('README_TODO.md')
          expect(actual_readme_todo.read).to eq "This is outdated!\n"
          create_pack

          expect(actual_readme_todo.read).to eq expected_readme_todo
        end
      end

      context 'app has one pack with a README.md' do
        before do
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

          write_file('packs/organisms/README.md', <<~CONTENTS)
            This is a readme!
          CONTENTS
        end

        it 'adds a README_TODO.md file as a placeholder' do
          actual_readme_todo = packages.first.directory.join('README_TODO.md')
          create_pack
          expect(actual_readme_todo.exist?).to eq false
        end
      end
    end

    context 'pack is in gems' do
      let(:pack_name) { 'gems/my_sick_new_pack' }

      it 'can move files from a monolith into a package' do
        complex_app

        expected_files_before = [
          # Files in monolith
          'app/services/horse_like/zebra.rb',
          'app/services/horse_like/donkey.rb',
          'app/services/horse_like/horse.rb',
          'app/services/horse_like/zebra.rb',
          'app/services/fish_like/small_ones/goldfish.rb',
          'app/services/fish_like/small_ones/seahorse.rb',
          'app/services/fish_like/big_ones/whale.rb',
          # Specs in monolith
          'spec/services/dog_like/golden_retriever_spec.rb',
          'spec/services/fish_like/big_ones/whale_spec.rb',
          'spec/services/horse_like/donkey_spec.rb',
        ]

        expect_files_to_exist expected_files_before

        create_pack
        move_to_pack
        expect_files_to_not_exist expected_files_before

        expected_files_after = [
          'gems/my_sick_new_pack/app/services/horse_like/zebra.rb',
          'gems/my_sick_new_pack/app/services/horse_like/donkey.rb',
          'gems/my_sick_new_pack/app/services/horse_like/horse.rb',
          'gems/my_sick_new_pack/app/services/horse_like/zebra.rb',
          'gems/my_sick_new_pack/app/services/fish_like/small_ones/goldfish.rb',
          'gems/my_sick_new_pack/app/services/fish_like/small_ones/seahorse.rb',
          'gems/my_sick_new_pack/app/services/fish_like/big_ones/whale.rb',
          'gems/my_sick_new_pack/spec/services/dog_like/golden_retriever_spec.rb',
          'gems/my_sick_new_pack/spec/services/fish_like/big_ones/whale_spec.rb',
          'gems/my_sick_new_pack/spec/services/horse_like/donkey_spec.rb',
        ]

        expect_files_to_exist expected_files_after
      end

      it 'can move files from one pack to another pack' do
        complex_app

        expected_files_before = [
          # Files in packs
          'packs/organisms/app/services/bird_like/eagle.rb',
          'packs/organisms/app/services/bird_like/swan.rb',
          'packs/organisms/app/services/bug_like/fly.rb',
          # Specs in packs
          'packs/organisms/spec/services/bird_like/eagle_spec.rb',
          'packs/organisms/spec/services/bug_like/fly_spec.rb',
        ]

        expect_files_to_exist expected_files_before

        create_pack
        move_to_pack

        expect_files_to_not_exist expected_files_before

        expected_files_after = [
          'gems/my_sick_new_pack/app/services/bird_like/eagle.rb',
          'gems/my_sick_new_pack/app/services/bird_like/swan.rb',
          'gems/my_sick_new_pack/app/services/bug_like/fly.rb',
          'gems/my_sick_new_pack/spec/services/bird_like/eagle_spec.rb',
          'gems/my_sick_new_pack/spec/services/bug_like/fly_spec.rb',
        ]

        expect_files_to_exist expected_files_after
      end

      it 'can move files from one one gem to another' do
        complex_app

        expected_files_before = [ 'gems/my_gem/app/services/my_gem_service.rb' ]

        expect_files_to_exist expected_files_before


        UsePackwerk.create_pack!(pack_name: pack_name)

        UsePackwerk.move_to_pack!(
          pack_name: pack_name,
          paths_relative_to_root: ['gems/my_gem/app/services/my_gem_service.rb'],
        )

        expect_files_to_not_exist expected_files_before

        expected_files_after = [
          'gems/my_sick_new_pack/app/services/my_gem_service.rb',
        ]

        expect_files_to_exist expected_files_after
      end
    end

    context 'in a pack with various ownership' do
      before do
        write_file('app/services/owned_by_chefs_2/sandwich.rb', <<~CONTENTS)
          # typed: false
          
          # content
        CONTENTS

        write_file('app/services/owned_by_chefs/sandwich.rb', <<~CONTENTS)
          # @team Chefs
          
          # content
        CONTENTS

        write_file('app/services/owned_by_artists/paintbrush.rb', <<~CONTENTS)
          # @team Artists
          
          # content
        CONTENTS

        write_file('config/teams/art/artists.yml', <<~CONTENTS)
          name: Artists
        CONTENTS

        write_file('config/teams/food/chefs.yml', <<~CONTENTS)
          name: Chefs
          owned_globs:
            - app/services/owned_by_chefs_2/**
            - spec/services/owned_by_chefs_2/**
        CONTENTS

        write_file('spec/services/owned_by_chefs/sandwich_spec.rb', <<~CONTENTS)
          # @team Chefs
        CONTENTS

        write_file('spec/services/owned_by_artists/paintbrush_spec.rb', <<~CONTENTS)
          # @team Artists
        CONTENTS

        write_file('packs/package.yml', <<~CONTENTS)
          enforce_dependencies: true
          enforce_privacy: true
          metadata:
            owner: Artists
        CONTENTS

        write_file('packs/owned_by_artists/app/public/paint.rb', <<~CONTENTS)
          # typed: strict
          
          # content
        CONTENTS

        write_file('packs/owned_by_artists/spec/public/paint_spec.rb', <<~CONTENTS)
          # typed: strict
        CONTENTS
      end

      let(:create_pack) do
        UsePackwerk.create_pack!(
          pack_name: pack_name,
        )
      end

      let(:move_to_pack) do
        UsePackwerk.move_to_pack!(
          pack_name: pack_name,
          paths_relative_to_root: %w(
            app/services/owned_by_chefs/sandwich.rb
            app/services/owned_by_chefs_2/sandwich.rb
            app/services/owned_by_artists/paintbrush.rb
            packs/owned_by_artists/app/public/paint.rb
          ),
          per_file_processors: [UsePackwerk::RubocopPostProcessor.new, UsePackwerk::CodeOwnershipPostProcessor.new],
        )
      end

      it 'prints out the right ownership' do
        logged_output = ""

        expect(UsePackwerk::Logging).to receive(:print).at_least(:once) do |string|
          logged_output += string
          logged_output += "\n"
        end

        create_pack
        move_to_pack

        expected_logged_output = <<~OUTPUT
        This section contains info about the current ownership distribution of the moved files.
          Artists - 4 files
          Chefs - 3 files
        OUTPUT

        expect(logged_output).to include expected_logged_output
      end
    
      it 'removes file annotations if the destination pack has file annotations' do
        logged_output = ""

        expect(UsePackwerk::Logging).to receive(:print).at_least(:once) do |string|
          logged_output += string
          logged_output += "\n"
        end

        create_pack

        expect(Pathname.new('app/services/owned_by_chefs/sandwich.rb').read).to eq <<~RUBY
          # @team Chefs

          # content
        RUBY
        expect(Pathname.new('app/services/owned_by_chefs_2/sandwich.rb').read).to eq <<~RUBY
          # typed: false

          # content
        RUBY
        expect(Pathname.new('app/services/owned_by_artists/paintbrush.rb').read).to eq <<~RUBY
          # @team Artists

          # content
        RUBY
        expect(Pathname.new('packs/owned_by_artists/app/public/paint.rb').read).to eq <<~RUBY
          # typed: strict

          # content
        RUBY

        # Set the package to be owned by `Artists``
        team = instance_double(CodeTeams::Team)
        package = ParsePackwerk.all.find {|p| p.name == pack_name} 
        allow(CodeOwnership).to receive(:for_package).with(anything).and_return(team)
        bust_cache_and_configure_code_ownership!

        move_to_pack

        expected_logged_output = <<~OUTPUT
        This section contains info about the current ownership distribution of the moved files.
          Artists - 4 files
          Chefs - 3 files
        Since the destination package has package-based ownership, file-annotations were removed from moved files.
        OUTPUT

        expect(logged_output).to include expected_logged_output

        expect(Pathname.new('packs/animals/app/services/owned_by_chefs/sandwich.rb').read).to eq (<<~RUBY)
          # content
        RUBY

        expect(Pathname.new('packs/animals/app/services/owned_by_chefs_2/sandwich.rb').read).to eq <<~RUBY
          # typed: false

          # content
        RUBY
        expect(Pathname.new('packs/animals/app/services/owned_by_artists/paintbrush.rb').read).to eq (<<~RUBY)
          # content
        RUBY
        expect(Pathname.new('packs/animals/app/public/paint.rb').read).to eq <<~RUBY
          # typed: strict

          # content
        RUBY
      end
    end

    context 'files moved are tasks in lib' do
      let(:move_to_pack) do
        UsePackwerk.move_to_pack!(
          pack_name: pack_name,
          paths_relative_to_root: [
            'lib/tasks/my_task.rake',
            'packs/organisms/lib/tasks/my_organism_task.rake',
          ],
        )
      end

      it 'can move files from lib from one pack to another pack' do
        complex_app

        expected_files_before = [
          'lib/tasks/my_task.rake',
          'spec/lib/tasks/my_task_spec.rb',
          'packs/organisms/lib/tasks/my_organism_task.rake',
          'packs/organisms/spec/lib/tasks/my_organism_task_spec.rb',
        ]

        expect_files_to_exist expected_files_before

        create_pack
        move_to_pack

        expect_files_to_not_exist expected_files_before

        expected_files_after = [
          'packs/animals/lib/tasks/my_task.rake',
          'packs/animals/spec/lib/tasks/my_task_spec.rb',
          'packs/animals/lib/tasks/my_organism_task.rake',
          'packs/animals/spec/lib/tasks/my_organism_task_spec.rb',
        ]

        expect_files_to_exist expected_files_after
      end
    end
  end

  describe '.make_public!' do
    let(:make_public) do
      UsePackwerk.make_public!(
        paths_relative_to_root: [file_to_make_public],
        per_file_processors: [UsePackwerk::RubocopPostProcessor.new],
      )
    end

    it 'can make files in the monolith public' do
      complex_app

      expected_files_before = [
        # Files in monolith
        'app/services/horse_like/zebra.rb',
        'app/services/horse_like/donkey.rb',
        'app/services/horse_like/horse.rb',
        'app/services/horse_like/zebra.rb',
        'app/services/fish_like/small_ones/goldfish.rb',
        'app/services/fish_like/small_ones/seahorse.rb',
        'app/services/fish_like/big_ones/whale.rb',
        # Specs in monolith
        'spec/services/dog_like/golden_retriever_spec.rb',
        'spec/services/fish_like/big_ones/whale_spec.rb',
        'spec/services/horse_like/donkey_spec.rb',
      ]

      expect_files_to_exist expected_files_before

      UsePackwerk.make_public!(
        paths_relative_to_root: [
          'app/services/fish_like',
          'app/services/horse_like/zebra.rb',
        ],
      )

      expect_files_to_not_exist([
        'app/services/horse_like/zebra.rb',
        'app/services/fish_like/small_ones/goldfish.rb',
        'app/services/fish_like/small_ones/seahorse.rb',
        'spec/services/fish_like/big_ones/whale_spec.rb',
      ])

      expected_files_after = [
        # Files in monolith
        'app/public/horse_like/zebra.rb',
        'app/services/horse_like/donkey.rb',
        'app/services/horse_like/horse.rb',
        'app/public/fish_like/small_ones/goldfish.rb',
        'app/public/fish_like/small_ones/seahorse.rb',
        'app/public/fish_like/big_ones/whale.rb',
        # Specs in monolith
        'spec/services/dog_like/golden_retriever_spec.rb',
        'spec/public/fish_like/big_ones/whale_spec.rb',
        'spec/services/horse_like/donkey_spec.rb',
      ]

      expect_files_to_exist expected_files_after
    end

    context 'app has public dir but nothing inside of it' do
      before { app_with_nothing_in_public_dir }
      let(:file_to_make_public) { 'packs/organisms/app/services/swan.rb' }

      it 'moves the file into the public directory' do
        expect(packages.count).to eq 1

        expected_file = packages.first.directory.join('app/public/swan.rb')
        expect(expected_file).to_not exist

        make_public

        expect(expected_file).to exist
      end

      it 'replaces the file in rubocop todo' do
        rubocop_todo = Pathname.new('.rubocop_todo.yml')

        expect(rubocop_todo.read).to include 'packs/organisms/app/services/swan.rb'
        expect(rubocop_todo.read).to_not include 'packs/organisms/app/public/swan.rb'

        make_public

        expect(rubocop_todo.read).to_not include 'packs/organisms/app/services/swan.rb'
        expect(rubocop_todo.read).to include 'packs/organisms/app/public/swan.rb'
      end
    end

    context 'app has no public dir' do
      before { app_with_no_public_dir }

      let(:file_to_make_public) { 'packs/organisms/app/services/swan.rb' }

      it 'moves the file into the public directory' do
        expect(packages.count).to eq 1

        expected_file = packages.first.directory.join('app/public/swan.rb')
        expect(expected_file).to_not exist

        make_public

        expect(expected_file).to exist
      end
    end

    context 'app with one file in public dir' do
      before { app_with_file_in_public_dir }
      let(:file_to_make_public) { 'packs/organisms/app/services/other_bird.rb' }

      it 'moves the file into the public directory' do
        expect(packages.count).to eq 1

        expected_file = packages.first.directory.join('app/public/other_bird.rb')
        expect(expected_file).to_not exist

        make_public

        expect(expected_file).to exist
      end
    end

    context 'pack is in gems' do
      before { complex_app } 
      let(:file_to_make_public) { 'gems/my_gem/app/services/my_gem_service.rb' }

      it 'moves the file into the public directory' do
        UsePackwerk.create_pack!(pack_name: 'gems/my_gem')

        expected_file = only_nonroot_package.directory.join('app/public/my_gem_service.rb')
        expect(expected_file).to_not exist

        make_public

        expect(expected_file).to exist
      end
    end

    context 'packs have files of the same name after making things public' do
      before { app_with_files_and_directories_with_same_names }

      it 'merges the set of files in common folders' do
        expected_files_before = [
          'packs/food/app/public/tomato.rb',
          'packs/food/app/public/salad.rb',
          'packs/food/app/services/salad.rb',
          'packs/food/app/services/salads/dressing.rb',
          'packs/food/app/workers/tomato.rb',
          'packs/food/spec/public/tomato_spec.rb',
          'packs/food/spec/services/salad_spec.rb',
          'packs/food/spec/services/salads/dressing_spec.rb',
        ]

        expect_files_to_exist expected_files_before

        UsePackwerk.make_public!(paths_relative_to_root: ['packs/food/app/services', 'packs/food/app/workers/tomato.rb'])

        expect_files_to_not_exist([
          'packs/food/app/services/salads/dressing.rb',
        ])

        expected_files_after = [
          'packs/food/app/public/tomato.rb',
          'packs/food/app/public/salad.rb',
          'packs/food/app/public/salads/dressing.rb',
          'packs/food/spec/public/salads/dressing_spec.rb',
          'packs/food/spec/public/salad_spec.rb',
          'packs/food/app/services/salad.rb',
          'packs/food/app/workers/tomato.rb',
          'packs/food/spec/public/tomato_spec.rb',
          'packs/food/app/public/tomato.rb',
        ]

        expect_files_to_exist expected_files_after
      end
    end
  end

  describe '.list_top_privacy_violations' do
    let(:list_top_privacy_violations) do
      UsePackwerk.list_top_privacy_violations(
        pack_name: pack_name,
        limit: limit,
      )
    end

    let(:limit) { 10 }
    before { app_with_lots_of_violations }

    context 'analyzing the root pack' do
      let(:pack_name) { ParsePackwerk::ROOT_PACKAGE_NAME }

      it 'has the right output' do
        logged_output = ""
        expect(UsePackwerk::Logging).to receive(:print).at_least(:once) do |string|
          logged_output += string
          logged_output += "\n"
        end

        list_top_privacy_violations
        puts logged_output

        expected_logged_output = <<~OUTPUT
        Total Count: 4
        RandomMonolithFile
          - Total Count: 4 (100.0% of total)
          - By package:
            - packs/food: 2
            - packs/organisms: 2
        OUTPUT
        expect(logged_output).to eq expected_logged_output
      end

    end

    context 'analyzing packs/food' do
      let(:pack_name) { 'packs/food' }

      it 'has the right output' do
        logged_output = ""
        expect(UsePackwerk::Logging).to receive(:print).at_least(:once) do |string|
          logged_output += string
          logged_output += "\n"
        end

        list_top_privacy_violations
        puts logged_output

        expected_logged_output = <<~OUTPUT
        Total Count: 3
        Salad
          - Total Count: 3 (100.0% of total)
          - By package:
            - packs/organisms: 2
            - .: 1
        OUTPUT
        expect(logged_output).to eq expected_logged_output
      end
    end

    context 'analyzing packs/organisms' do
      let(:pack_name) { 'packs/organisms' }

      it 'has the right output' do
        logged_output = ""
        expect(UsePackwerk::Logging).to receive(:print).at_least(:once) do |string|
          logged_output += string
          logged_output += "\n"
        end

        list_top_privacy_violations
        puts logged_output

        expected_logged_output = <<~OUTPUT
        Total Count: 4
        Vulture
          - Total Count: 2 (50.0% of total)
          - By package:
            - packs/food: 2
        Eagle
          - Total Count: 1 (25.0% of total)
          - By package:
            - packs/food: 1
        OtherBird
          - Total Count: 1 (25.0% of total)
          - By package:
            - packs/food: 1
        OUTPUT
        expect(logged_output).to eq expected_logged_output
      end

      context 'user has set a limit of 2' do
        let(:limit) { 2 }

        it 'has the right output' do
          logged_output = ""
          expect(UsePackwerk::Logging).to receive(:print).at_least(:once) do |string|
            logged_output += string
            logged_output += "\n"
          end

          list_top_privacy_violations
          puts logged_output

          expected_logged_output = <<~OUTPUT
          Total Count: 4
          Vulture
            - Total Count: 2 (50.0% of total)
            - By package:
              - packs/food: 2
          Eagle
            - Total Count: 1 (25.0% of total)
            - By package:
              - packs/food: 1
          OUTPUT
          expect(logged_output).to eq expected_logged_output
        end
      end
    end

    context 'analyzing a pack with a trailing slash in the name' do
      let(:pack_name) { 'packs/food/' }

      it 'has the right output' do
        logged_output = ""
        expect(UsePackwerk::Logging).to receive(:print).at_least(:once) do |string|
          logged_output += string
          logged_output += "\n"
        end

        list_top_privacy_violations
        puts logged_output

        expected_logged_output = <<~OUTPUT
        Total Count: 3
        Salad
          - Total Count: 3 (100.0% of total)
          - By package:
            - packs/organisms: 2
            - .: 1
        OUTPUT
        expect(logged_output).to eq expected_logged_output
      end
    end

    context 'analyzing all packs' do
      it 'has the right output' do
        logged_output = ""
        expect(UsePackwerk::Logging).to receive(:print).at_least(:once) do |string|
          logged_output += string
          logged_output += "\n"
        end

        UsePackwerk.list_top_privacy_violations(
          pack_name: nil,
          limit: limit,
        )

        puts logged_output

        expected_logged_output = <<~OUTPUT
        Total Count: 11
        RandomMonolithFile (.)
          - Total Count: 4 (36.36% of total)
          - By package:
            - packs/food: 2
            - packs/organisms: 2
        Salad (packs/food)
          - Total Count: 3 (27.27% of total)
          - By package:
            - packs/organisms: 2
            - .: 1
        Vulture (packs/organisms)
          - Total Count: 2 (18.18% of total)
          - By package:
            - packs/food: 2
        Eagle (packs/organisms)
          - Total Count: 1 (9.09% of total)
          - By package:
            - packs/food: 1
        OtherBird (packs/organisms)
          - Total Count: 1 (9.09% of total)
          - By package:
            - packs/food: 1
        OUTPUT
        expect(logged_output).to eq expected_logged_output
      end
    end
  end

  describe '.list_top_dependency_violations' do
    let(:list_top_dependency_violations) do
      UsePackwerk.list_top_dependency_violations(
        pack_name: pack_name,
        limit: limit,
      )
    end

    let(:limit) { 10 }
    before { app_with_lots_of_violations }

    context 'analyzing the root pack' do
      let(:pack_name) { ParsePackwerk::ROOT_PACKAGE_NAME }

      it 'has the right output' do
        logged_output = ""
        expect(UsePackwerk::Logging).to receive(:print).at_least(:once) do |string|
          logged_output += string
          logged_output += "\n"
        end

        list_top_dependency_violations
        puts logged_output

        expected_logged_output = <<~OUTPUT
        Total Count: 4
        RandomMonolithFile
          - Total Count: 4 (100.0% of total)
          - By package:
            - packs/food: 2
            - packs/organisms: 2
        OUTPUT
        expect(logged_output).to eq expected_logged_output
      end

    end

    context 'analyzing packs/food' do
      let(:pack_name) { 'packs/food' }

      it 'has the right output' do
        logged_output = ""
        expect(UsePackwerk::Logging).to receive(:print).at_least(:once) do |string|
          logged_output += string
          logged_output += "\n"
        end

        list_top_dependency_violations
        puts logged_output

        expected_logged_output = <<~OUTPUT
        Total Count: 4
        Burger
          - Total Count: 2 (50.0% of total)
          - By package:
            - packs/organisms: 2
        Salad
          - Total Count: 2 (50.0% of total)
          - By package:
            - packs/organisms: 2
        OUTPUT
        expect(logged_output).to eq expected_logged_output
      end
    end

    context 'analyzing packs/organisms' do
      let(:pack_name) { 'packs/organisms' }

      it 'has the right output' do
        logged_output = ""
        expect(UsePackwerk::Logging).to receive(:print).at_least(:once) do |string|
          logged_output += string
          logged_output += "\n"
        end

        list_top_dependency_violations
        puts logged_output

        expected_logged_output = <<~OUTPUT
        Total Count: 4
        Vulture
          - Total Count: 2 (50.0% of total)
          - By package:
            - packs/food: 2
        Eagle
          - Total Count: 1 (25.0% of total)
          - By package:
            - packs/food: 1
        OtherBird
          - Total Count: 1 (25.0% of total)
          - By package:
            - packs/food: 1
        OUTPUT
        expect(logged_output).to eq expected_logged_output
      end

      context 'user has set a limit of 2' do
        let(:limit) { 2 }

        it 'has the right output' do
          logged_output = ""
          expect(UsePackwerk::Logging).to receive(:print).at_least(:once) do |string|
            logged_output += string
            logged_output += "\n"
          end

          list_top_dependency_violations
          puts logged_output

          expected_logged_output = <<~OUTPUT
          Total Count: 4
          Vulture
            - Total Count: 2 (50.0% of total)
            - By package:
              - packs/food: 2
          Eagle
            - Total Count: 1 (25.0% of total)
            - By package:
              - packs/food: 1
          OUTPUT
          expect(logged_output).to eq expected_logged_output
        end
      end
    end

    context 'analyzing a pack with a trailing slash in the name' do
      let(:pack_name) { 'packs/food/' }

      it 'has the right output' do
        logged_output = ""
        expect(UsePackwerk::Logging).to receive(:print).at_least(:once) do |string|
          logged_output += string
          logged_output += "\n"
        end

        list_top_dependency_violations
        puts logged_output

        expected_logged_output = <<~OUTPUT
        Total Count: 4
        Burger
          - Total Count: 2 (50.0% of total)
          - By package:
            - packs/organisms: 2
        Salad
          - Total Count: 2 (50.0% of total)
          - By package:
            - packs/organisms: 2
        OUTPUT
        expect(logged_output).to eq expected_logged_output
      end
    end

    context 'analyzing all packs' do
      it 'has the right output' do
        logged_output = ""
        expect(UsePackwerk::Logging).to receive(:print).at_least(:once) do |string|
          logged_output += string
          logged_output += "\n"
        end

        UsePackwerk.list_top_dependency_violations(
          pack_name: nil,
          limit: limit,
        )

        puts logged_output

        expected_logged_output = <<~OUTPUT
        Total Count: 12
        RandomMonolithFile (.)
          - Total Count: 4 (33.33% of total)
          - By package:
            - packs/food: 2
            - packs/organisms: 2
        Burger (packs/food)
          - Total Count: 2 (16.67% of total)
          - By package:
            - packs/organisms: 2
        Salad (packs/food)
          - Total Count: 2 (16.67% of total)
          - By package:
            - packs/organisms: 2
        Vulture (packs/organisms)
          - Total Count: 2 (16.67% of total)
          - By package:
            - packs/food: 2
        Eagle (packs/organisms)
          - Total Count: 1 (8.33% of total)
          - By package:
            - packs/food: 1
        OtherBird (packs/organisms)
          - Total Count: 1 (8.33% of total)
          - By package:
            - packs/food: 1
        OUTPUT
        expect(logged_output).to eq expected_logged_output
      end
    end
  end

  describe '.add_dependency!' do
    let(:add_dependency) do
      UsePackwerk.add_dependency!(
        pack_name: pack_name,
        dependency_name: dependency_name,
      )
    end

    context 'pack has no dependencies' do
      let(:pack_name) { '.' }
      let(:dependency_name) { 'packs/other_pack' }

      before do
        write_file('package.yml', <<~YML.strip)
          enforce_dependencies: false
          enforce_privacy: false
        YML

        write_file('packs/other_pack/package.yml', <<~YML.strip)
          enforce_dependencies: false
          enforce_privacy: false
        YML
      end

      it 'adds the dependency' do
        expect(get_packages.find{|p| p.name == '.'}.dependencies).to eq([])
        add_dependency
        expect(get_packages.find{|p| p.name == '.'}.dependencies).to eq(['packs/other_pack'])
      end
    end

    context 'pack has one dependency' do
      let(:pack_name) { '.' }
      let(:dependency_name) { 'packs/other_pack' }

      before do
        write_file('package.yml', <<~YML.strip)
          enforce_dependencies: false
          enforce_privacy: false
          dependencies:
          - packs/yet_another_pack
        YML

        write_file('packs/other_pack/package.yml', <<~YML.strip)
          enforce_dependencies: false
          enforce_privacy: false
        YML

        write_file('packs/yet_another_pack/package.yml', <<~YML.strip)
          enforce_dependencies: false
          enforce_privacy: false
        YML
      end

      it 'adds the dependency' do
        expect(get_packages.find{|p| p.name == '.'}.dependencies).to eq(['packs/yet_another_pack'])
        add_dependency
        expect(get_packages.find{|p| p.name == '.'}.dependencies).to eq(['packs/other_pack', 'packs/yet_another_pack'])
      end
    end

    context 'pack has redundant dependency' do
      let(:pack_name) { '.' }
      let(:dependency_name) { 'packs/other_pack' }

      before do
        write_file('package.yml', <<~YML.strip)
          enforce_dependencies: false
          enforce_privacy: false
          dependencies:
          - packs/yet_another_pack
          - packs/yet_another_pack
        YML

        write_file('packs/other_pack/package.yml', <<~YML.strip)
          enforce_dependencies: false
          enforce_privacy: false
        YML

        write_file('packs/yet_another_pack/package.yml', <<~YML.strip)
          enforce_dependencies: false
          enforce_privacy: false
        YML
      end

      it 'adds the dependency and removes the redundant one' do
        expect(get_packages.find{|p| p.name == '.'}.dependencies).to eq(['packs/yet_another_pack', 'packs/yet_another_pack'])
        add_dependency
        expect(get_packages.find{|p| p.name == '.'}.dependencies).to eq(['packs/other_pack', 'packs/yet_another_pack'])
      end
    end

    context 'pack has unsorted dependencies' do
      let(:pack_name) { '.' }
      let(:dependency_name) { 'packs/other_pack' }

      before do
        write_file('package.yml', <<~YML.strip)
          enforce_dependencies: false
          enforce_privacy: false
          dependencies:
          - packs/yet_another_pack
          - packs/aa_yet_another_pack
        YML

        write_file('packs/other_pack/package.yml', <<~YML.strip)
          enforce_dependencies: false
          enforce_privacy: false
        YML

        write_file('packs/yet_another_pack/package.yml', <<~YML.strip)
          enforce_dependencies: false
          enforce_privacy: false
        YML

        write_file('packs/aa_yet_another_pack/package.yml', <<~YML.strip)
          enforce_dependencies: false
          enforce_privacy: false
        YML
      end

      it 'adds the dependency and sorts the other dependencies' do
        expect(get_packages.find{|p| p.name == '.'}.dependencies).to eq(['packs/yet_another_pack', 'packs/aa_yet_another_pack'])
        add_dependency
        expect(get_packages.find{|p| p.name == '.'}.dependencies).to eq(['packs/aa_yet_another_pack', 'packs/other_pack', 'packs/yet_another_pack'])
      end
    end

    context 'new dependency does not exist' do
      let(:pack_name) { '.' }
      let(:dependency_name) { 'packs/other_pack' }

      before do
        write_file('package.yml', <<~YML.strip)
          enforce_dependencies: false
          enforce_privacy: false
        YML
      end

      it 'adds the dependency and sorts the other dependencies' do
        expect(get_packages.find{|p| p.name == '.'}.dependencies).to eq([])
        expect { add_dependency }.to raise_error do |e|
          expect(e.message).to eq "Can not find package with name packs/other_pack. Make sure the argument is of the form `packs/my_pack/`"
        end
      end
    end

    context 'pack does not exist' do
      let(:pack_name) { '.' }
      let(:dependency_name) { 'packs/other_pack' }

      it 'adds the dependency and sorts the other dependencies' do
        expect { add_dependency }.to raise_error do |e|
          expect(e.message).to eq "Can not find package with name .. Make sure the argument is of the form `packs/my_pack/`"
        end
      end
    end
  end
end

