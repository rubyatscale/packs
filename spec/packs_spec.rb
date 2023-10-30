# typed: false

RSpec.describe Packs do
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

  def write_codeownership_config
    write_file('config/code_ownership.yml', <<~CONTENTS)
      owned_globs:
        - '{app,components,config,frontend,lib,packs,spec}/**/*.{rb,rake,js,jsx,ts,tsx}'
      unowned_globs:
        - app/services/horse_like/donkey.rb
        - spec/services/horse_like/donkey_spec.rb
    CONTENTS
  end

  before do
    Packs.bust_cache!
    CodeTeams.bust_caches!
    # Always add the root package for every spec
    write_package_yml('.')
    allow(Packs::Logging).to receive(:out)
    allow(Packs::Logging).to receive(:print)
  end

  describe '.create_pack!' do
    before do
      write_file('packwerk.yml', <<~YML)
        require:
          - packwerk/privacy/checker
      YML
    end

    # Right now, `Packs` only supports `packs`, `gems`, or `components` as the home for packwerk packages
    context 'pack name does not include `packs` prefix' do
      let(:pack_name) { 'my_pack' }

      it 'errors' do
        expect { Packs.create_pack!(pack_name: 'foo/my_pack') }.to raise_error(
          'Packs only supports packages in the the following directories: ["gems", "components", "packs"]. Please make sure to pass in the name of the pack including the full directory path, e.g. `packs/my_pack`.'
        )
      end
    end

    it 'creates a package.yml correctly' do
      write_codeownership_config

      Packs.create_pack!(pack_name: 'packs/my_pack')
      ParsePackwerk.bust_cache!
      package = ParsePackwerk.find('packs/my_pack')
      expect(package.name).to eq('packs/my_pack')
      expect(package.enforce_privacy).to eq(true)
      expect(package.enforce_dependencies).to eq(true)
      expect(package.dependencies).to eq([])
      expect(package.config['owner']).to eq('MyTeam')
      expect(package.metadata).to eq({})

      expected = <<~EXPECTED
        enforce_dependencies: true
        enforce_privacy: true
        owner: MyTeam # specify your team here, or delete this key if this package is not owned by one team
      EXPECTED

      expect(package.yml.read).to eq expected
    end

    context 'code ownership is not yet configured' do
      it 'creates a package.yml correctly' do
        Packs.create_pack!(pack_name: 'packs/my_pack')
        ParsePackwerk.bust_cache!
        package = ParsePackwerk.find('packs/my_pack')
        expect(package.name).to eq('packs/my_pack')
        expect(package.enforce_privacy).to eq(true)
        expect(package.enforce_dependencies).to eq(true)
        expect(package.dependencies).to eq([])
        expect(package.metadata).to eq({})

        expected = <<~EXPECTED
          enforce_dependencies: true
          enforce_privacy: true
        EXPECTED

        expect(package.yml.read).to eq expected
      end
    end

    context 'use packwerk is configured to not enforce dependencies by default' do
      it 'creates a package.yml correctly' do
        write_codeownership_config
        Packs.configure { |config| config.enforce_dependencies = false }
        Packs.create_pack!(pack_name: 'packs/my_pack')
        expected_package = ParsePackwerk::Package.new(
          name: 'packs/my_pack',
          enforce_privacy: true,
          enforce_dependencies: false,
          dependencies: [],
          metadata: {},
          config: { 'owner' => 'MyTeam' }
        )

        ParsePackwerk.bust_cache!

        actual_package = ParsePackwerk.find('packs/my_pack')
        expect(actual_package.name).to eq(expected_package.name)
        expect(actual_package.enforce_privacy).to eq(expected_package.enforce_privacy)
        expect(actual_package.enforce_dependencies).to eq(expected_package.enforce_dependencies)
        expect(actual_package.dependencies).to eq(expected_package.dependencies)
        expect(actual_package.metadata).to eq(expected_package.metadata)
      end
    end

    context 'pack already exists and has content' do
      it 'is idempotent' do
        write_package_yml('packs/food', enforce_privacy: false, enforce_dependencies: true, dependencies: ['packs/some_other_pack'])
        expect(ParsePackwerk.all.count).to eq 2
        Packs.create_pack!(pack_name: 'packs/food/')
        ParsePackwerk.bust_cache!
        expect(ParsePackwerk.all.count).to eq 2
        package = ParsePackwerk.find('packs/food')

        expect(package.name).to eq('packs/food')
        expect(package.enforce_privacy).to eq(false)
        expect(package.enforce_dependencies).to eq(true)
        expect(package.dependencies).to eq(['packs/some_other_pack'])
      end
    end

    it 'automatically adds the owner metadata key' do
      write_codeownership_config
      Packs.create_pack!(pack_name: 'packs/my_pack')
      ParsePackwerk.bust_cache!
      package = ParsePackwerk.find('packs/my_pack')
      expect(package.config['owner']).to eq 'MyTeam'
      package_yml_contents = package.yml.read
      expect(package_yml_contents).to include('owner: MyTeam # specify your team here, or delete this key if this package is not owned by one team')
    end

    context 'team owner is provided' do
      it 'automatically adds the owner top-level key' do
        write_codeownership_config
        write_file('config/teams/artists.yml', 'name: Artists')
        Packs.create_pack!(pack_name: 'packs/my_pack', team: CodeTeams.find('Artists'))
        ParsePackwerk.bust_cache!
        package = ParsePackwerk.find('packs/my_pack')
        expect(package.metadata).to eq({})
        expect(package.config['owner']).to eq 'Artists'
        package_yml_contents = package.yml.read
        expect(package_yml_contents).to include('owner: Artists')
      end
    end

    context 'pack is in gems' do
      let(:pack_name) { 'gems/my_pack' }

      it 'creates the pack' do
        Packs.create_pack!(pack_name: 'gems/my_pack')
        ParsePackwerk.bust_cache!
        expect(ParsePackwerk.find('gems/my_pack').name).to eq('gems/my_pack')
      end
    end

    context 'pack is nested' do
      let(:pack_name) { 'packs/fruits/apples' }

      it 'creates a package.yml correctly' do
        write_codeownership_config
        Packs.create_pack!(pack_name: 'packs/fruits/apples')
        ParsePackwerk.bust_cache!
        package = ParsePackwerk.find('packs/fruits/apples')
        expect(package.name).to eq('packs/fruits/apples')
        expect(package.enforce_privacy).to eq(true)
        expect(package.enforce_dependencies).to eq(true)
        expect(package.dependencies).to eq([])
        expect(package.config['owner']).to eq('MyTeam')
        expect(package.metadata).to eq({})

        expected = <<~EXPECTED
          enforce_dependencies: true
          enforce_privacy: true
          owner: MyTeam # specify your team here, or delete this key if this package is not owned by one team
        EXPECTED

        expect(package.yml.read).to eq expected
      end
    end

    describe 'creating a TODO.md inside app/public' do
      let(:expected_todo) do
        <<~TODO
          This directory holds your public API!

          Any classes, constants, or modules that you want other packs to use and you intend to support should go in here.
          Anything that is considered private should go in other folders.

          If another pack uses classes, constants, or modules that are not in your public folder, it will be considered a "privacy violation" by packwerk.
          You can prevent other packs from using private API by using packwerk.

          Want to find how your private API is being used today?
          Try running: `bin/packs list_top_violations privacy packs/organisms`

          Want to move something into this folder?
          Try running: `bin/packs make_public packs/organisms/path/to/file.rb`

          One more thing -- feel free to delete this file and replace it with a README.md describing your package in the main package directory.

          See https://github.com/rubyatscale/packs#readme for more info!
        TODO
      end

      context 'app has no public dir' do
        it 'adds a TODO.md file letting someone know what to do with it' do
          Packs.create_pack!(pack_name: 'packs/organisms')
          actual_todo = Pathname.new('packs/organisms/app/public/TODO.md').read
          expect(actual_todo).to eq expected_todo
        end

        context 'pack not enforcing privacy' do
          it 'does not add a TODO.md file' do
            Packs.create_pack!(pack_name: 'packs/organisms', enforce_privacy: false)

            ParsePackwerk.bust_cache!
            package = ParsePackwerk.find('packs/organisms')
            expect(package.enforce_privacy).to eq(false)
            todo_file = Pathname.new('packs/organisms/app/public/TODO.md')
            expect(todo_file.exist?).to eq false
          end
        end
      end

      context 'app with one file in public dir' do
        it 'does not add a TODO.md file' do
          write_file('packs/organisms/app/public/my_public_api.rb')
          Packs.create_pack!(pack_name: 'packs/organisms')
          todo_file = Pathname.new('packs/organisms/app/public/TODO.md')
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

          README.md files are under version control and should change as your public API changes.#{' '}

          See https://github.com/rubyatscale/packs#readme for more info!
        EXPECTED
      end

      it 'adds a README_TODO.md file as a placeholder' do
        Packs.create_pack!(pack_name: 'packs/organisms')
        ParsePackwerk.bust_cache!
        actual_readme_todo = ParsePackwerk.find('packs/organisms').directory.join('README_TODO.md')
        expect(actual_readme_todo.read).to eq expected_readme_todo
      end

      context 'app has one pack with an outdated README_TODO.md' do
        it 'overwrites the README_TODO.md' do
          write_file('packs/organisms/README_TODO.md', 'This is outdated')
          write_package_yml('packs/organisms')
          actual_readme_todo = ParsePackwerk.find('packs/organisms').directory.join('README_TODO.md')
          expect(actual_readme_todo.read).to eq 'This is outdated'
          Packs.create_pack!(pack_name: 'packs/organisms')
          expect(actual_readme_todo.read).to eq expected_readme_todo
        end
      end

      context 'app has one pack with a README.md' do
        it 'does not add a README_TODO.md file' do
          write_package_yml('packs/organisms')
          write_file('packs/organisms/README.md')
          actual_readme_todo = ParsePackwerk.find('packs/organisms').directory.join('README_TODO.md')
          Packs.create_pack!(pack_name: 'packs/organisms')
          expect(actual_readme_todo.exist?).to eq false
        end
      end
    end
  end

  describe '.move_to_pack!' do
    before do
      write_file('packwerk.yml', <<~YML)
        require:
          - packwerk/privacy/checker
      YML
    end

    context 'pack is not nested' do
      context 'pack not yet created' do
        it 'errors' do
          write_file('app/services/foo.rb')

          expect {
            Packs.move_to_pack!(pack_name: 'packs/animals', paths_relative_to_root: ['app/services/foo.rb'])
          }.to raise_error('Can not find package with name packs/animals. Make sure the argument is of the form `packs/my_pack/`')
        end
      end

      it 'can move files from a monolith and their specs into a package' do
        write_file('app/services/horse_like/donkey.rb')
        write_file('spec/services/horse_like/donkey_spec.rb')
        write_package_yml('packs/animals')
        Packs.move_to_pack!(
          pack_name: 'packs/animals',
          paths_relative_to_root: ['app/services/horse_like/donkey.rb']
        )

        expect_files_to_not_exist([
                                    'app/services/horse_like/donkey.rb',
                                    'spec/services/horse_like/donkey_spec.rb'
                                  ])

        expect_files_to_exist([
                                'packs/animals/app/services/horse_like/donkey.rb',
                                'packs/animals/spec/services/horse_like/donkey_spec.rb'
                              ])
      end

      it 'can move directories from a monolith and their specs into a package' do
        write_file('app/services/horse_like/donkey.rb')
        write_file('spec/services/horse_like/donkey_spec.rb')
        write_package_yml('packs/animals')
        Packs.move_to_pack!(
          pack_name: 'packs/animals',
          paths_relative_to_root: ['app/services/horse_like']
        )

        expect_files_to_not_exist([
                                    'app/services/horse_like/donkey.rb',
                                    'spec/services/horse_like/donkey_spec.rb'
                                  ])

        expect_files_to_exist([
                                'packs/animals/app/services/horse_like/donkey.rb',
                                'packs/animals/spec/services/horse_like/donkey_spec.rb'
                              ])
      end

      it 'can move files from a parent pack to another parent pack' do
        write_package_yml('packs/organisms')
        write_package_yml('packs/animals')

        write_file('packs/organisms/app/services/horse_like/donkey.rb')
        write_file('packs/organisms/spec/services/horse_like/donkey_spec.rb')

        Packs.move_to_pack!(
          pack_name: 'packs/animals',
          paths_relative_to_root: ['packs/organisms/app/services/horse_like/donkey.rb']
        )

        expect_files_to_not_exist([
                                    'packs/organisms/app/services/horse_like/donkey.rb',
                                    'packs/organisms/spec/services/horse_like/donkey_spec.rb'
                                  ])

        expect_files_to_exist([
                                'packs/animals/app/services/horse_like/donkey.rb',
                                'packs/animals/spec/services/horse_like/donkey_spec.rb'
                              ])
      end

      it 'can move files from a child pack to a parent pack' do
        write_package_yml('packs/animals/horse_like')
        write_package_yml('packs/animals')

        write_file('packs/animals/horse_like/app/services/horse_like/donkey.rb')
        write_file('packs/animals/horse_like/spec/services/horse_like/donkey_spec.rb')

        Packs.move_to_pack!(
          pack_name: 'packs/animals',
          paths_relative_to_root: ['packs/animals/horse_like/app/services/horse_like/donkey.rb']
        )

        expect_files_to_not_exist([
                                    'packs/animals/horse_like/app/services/horse_like/donkey.rb',
                                    'packs/animals/horse_like/spec/services/horse_like/donkey_spec.rb'
                                  ])

        expect_files_to_exist([
                                'packs/animals/app/services/horse_like/donkey.rb',
                                'packs/animals/spec/services/horse_like/donkey_spec.rb'
                              ])
      end

      context 'directory moves have trailing slashes' do
        it 'can move files from one pack to another pack' do
          write_package_yml('packs/organisms')
          write_package_yml('packs/animals')

          write_file('packs/organisms/app/services/horse_like/donkey.rb')
          write_file('packs/organisms/spec/services/horse_like/donkey_spec.rb')

          Packs.move_to_pack!(
            pack_name: 'packs/animals',
            paths_relative_to_root: ['packs/organisms/app/services/horse_like/']
          )

          expect_files_to_not_exist([
                                      'packs/organisms/app/services/horse_like/donkey.rb',
                                      'packs/organisms/spec/services/horse_like/donkey_spec.rb'
                                    ])

          expect_files_to_exist([
                                  'packs/animals/app/services/horse_like/donkey.rb',
                                  'packs/animals/spec/services/horse_like/donkey_spec.rb'
                                ])
        end
      end

      context 'packs have files folders of the same name' do
        it 'merges the folders' do
          write_package_yml('packs/food')
          write_package_yml('packs/organisms')
          write_file('packs/food/app/services/salad.rb')
          write_file('packs/food/app/services/tomato.rb')
          write_file('packs/organisms/app/services/apple.rb')
          write_file('packs/organisms/app/services/sunflower.rb')

          Packs.move_to_pack!(
            pack_name: 'packs/food',
            paths_relative_to_root: [
              'packs/organisms/app/services'
            ]
          )

          expect_files_to_not_exist([
                                      'packs/organisms/app/services/sunflower.rb',
                                      'packs/organisms/app/services/apple.rb'
                                    ])

          expect_files_to_exist([
                                  'packs/food/app/services/salad.rb',
                                  'packs/food/app/services/tomato.rb',
                                  'packs/food/app/services/sunflower.rb',
                                  'packs/food/app/services/apple.rb'
                                ])
        end
      end

      context 'packs have files of the same name' do
        it 'leaves the origin and destination in place' do
          write_package_yml('packs/food')
          write_package_yml('packs/organisms')
          write_file('packs/food/app/services/salad.rb')
          write_file('packs/organisms/app/services/salad.rb')

          Packs.move_to_pack!(
            pack_name: 'packs/food',
            paths_relative_to_root: [
              'packs/organisms/app/services'
            ]
          )

          expect_files_to_exist([
                                  'packs/food/app/services/salad.rb',
                                  'packs/organisms/app/services/salad.rb'
                                ])
        end
      end

      context 'files moved are tasks in lib' do
        it 'can move files from lib from one pack to another pack' do
          write_package_yml('packs/my_pack')
          write_package_yml('packs/organisms')
          write_file('lib/tasks/my_task.rake')
          write_file('spec/lib/tasks/my_task_spec.rb')
          write_file('packs/organisms/lib/tasks/my_other_task.rake')
          write_file('packs/organisms/spec/lib/tasks/my_other_task_spec.rb')

          Packs.move_to_pack!(
            pack_name: 'packs/my_pack',
            paths_relative_to_root: [
              'lib/tasks/my_task.rake',
              'packs/organisms/lib/tasks/my_other_task.rake'
            ]
          )

          expect_files_to_not_exist([
                                      'lib/tasks/my_task.rake',
                                      'spec/lib/tasks/my_task_spec.rb',
                                      'packs/organisms/lib/tasks/my_other_task.rake',
                                      'packs/organisms/spec/lib/tasks/my_other_task_spec.rb'
                                    ])

          expect_files_to_exist([
                                  'packs/my_pack/lib/tasks/my_task.rake',
                                  'packs/my_pack/spec/lib/tasks/my_task_spec.rb',
                                  'packs/my_pack/lib/tasks/my_other_task.rake',
                                  'packs/my_pack/spec/lib/tasks/my_other_task_spec.rb'
                                ])
        end
      end

      describe 'RubocopPostProcessor' do
        context 'moving file listed in top-level .rubocop_todo.yml' do
          it 'modifies an application-specific file, .rubocop_todo.yml, correctly' do
            write_file('.rubocop.yml')

            write_file('.rubocop_todo.yml', <<~CONTENTS)
              ---
              Layout/BeginEndAlignment:
                Exclude:
                - packs/foo/app/services/foo.rb
            CONTENTS

            before_rubocop_todo = YAML.load_file(Pathname.new('.rubocop_todo.yml'))

            expect(before_rubocop_todo).to eq({ 'Layout/BeginEndAlignment' => { 'Exclude' => ['packs/foo/app/services/foo.rb'] } })

            write_file('packs/foo/app/services/foo.rb')
            Packs.create_pack!(pack_name: 'packs/bar')
            Packs.create_pack!(pack_name: 'packs/foo')
            ParsePackwerk.bust_cache!
            Packs.move_to_pack!(
              pack_name: 'packs/bar',
              paths_relative_to_root: ['packs/foo/app/services/foo.rb'],
              per_file_processors: [Packs::RubocopPostProcessor.new]
            )

            after_rubocop_todo = YAML.load_file(Pathname.new('.rubocop_todo.yml'))
            expect(after_rubocop_todo).to eq({ 'Layout/BeginEndAlignment' => { 'Exclude' => ['packs/bar/app/services/foo.rb'] } })
          end
        end
      end

      describe 'CodeOwnershipPostProcessor' do
        before do
          write_codeownership_config
        end

        it 'modifies an application-specific file, config/code_ownership.yml, correctly' do
          write_file('app/services/horse_like/donkey.rb')
          write_file('spec/services/horse_like/donkey_spec.rb')
          write_package_yml('packs/animals')

          Packs.move_to_pack!(
            pack_name: 'packs/animals',
            paths_relative_to_root: ['app/services/horse_like'],
            per_file_processors: [Packs::CodeOwnershipPostProcessor.new]
          )

          after_codeownership_yml = File.read(Pathname.new('config/code_ownership.yml'))

          expect(after_codeownership_yml).to_not include '- app/services/horse_like/donkey.rb'
          expect(after_codeownership_yml).to_not include '- spec/services/horse_like/donkey_spec.rb'
          expect(after_codeownership_yml).to include '- packs/animals/app/services/horse_like/donkey.rb'
          expect(after_codeownership_yml).to include '- packs/animals/spec/services/horse_like/donkey_spec.rb'
        end

        it 'prints out the right ownership' do
          write_package_yml('packs/owned_by_artists', owner: 'Artists')
          write_file('packs/owned_by_artists/app/services/foo.rb')
          write_file('config/teams/artists.yml', 'name: Artists')

          logged_output = ''

          expect(Packs::Logging).to receive(:print).at_least(:once) do |string|
            logged_output += string
            logged_output += "\n"
          end

          Packs.move_to_pack!(
            pack_name: '.',
            paths_relative_to_root: ['packs/owned_by_artists/app/services/foo.rb'],
            per_file_processors: [Packs::CodeOwnershipPostProcessor.new]
          )

          expected_logged_output = <<~OUTPUT
            This section contains info about the current ownership distribution of the moved files.
              Artists - 1 files
          OUTPUT

          expect(logged_output).to include expected_logged_output
        end

        it 'removes file annotations if the destination pack has file annotations' do
          write_codeownership_config

          write_package_yml('packs/owned_by_artists', owner: 'Artists')
          write_file('app/services/foo.rb', '# @team Chefs')
          write_file('config/teams/artists.yml', 'name: Artists')
          write_file('config/teams/chefs.yml', 'name: Chefs')

          logged_output = ''

          expect(Packs::Logging).to receive(:print).at_least(:once) do |string|
            logged_output += string
            logged_output += "\n"
          end

          Packs.move_to_pack!(
            pack_name: 'packs/owned_by_artists',
            paths_relative_to_root: ['app/services/foo.rb'],
            per_file_processors: [Packs::CodeOwnershipPostProcessor.new]
          )

          expected_logged_output = <<~OUTPUT
            This section contains info about the current ownership distribution of the moved files.
              Chefs - 1 files
            Since the destination package has package-based ownership, file-annotations were removed from moved files.
          OUTPUT

          expect(logged_output).to include expected_logged_output

          expect(Pathname.new('packs/owned_by_artists/app/services/foo.rb').read).to eq('')
        end
      end
    end

    context 'pack is nested' do
      let(:pack_name) { 'packs/fruits/apples' }

      context 'pack not yet created' do
        it 'errors' do
          expect {
            Packs.move_to_pack!(paths_relative_to_root: ['packs/fruits/apples/app/services/mcintosh.rb'], pack_name: 'packs/fruits/apples')
          }.to raise_error('Can not find package with name packs/fruits/apples. Make sure the argument is of the form `packs/my_pack/`')
        end
      end

      it 'can move files from a monolith into a child package' do
        write_package_yml('packs/fruits/apples')
        write_file('app/services/mcintosh.rb')
        write_file('spec/services/mcintosh_spec.rb')

        Packs.move_to_pack!(
          paths_relative_to_root: ['app/services/mcintosh.rb'],
          pack_name: 'packs/fruits/apples'
        )
        expect_files_to_not_exist([
                                    'app/services/mcintosh.rb',
                                    'spec/services/mcintosh_spec.rb'
                                  ])

        expect_files_to_exist([
                                'packs/fruits/apples/app/services/mcintosh.rb',
                                'packs/fruits/apples/spec/services/mcintosh_spec.rb'
                              ])
      end

      it 'can move files from a parent pack to a child pack' do
        write_package_yml('packs/fruits/apples')
        write_package_yml('packs/fruits')
        write_file('packs/fruits/app/services/mcintosh.rb')
        write_file('packs/fruits/spec/services/mcintosh_spec.rb')

        Packs.move_to_pack!(
          paths_relative_to_root: ['packs/fruits/app/services/mcintosh.rb'],
          pack_name: 'packs/fruits/apples'
        )
        expect_files_to_not_exist([
                                    'packs/fruits/app/services/mcintosh.rb',
                                    'packs/fruits/spec/services/mcintosh_spec.rb'
                                  ])

        expect_files_to_exist([
                                'packs/fruits/apples/app/services/mcintosh.rb',
                                'packs/fruits/apples/spec/services/mcintosh_spec.rb'
                              ])
      end
    end

    describe 'creating a TODO.md inside app/public' do
      let(:expected_todo) do
        <<~TODO
          This directory holds your public API!

          Any classes, constants, or modules that you want other packs to use and you intend to support should go in here.
          Anything that is considered private should go in other folders.

          If another pack uses classes, constants, or modules that are not in your public folder, it will be considered a "privacy violation" by packwerk.
          You can prevent other packs from using private API by using packwerk.

          Want to find how your private API is being used today?
          Try running: `bin/packs list_top_violations privacy packs/organisms`

          Want to move something into this folder?
          Try running: `bin/packs make_public packs/organisms/path/to/file.rb`

          One more thing -- feel free to delete this file and replace it with a README.md describing your package in the main package directory.

          See https://github.com/rubyatscale/packs#readme for more info!
        TODO
      end

      context 'app has no public dir' do
        it 'adds a TODO.md file letting someone know what to do with it' do
          write_file('app/services/foo.rb')
          write_package_yml('packs/organisms')
          Packs.move_to_pack!(
            pack_name: 'packs/organisms',
            paths_relative_to_root: ['app/services/foo.rb']
          )

          actual_todo = Pathname.new('packs/organisms/app/public/TODO.md').read
          expect(actual_todo).to eq expected_todo
        end

        context 'pack not enforcing privacy' do
          it 'does not add a TODO.md file' do
            write_file('app/services/foo.rb')
            write_package_yml('packs/organisms', enforce_privacy: false)
            Packs.move_to_pack!(
              pack_name: 'packs/organisms',
              paths_relative_to_root: ['app/services/foo.rb']
            )

            todo_file = Pathname.new('packs/organisms/app/public/TODO.md')
            expect(todo_file.exist?).to eq false
          end
        end
      end

      context 'app with one file in public dir' do
        it 'does not add a TODO.md file' do
          write_file('packs/organisms/app/public/my_public_api.rb')
          write_file('app/services/foo.rb')
          write_package_yml('packs/organisms')
          Packs.move_to_pack!(
            pack_name: 'packs/organisms',
            paths_relative_to_root: ['app/services/foo.rb']
          )

          todo_file = Pathname.new('packs/organisms/app/public/TODO.md')
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

          README.md files are under version control and should change as your public API changes.#{' '}

          See https://github.com/rubyatscale/packs#readme for more info!
        EXPECTED
      end

      it 'adds a README_TODO.md file as a placeholder' do
        write_file('app/services/foo.rb')
        write_package_yml('packs/organisms')
        Packs.move_to_pack!(
          pack_name: 'packs/organisms',
          paths_relative_to_root: ['app/services/foo.rb']
        )

        actual_readme_todo = ParsePackwerk.find('packs/organisms').directory.join('README_TODO.md')
        expect(actual_readme_todo.read).to eq expected_readme_todo
      end

      context 'app has one pack with an outdated README_TODO.md' do
        it 'overwrites the README_TODO.md' do
          write_file('app/services/foo.rb')
          write_package_yml('packs/organisms')
          write_file('packs/organisms/README_TODO.md', 'This is outdated')
          actual_readme_todo = ParsePackwerk.find('packs/organisms').directory.join('README_TODO.md')
          expect(actual_readme_todo.read).to eq 'This is outdated'
          Packs.move_to_pack!(
            pack_name: 'packs/organisms',
            paths_relative_to_root: ['app/services/foo.rb']
          )
          expect(actual_readme_todo.read).to eq expected_readme_todo
        end
      end

      context 'app has one pack with a README.md' do
        it 'does not add a README_TODO.md file' do
          write_file('app/services/foo.rb')
          write_package_yml('packs/organisms')
          write_file('packs/organisms/README.md')
          actual_readme_todo = ParsePackwerk.find('packs/organisms').directory.join('README_TODO.md')
          Packs.move_to_pack!(
            pack_name: 'packs/organisms',
            paths_relative_to_root: ['app/services/foo.rb']
          )
          expect(actual_readme_todo.exist?).to eq false
        end
      end
    end
  end

  describe '.make_public!' do
    it 'can make individual files in the monolith and their specs public' do
      write_file('app/services/horse_like/donkey.rb')
      write_file('spec/services/horse_like/donkey_spec.rb')

      Packs.make_public!(
        paths_relative_to_root: ['app/services/horse_like/donkey.rb']
      )

      expect_files_to_not_exist([
                                  'app/services/horse_like/donkey.rb',
                                  'spec/services/horse_like/donkey_spec.rb'
                                ])

      expect_files_to_exist([
                              'app/public/horse_like/donkey.rb',
                              'spec/public/horse_like/donkey_spec.rb'
                            ])
    end

    it 'can make directories in the monolith and their specs public' do
      write_file('app/services/fish_like/small_ones/goldfish.rb')
      write_file('app/services/fish_like/small_ones/seahorse.rb')
      write_file('app/services/fish_like/big_ones/whale.rb')
      write_file('spec/services/fish_like/big_ones/whale_spec.rb')

      Packs.make_public!(
        paths_relative_to_root: ['app/services/fish_like']
      )

      expect_files_to_not_exist([
                                  'app/services/fish_like/small_ones/goldfish.rb',
                                  'app/services/fish_like/small_ones/seahorse.rb',
                                  'app/services/fish_like/big_ones/whale.rb',
                                  'spec/services/fish_like/big_ones/whale_spec.rb'
                                ])

      expect_files_to_exist([
                              'app/public/fish_like/small_ones/goldfish.rb',
                              'app/public/fish_like/small_ones/seahorse.rb',
                              'app/public/fish_like/big_ones/whale.rb',
                              'spec/public/fish_like/big_ones/whale_spec.rb'
                            ])
    end

    it 'can make files in a nested pack public' do
      Packs.create_pack!(pack_name: 'packs/fruits/apples')
      ParsePackwerk.bust_cache!
      write_file('packs/fruits/apples/app/services/apple.rb')
      write_file('packs/fruits/apples/spec/services/apple_spec.rb')

      Packs.make_public!(
        paths_relative_to_root: ['packs/fruits/apples/app/services/apple.rb']
      )

      expect_files_to_not_exist([
                                  'packs/fruits/apples/app/services/apple.rb',
                                  'packs/fruits/apples/spec/services/apple_spec.rb'
                                ])

      expect_files_to_exist([
                              'packs/fruits/apples/app/public/apple.rb',
                              'packs/fruits/apples/spec/public/apple_spec.rb'
                            ])
    end

    context 'pack has empty public directory' do
      it 'moves the file into the public directory' do
        write_package_yml('packs/organisms')
        write_file('packs/organisms/app/services/other_bird.rb')
        write_file('packs/organisms/spec/services/other_bird_spec.rb')

        Packs.make_public!(
          paths_relative_to_root: ['packs/organisms/app/services/other_bird.rb']
        )

        expect_files_to_not_exist([
                                    'packs/organisms/app/services/other_bird.rb',
                                    'packs/organisms/spec/services/other_bird_spec.rb'
                                  ])

        expect_files_to_exist([
                                'packs/organisms/app/public/other_bird.rb',
                                'packs/organisms/spec/public/other_bird_spec.rb'
                              ])
      end

      it 'replaces the file in the top-level .rubocop_todo.yml' do
        write_file('.rubocop.yml')
        write_package_yml('packs/organisms')

        write_file('.rubocop_todo.yml', <<~CONTENTS)
          ---
          Layout/BeginEndAlignment:
            Exclude:
            - packs/organisms/app/services/other_bird.rb
        CONTENTS

        write_file('packs/organisms/app/services/other_bird.rb')
        write_file('packs/organisms/spec/services/other_bird_spec.rb')

        rubocop_todo = Pathname.new('.rubocop_todo.yml')

        expect(rubocop_todo.read).to include 'packs/organisms/app/services/other_bird.rb'
        expect(rubocop_todo.read).to_not include 'packs/organisms/app/public/other_bird.rb'

        Packs.make_public!(
          paths_relative_to_root: ['packs/organisms/app/services/other_bird.rb'],
          per_file_processors: [Packs::RubocopPostProcessor.new]
        )

        expect(rubocop_todo.read).to_not include 'packs/organisms/app/services/other_bird.rb'
        expect(rubocop_todo.read).to include 'packs/organisms/app/public/other_bird.rb'
      end
    end

    context 'pack with one file in public dir' do
      it 'moves the file into the public directory' do
        write_package_yml('packs/organisms')
        write_file('packs/organisms/app/public/swan.rb')
        write_file('packs/organisms/app/services/other_bird.rb')
        write_file('packs/organisms/spec/services/other_bird_spec.rb')

        Packs.make_public!(
          paths_relative_to_root: ['packs/organisms/app/services/other_bird.rb']
        )

        expect_files_to_not_exist([
                                    'packs/organisms/app/services/other_bird.rb',
                                    'packs/organisms/spec/services/other_bird_spec.rb'
                                  ])

        expect_files_to_exist([
                                'packs/organisms/app/public/swan.rb',
                                'packs/organisms/app/public/other_bird.rb',
                                'packs/organisms/spec/public/other_bird_spec.rb'
                              ])
      end
    end

    context 'pack is in gems' do
      it 'moves the file into the public directory' do
        write_package_yml('gems/my_gem')
        write_file('gems/my_gem/app/public/my_gem_service.rb')

        Packs.make_public!(
          paths_relative_to_root: ['gems/my_gem/app/services/my_gem_service.rb']
        )

        expect_files_to_exist(['gems/my_gem/app/public/my_gem_service.rb'])
        expect_files_to_not_exist(['gems/my_gem/app/services/my_gem_service.rb'])
      end
    end

    context 'packs have files of the same name after making things public' do
      it 'merges the set of files in common without overwriting' do
        write_package_yml('packs/food')

        write_file('packs/food/app/public/salad.rb')
        write_file('packs/food/spec/public/salad_spec.rb')
        write_file('packs/food/app/services/salad.rb')
        write_file('packs/food/spec/services/salad_spec.rb')
        write_file('packs/food/app/services/salad_dressing.rb')
        write_file('packs/food/spec/services/salads/dressing_spec.rb')

        Packs.make_public!(
          paths_relative_to_root: [
            'packs/food/app/services/salad.rb',
            'packs/food/app/services/salad_dressing.rb'
          ]
        )

        expect_files_to_not_exist([
                                    'packs/food/app/services/salad_dressing.rb',
                                    'packs/food/spec/services/salad_dressing_spec.rb'
                                  ])

        expected_files_after = [
          'packs/food/app/public/salad.rb',
          'packs/food/spec/public/salad_spec.rb',
          'packs/food/app/services/salad.rb',
          'packs/food/spec/services/salad_spec.rb'
        ]

        expect_files_to_exist expected_files_after
      end
    end
  end

  describe '.add_dependency!' do
    context 'pack has no dependencies' do
      it 'adds the dependency and runs validate' do
        write_package_yml('packs/other_pack')

        expect(ParsePackwerk.find('.').dependencies).to eq([])
        expect(Packs).to receive(:validate).and_return(true)
        Packs.add_dependency!(pack_name: '.', dependency_name: 'packs/other_pack')
        ParsePackwerk.bust_cache!
        expect(ParsePackwerk.find('.').dependencies).to eq(['packs/other_pack'])
      end
    end

    context 'pack has one dependency' do
      it 'adds the dependency and runs validate' do
        write_package_yml('.', dependencies: ['packs/foo'])
        write_package_yml('packs/other_pack')
        expect(ParsePackwerk.find('.').dependencies).to eq(['packs/foo'])
        expect(Packs).to receive(:validate).and_return(true)
        Packs.add_dependency!(pack_name: '.', dependency_name: 'packs/other_pack')
        ParsePackwerk.bust_cache!
        expect(ParsePackwerk.find('.').dependencies).to eq(['packs/foo', 'packs/other_pack'])
      end
    end

    context 'pack has redundant dependency' do
      it 'adds the dependency, removes the redundant one, and adds validate' do
        write_package_yml('.', dependencies: ['packs/foo', 'packs/foo', 'packs/foo'])
        write_package_yml('packs/other_pack')
        expect(ParsePackwerk.find('.').dependencies).to eq(['packs/foo', 'packs/foo', 'packs/foo'])
        expect(Packs).to receive(:validate).and_return(false)
        Packs.add_dependency!(pack_name: '.', dependency_name: 'packs/other_pack')
        ParsePackwerk.bust_cache!
        expect(ParsePackwerk.find('.').dependencies).to eq(['packs/foo', 'packs/other_pack'])
      end
    end

    context 'pack has unsorted dependencies' do
      it 'adds the dependency, sorts the other dependencies, and runs validate' do
        write_package_yml('.', dependencies: ['packs/foo', 'packs/zoo', 'packs/boo'])
        write_package_yml('packs/other_pack')

        expect(ParsePackwerk.find('.').dependencies).to eq(['packs/foo', 'packs/zoo', 'packs/boo'])
        expect(Packs).to receive(:validate).and_return(false)
        Packs.add_dependency!(pack_name: '.', dependency_name: 'packs/other_pack')
        ParsePackwerk.bust_cache!
        expect(ParsePackwerk.find('.').dependencies).to eq(['packs/boo', 'packs/foo', 'packs/other_pack', 'packs/zoo'])
      end
    end

    context 'new dependency does not exist' do
      it 'raises an error and does not run validate' do
        expect(ParsePackwerk.find('.').dependencies).to eq([])
        expect(Packs).to_not receive(:validate)
        expect { Packs.add_dependency!(pack_name: '.', dependency_name: 'packs/other_pack') }.to raise_error do |e|
          expect(e.message).to eq 'Can not find package with name packs/other_pack. Make sure the argument is of the form `packs/my_pack/`'
        end
      end
    end

    context 'pack does not exist' do
      it 'raises an error and does not run validate' do
        expect(Packs).to_not receive(:validate)
        expect { Packs.add_dependency!(pack_name: 'packs/other_pack', dependency_name: '.') }.to raise_error do |e|
          expect(e.message).to eq 'Can not find package with name packs/other_pack. Make sure the argument is of the form `packs/my_pack/`'
        end
      end
    end
  end

  describe 'move_to_parent!' do
    it 'moves over all files and the package.yml' do
      write_package_yml('packs/fruits')
      write_package_yml('packs/apples', dependencies: ['packs/other_pack'], metadata: { 'custom_field' => 'custom value' })

      write_file('packs/apples/package_todo.yml', <<~CONTENTS)
        ---
        ".":
          "SomeConstant":
            violations:
            - privacy
            files:
            - packs/apples/app/services/apple.rb
      CONTENTS

      write_file('packs/apples/app/services/apples/some_yml.yml')
      write_file('packs/apples/app/services/apples.rb')
      write_file('packs/apples/app/services/apples/foo.rb')
      write_file('packs/apples/README.md')

      Packs.move_to_parent!(
        pack_name: 'packs/apples',
        parent_name: 'packs/fruits'
      )

      ParsePackwerk.bust_cache!

      expect(ParsePackwerk.find('packs/apples')).to be_nil
      actual_package = ParsePackwerk.find('packs/fruits/apples')
      expect(actual_package).to_not be_nil
      expect(actual_package.metadata['custom_field']).to eq 'custom value'
      expect(actual_package.dependencies).to eq(['packs/other_pack'])

      expect_files_to_exist([
                              'packs/fruits/apples/app/services/apples/some_yml.yml',
                              'packs/fruits/apples/app/services/apples.rb',
                              'packs/fruits/apples/app/services/apples/foo.rb',
                              'packs/fruits/apples/README.md'
                            ])

      expect_files_to_not_exist([
                                  'packs/apples/app/services/apples/some_yml.yml',
                                  'packs/apples/app/services/apples.rb',
                                  'packs/apples/app/services/apples/foo.rb',
                                  'packs/apples/package.yml',
                                  'packs/apples/package_todo.yml',
                                  'packs/apples/README.md'
                                ])

      expect(Pathname.new('packs/apples')).to exist

      expect(ParsePackwerk.find('packs/fruits').dependencies).to eq(['packs/fruits/apples'])
    end

    it 'updates ignored_dependencies in all package.yml' do
      write_package_yml('packs/fruits')
      write_package_yml('packs/apples', dependencies: ['packs/other_pack'], metadata: { 'custom_field' => 'custom value' })
      write_package_yml('packs/turtles', config: { 'ignored_dependencies' => ['packs/apples'] })

      Packs.move_to_parent!(
        pack_name: 'packs/apples',
        parent_name: 'packs/fruits'
      )

      ParsePackwerk.bust_cache!

      expect(ParsePackwerk.find('packs/turtles').config['ignored_dependencies']).to eq(['packs/fruits/apples'])
    end

    it 'gives some helpful output to users' do
      logged_output = ''

      expect(Packs::Logging).to receive(:out).at_least(:once) do |string|
        logged_output += Rainbow.uncolor(string)
        logged_output += "\n"
      end

      expect(Packs::Logging).to receive(:print).at_least(:once) do |string|
        logged_output += Rainbow.uncolor(string)
        logged_output += "\n"
      end

      write_package_yml('packs/fruits')
      write_package_yml('packs/apples')
      write_file('packs/apples/app/services/apples/foo.rb')

      Packs.move_to_parent!(
        pack_name: 'packs/apples',
        parent_name: 'packs/fruits'
      )

      expect(logged_output).to eq <<~OUTPUT
        ====================================================================================================
        👋 Hi!


        You are moving one pack to be a child of a different pack. Check out https://github.com/rubyatscale/packs#readme for more info!

        ====================================================================================================
        File Operations


        Moving file packs/apples/app/services/apples/foo.rb to packs/fruits/apples/app/services/apples/foo.rb
        ====================================================================================================
        Next steps


        Your next steps might be:

        1) Delete the old pack when things look good: `git rm -r packs/apples`

        2) Run `bin/packwerk update-todo` to update the violations. Make sure to run `spring stop` first.

      OUTPUT
    end

    it 'rewrites other packs package.yml files to point to the new nested package' do
      write_package_yml('packs/fruits', dependencies: ['packs/apples'])
      write_package_yml('packs/other_pack', dependencies: ['packs/apples', 'packs/something_else'])
      write_package_yml('packs/apples')

      Packs.move_to_parent!(
        pack_name: 'packs/apples',
        parent_name: 'packs/fruits'
      )

      ParsePackwerk.bust_cache!

      expect(ParsePackwerk.find('packs/fruits').dependencies).to eq(['packs/fruits/apples'])
      expect(ParsePackwerk.find('packs/other_pack').dependencies).to eq(['packs/fruits/apples', 'packs/something_else'])
    end

    it 'updates sorbet config to point at the new spec location' do
      write_package_yml('packs/fruits')
      write_package_yml('packs/apples')
      write_file('sorbet/config', <<~CONTENTS)
        --dir
        .
        --ignore=/packs/other_pack/spec
        --ignore=/packs/apples/spec
      CONTENTS

      Packs.move_to_parent!(
        pack_name: 'packs/apples',
        parent_name: 'packs/fruits'
      )

      ParsePackwerk.bust_cache!

      expect(Pathname.new('sorbet/config').read).to eq <<~CONTENTS
        --dir
        .
        --ignore=/packs/other_pack/spec
        --ignore=/packs/fruits/apples/spec
      CONTENTS
    end

    context 'parent pack does not already exist' do
      it 'creates it' do
        # Parent pack does not exist!
        # write_package_yml('packs/fruits')

        write_package_yml('packs/apples')

        Packs.move_to_parent!(
          pack_name: 'packs/apples',
          parent_name: 'packs/fruits'
        )

        ParsePackwerk.bust_cache!
        expect(Pathname.new('packs/apples')).to exist
        expect(ParsePackwerk.find('packs/fruits').dependencies).to eq(['packs/fruits/apples'])
      end
    end

    describe 'RubocopPostProcessor' do
      it 'modifies an application-specific file, .rubocop_todo.yml, correctly' do
        write_file('.rubocop.yml')

        write_file('.rubocop_todo.yml', <<~CONTENTS)
          ---
          Layout/BeginEndAlignment:
            Exclude:
            - packs/foo/app/services/foo.rb
        CONTENTS

        before_rubocop_todo = YAML.load_file(Pathname.new('.rubocop_todo.yml'))

        expect(before_rubocop_todo).to eq({ 'Layout/BeginEndAlignment' => { 'Exclude' => ['packs/foo/app/services/foo.rb'] } })

        write_file('packs/foo/app/services/foo.rb')
        Packs.create_pack!(pack_name: 'packs/bar')
        Packs.create_pack!(pack_name: 'packs/foo')
        ParsePackwerk.bust_cache!
        Packs.move_to_parent!(
          pack_name: 'packs/foo',
          parent_name: 'packs/bar',
          per_file_processors: [Packs::RubocopPostProcessor.new]
        )

        after_rubocop_todo = YAML.load_file(Pathname.new('.rubocop_todo.yml'))
        expect(after_rubocop_todo).to eq({ 'Layout/BeginEndAlignment' => { 'Exclude' => ['packs/bar/foo/app/services/foo.rb'] } })
      end
    end
  end

  describe 'lint_package_todo_yml_files!' do
    context 'no diff after running update-todo' do
      it 'exits successfully' do
        expect(Packs).to receive(:update).and_return(true)
        expect(Packs.const_get(:Private)).to receive(:exit_with).with(true)
        expect(Packs.const_get(:Private)).to_not receive(:puts)
        Packs.lint_package_todo_yml_files!
      end
    end

    context 'some stale violations removed after running update-todo' do
      it 'exits in a failure' do
        write_file('packs/my_pack/package.yml', <<~CONTENTS)
          enforce_privacy: true
          enforce_dependencies: true
        CONTENTS

        write_file('packs/my_pack/package_todo.yml', <<~CONTENTS)
          ---
          packs/my_other_pack:
            "::SomeConstant":
              violations:
              - privacy
              files:
              - packs/my_pack/app/services/my_pack.rb
              - packs/my_pack/app/services/my_pack_2.rb
        CONTENTS

        expect(Packs).to receive(:update) do
          write_file('packs/my_pack/package_todo.yml', <<~CONTENTS)
            ---
            packs/my_other_pack:
              "::SomeConstant":
                violations:
                - privacy
                files:
                - packs/my_pack/app/services/my_pack.rb
          CONTENTS

          true
        end

        expect(Packs.const_get(:Private)).to receive(:puts).with(<<~EXPECTED)
          All `package_todo.yml` files must be up-to-date and that no diff is generated when running `bin/packwerk update-todo`.
          This helps ensure a high quality signal in other engineers' PRs when inspecting new violations by ensuring there are no unrelated changes.

          There are three main reasons there may be a diff:
          1) Most likely, you may have stale violations, meaning there are old violations that no longer apply.
          2) You may have some sort of auto-formatter set up somewhere (e.g. something that reformats YML files) that is, for example, changing double quotes to single quotes. Ensure this is turned off for these auto-generated files.
          3) You may have edited these files manually. It's recommended to use the `bin/packwerk update-todo` command to make changes to `package_todo.yml` files.

          In all cases, you can run `bin/packwerk update-todo` to update these files.

          Here is the diff generated after running `update-todo`:
          ```
          diff -r /packs/my_pack/package_todo.yml /packs/my_pack/package_todo.yml
          8d7
          <     - packs/my_pack/app/services/my_pack_2.rb

          ```

        EXPECTED

        expect(Packs.const_get(:Private)).to receive(:exit_with).with(false)
        Packs.lint_package_todo_yml_files!
      end
    end

    context 'some formatting changes after running update-todo' do
      it 'exits in a failure' do
        callback_invocation = false
        Packs.configure do |config|
          config.on_package_todo_lint_failure = ->(output) { callback_invocation = output }
        end
        write_file('packs/my_pack/package.yml', <<~CONTENTS)
          enforce_privacy: true
          enforce_dependencies: true
        CONTENTS

        write_file('packs/my_pack/package_todo.yml', <<~CONTENTS)
          ---
          packs/my_other_pack:
            '::SomeConstant':
              violations:
              - privacy
              files:
              - packs/my_pack/app/services/my_pack.rb
              - packs/my_pack/app/services/my_pack_2.rb
        CONTENTS

        expect(Packs).to receive(:update) do
          write_file('packs/my_pack/package_todo.yml', <<~CONTENTS)
            ---
            packs/my_other_pack:
              "::SomeConstant":
                violations:
                - privacy
                files:
                - packs/my_pack/app/services/my_pack.rb
                - packs/my_pack/app/services/my_pack_2.rb
          CONTENTS

          true
        end

        expect(Packs.const_get(:Private)).to receive(:puts).with(<<~EXPECTED)
          All `package_todo.yml` files must be up-to-date and that no diff is generated when running `bin/packwerk update-todo`.
          This helps ensure a high quality signal in other engineers' PRs when inspecting new violations by ensuring there are no unrelated changes.

          There are three main reasons there may be a diff:
          1) Most likely, you may have stale violations, meaning there are old violations that no longer apply.
          2) You may have some sort of auto-formatter set up somewhere (e.g. something that reformats YML files) that is, for example, changing double quotes to single quotes. Ensure this is turned off for these auto-generated files.
          3) You may have edited these files manually. It's recommended to use the `bin/packwerk update-todo` command to make changes to `package_todo.yml` files.

          In all cases, you can run `bin/packwerk update-todo` to update these files.

          Here is the diff generated after running `update-todo`:
          ```
          diff -r /packs/my_pack/package_todo.yml /packs/my_pack/package_todo.yml
          3c3
          <   '::SomeConstant':
          ---
          >   "::SomeConstant":

          ```

        EXPECTED

        expect(Packs.const_get(:Private)).to receive(:exit_with).with(false)
        Packs.lint_package_todo_yml_files!
        expect(callback_invocation).to include('All `package_todo.yml` files must be up-to-date')
      end
    end
  end

  describe 'lint_package_yml_files!' do
    context 'package has no linting issues' do
      before do
        write_file('packs/my_pack/package.yml', <<~CONTENTS)
          enforce_dependencies: true
          enforce_privacy: true
          owner: Bar
          dependencies:
            - packs/apack
            - packs/bpack
            - packs/cpack
        CONTENTS
      end

      it 'produces no changes' do
        Packs.lint_package_yml_files!(Packs.all)
        expect(Packs.find('packs/my_pack').yml.read).to eq <<~YML
          enforce_dependencies: true
          enforce_privacy: true
          owner: Bar
          dependencies:
            - packs/apack
            - packs/bpack
            - packs/cpack
        YML
      end
    end

    context 'package has several linting issues' do
      before do
        write_file('packs/my_pack/package.yml', <<~CONTENTS)
          enforce_visibility: true
          enforce_privacy: true
          enforce_dependencies: true
          owner: Benefits Plan Recommendations
          dependencies:
            - gems/carrier_metadata
            - packs/authorizations
            - packs/carrier_registry
            - packs/demographics
            - packs/feature_flags
            - packs/metrics
            - packs/rails_shims
            - packs/underwriting_rules
            - packs/versions
          ignored_dependencies:
            - packs/carrier_implementation_setup
            - packs/integrations
          metadata:
            product_group: plan_recommendation_engine
          visible_to:
            - packs/benefits_applications
          layer: product
        CONTENTS
      end

      it 'produces a linted version of the pack' do
        Packs.lint_package_yml_files!(Packs.all)
        expect(Packs.find('packs/my_pack').yml.read).to eq <<~YML
          enforce_dependencies: true
          enforce_privacy: true
          enforce_visibility: true
          owner: Benefits Plan Recommendations
          layer: product
          dependencies:
            - gems/carrier_metadata
            - packs/authorizations
            - packs/carrier_registry
            - packs/demographics
            - packs/feature_flags
            - packs/metrics
            - packs/rails_shims
            - packs/underwriting_rules
            - packs/versions
          ignored_dependencies:
            - packs/carrier_implementation_setup
            - packs/integrations
          visible_to:
            - packs/benefits_applications
          metadata:
            product_group: plan_recommendation_engine
        YML
      end
    end

    context 'package has no owner' do
      before do
        write_file('packs/my_pack/package.yml', <<~CONTENTS)
          enforce_dependencies: true
          enforce_privacy: true
        CONTENTS
      end

      it 'produces no owner related changes' do
        Packs.lint_package_yml_files!(Packs.all)
        expect(Packs.find('packs/my_pack').yml.read).to eq <<~YML
          enforce_dependencies: true
          enforce_privacy: true
        YML
      end
    end

    context 'package has an owner specified in metadata' do
      before do
        write_file('packs/my_pack/package.yml', <<~CONTENTS)
          enforce_privacy: true
          enforce_dependencies: true
          metadata:
            owner: My Team
        CONTENTS
      end

      it 'moves owner to top-level key' do
        Packs.lint_package_yml_files!(Packs.all)
        expect(Packs.find('packs/my_pack').yml.read).to eq <<~YML
          enforce_dependencies: true
          enforce_privacy: true
          owner: My Team
        YML
      end
    end

    context 'package has no metadata' do
      before do
        write_file('packs/my_pack/package.yml', <<~CONTENTS)
          enforce_privacy: true
          enforce_dependencies: true
          metadata:
        CONTENTS
      end

      it 'removes metadata' do
        Packs.lint_package_yml_files!(Packs.all)
        expect(Packs.find('packs/my_pack').yml.read).to eq <<~YML
          enforce_dependencies: true
          enforce_privacy: true
        YML
      end
    end

    context 'package has no dependencies' do
      before do
        write_file('packs/my_pack/package.yml', <<~CONTENTS)
          enforce_privacy: true
          enforce_dependencies: true
          dependencies: []
        CONTENTS
      end

      it 'removes dependencies' do
        Packs.lint_package_yml_files!(Packs.all)
        expect(Packs.find('packs/my_pack').yml.read).to eq <<~YML
          enforce_dependencies: true
          enforce_privacy: true
        YML
      end
    end
  end

  # This will soon be moved into `query_packwerk`
  describe 'query_packwerk' do
    before do
      write_package_yml('packs/food')
      write_package_yml('packs/organisms')

      write_file('package_todo.yml', <<~CONTENTS)
        # This file contains a list of dependencies that are not part of the long term plan for ..
        # We should generally work to reduce this list, but not at the expense of actually getting work done.
        #
        # You can regenerate this file using the following command:
        #
        # bundle exec packwerk update-todo .
        ---
        "packs/food":
          "Salad":
            violations:
            - privacy
            files:
            - random_monolith_file.rb
      CONTENTS

      write_file('packs/food/package_todo.yml', <<~CONTENTS)
        # This file contains a list of dependencies that are not part of the long term plan for ..
        # We should generally work to reduce this list, but not at the expense of actually getting work done.
        #
        # You can regenerate this file using the following command:
        #
        # bundle exec packwerk update-todo .
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

      write_file('packs/organisms/package_todo.yml', <<~CONTENTS)
        # This file contains a list of dependencies that are not part of the long term plan for ..
        # We should generally work to reduce this list, but not at the expense of actually getting work done.
        #
        # You can regenerate this file using the following command:
        #
        # bundle exec packwerk update-todo .
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
    end

    describe '.list_top_violations for privacy' do
      let(:list_top_privacy_violations) do
        Packs.list_top_violations(
          type: 'privacy',
          pack_name: pack_name,
          limit: limit
        )
      end

      let(:limit) { 10 }

      context 'analyzing the root pack' do
        let(:pack_name) { ParsePackwerk::ROOT_PACKAGE_NAME }

        it 'has the right output' do
          logged_output = ''
          expect(Packs::Logging).to receive(:print).at_least(:once) do |string|
            logged_output += string
            logged_output += "\n"
          end

          list_top_privacy_violations

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
          logged_output = ''
          expect(Packs::Logging).to receive(:print).at_least(:once) do |string|
            logged_output += string
            logged_output += "\n"
          end

          list_top_privacy_violations

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
          logged_output = ''
          expect(Packs::Logging).to receive(:print).at_least(:once) do |string|
            logged_output += string
            logged_output += "\n"
          end

          list_top_privacy_violations

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
            logged_output = ''
            expect(Packs::Logging).to receive(:print).at_least(:once) do |string|
              logged_output += string
              logged_output += "\n"
            end

            list_top_privacy_violations

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
          logged_output = ''
          expect(Packs::Logging).to receive(:print).at_least(:once) do |string|
            logged_output += string
            logged_output += "\n"
          end

          list_top_privacy_violations

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
          logged_output = ''
          expect(Packs::Logging).to receive(:print).at_least(:once) do |string|
            logged_output += string
            logged_output += "\n"
          end

          Packs.list_top_violations(
            type: 'privacy',
            pack_name: nil,
            limit: limit
          )

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

    describe '.list_top_violations for dependency' do
      let(:list_top_dependency_violations) do
        Packs.list_top_violations(
          type: 'dependency',
          pack_name: pack_name,
          limit: limit
        )
      end

      let(:limit) { 10 }

      context 'analyzing the root pack' do
        let(:pack_name) { ParsePackwerk::ROOT_PACKAGE_NAME }

        it 'has the right output' do
          logged_output = ''
          expect(Packs::Logging).to receive(:print).at_least(:once) do |string|
            logged_output += string
            logged_output += "\n"
          end

          list_top_dependency_violations

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
          logged_output = ''
          expect(Packs::Logging).to receive(:print).at_least(:once) do |string|
            logged_output += string
            logged_output += "\n"
          end

          list_top_dependency_violations

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
          logged_output = ''
          expect(Packs::Logging).to receive(:print).at_least(:once) do |string|
            logged_output += string
            logged_output += "\n"
          end

          list_top_dependency_violations

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
            logged_output = ''
            expect(Packs::Logging).to receive(:print).at_least(:once) do |string|
              logged_output += string
              logged_output += "\n"
            end

            list_top_dependency_violations

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
          logged_output = ''
          expect(Packs::Logging).to receive(:print).at_least(:once) do |string|
            logged_output += string
            logged_output += "\n"
          end

          list_top_dependency_violations

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
          logged_output = ''
          expect(Packs::Logging).to receive(:print).at_least(:once) do |string|
            logged_output += string
            logged_output += "\n"
          end

          Packs.list_top_violations(
            type: 'dependency',
            pack_name: nil,
            limit: limit
          )

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
  end
end
