# frozen_string_literal: true

require 'tty/prompt/test'

module UsePackwerk
  RSpec.describe Private::InteractiveCli do
    let(:prompt) { TTY::Prompt::Test.new }
    subject do
      Private::InteractiveCli.start!(prompt: prompt)
    end

    it 'allows creating a new pack interactively' do
      write_file('config/teams/artists.yml', 'name: Artists')
      expect(UsePackwerk).to receive(:create_pack!).with(pack_name: 'packs/my_new_pack', team: CodeTeams.find('Artists'))
      prompt.input << "Create\r"
      prompt.input << "my_new_pack\r"
      prompt.input << "Artists\r"
      prompt.input.rewind
      subject
    end

    it 'allows adding a dependency interactively' do
      write_package_yml('packs/my_dependent_pack')
      write_package_yml('packs/my_dependency')
      expect(UsePackwerk).to receive(:add_dependency!).with(pack_name: 'packs/my_dependent_pack', dependency_name: 'packs/my_dependency')
      prompt.input << "Add a dependency\r"
      prompt.input << "my_dependent_pack\r"
      prompt.input << "my_dependency\r"
      prompt.input.rewind
      subject
    end

    it 'allows making files public interactively' do
      prompt.input << "public\r"
      prompt.input << "packs/my_pack/path/to/file.rb\r"
      prompt.input << "packs/my_pack/path/to/other_file.rb\r"
      prompt.input << "\C-d"
      prompt.input.rewind
      expect(UsePackwerk).to receive(:make_public!).with(
        paths_relative_to_root: ['packs/my_pack/path/to/file.rb', 'packs/my_pack/path/to/other_file.rb'],
        per_file_processors: anything
      )
      subject
    end

    it 'allows moving files interactively' do
      write_package_yml('packs/my_destination_pack')
      prompt.input << "Move\r"
      prompt.input << "my_destination_pack\r"
      prompt.input << "packs/my_pack/path/to/file.rb\r"
      prompt.input << "packs/my_pack/path/to/other_file.rb\r"
      prompt.input << "\C-d"
      prompt.input.rewind
      expect(UsePackwerk).to receive(:move_to_pack!).with(
        pack_name: 'packs/my_destination_pack',
        paths_relative_to_root: ['packs/my_pack/path/to/file.rb', 'packs/my_pack/path/to/other_file.rb'],
        per_file_processors: anything
      )
      subject
    end

    it 'allows moving files interactively' do
      write_package_yml('packs/my_destination_pack')
      prompt.input << "Move\r"
      prompt.input << "my_destination_pack\r"
      prompt.input << "packs/my_pack/path/to/file.rb\r"
      prompt.input << "packs/my_pack/path/to/other_file.rb\r"
      prompt.input << "\C-d"
      prompt.input.rewind
      expect(UsePackwerk).to receive(:move_to_pack!).with(
        pack_name: 'packs/my_destination_pack',
        paths_relative_to_root: ['packs/my_pack/path/to/file.rb', 'packs/my_pack/path/to/other_file.rb'],
        per_file_processors: anything
      )
      subject
    end
  end
end
