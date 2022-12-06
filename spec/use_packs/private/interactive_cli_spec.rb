# frozen_string_literal: true

require 'tty/prompt/test'

module UsePacks
  module INPUTS
    UP = "\e[A\r"
    DOWN = "\e[B\r"
    LEFT = "\e[D\r"
    RIGHT = "\e[C\r"

    RETURN = "\r"
    SPACE = " "
  end

  RSpec.describe Private::InteractiveCli do
    let(:prompt) { TTY::Prompt::Test.new }
    subject do
      Private::InteractiveCli.start!(prompt: prompt)
    end

    before { CodeTeams.bust_caches! }

    it 'allows creating a new pack interactively' do
      write_file('config/teams/artists.yml', 'name: Artists')
      expect(UsePacks).to receive(:create_pack!).with(pack_name: 'packs/my_new_pack', team: CodeTeams.find('Artists'))
      prompt.input << "Create\r"
      prompt.input << "my_new_pack\r"
      prompt.input << "Artists\r"
      prompt.input.rewind
      subject
    end

    it 'shows teams listed alphabetically and you can pick one with arrow keys' do
      write_file('config/teams/zebras.yml', 'name: Zebras')
      write_file('config/teams/artists.yml', 'name: Artists')
      write_file('config/teams/bbs.yml', 'name: BBs')

      expect(UsePacks).to receive(:create_pack!).with(pack_name: 'packs/my_new_pack', team: CodeTeams.find('Zebras'))
      prompt.input << "Create\r"
      prompt.input << "my_new_pack\r"
      prompt.input << "\e[B" # down arrow
      prompt.input << "\e[B" # down arrow
      prompt.input << "\r"
      prompt.input.rewind
      subject
    end

    it 'allows adding a dependency interactively' do
      write_package_yml('packs/my_dependent_pack')
      write_package_yml('packs/my_dependency')
      expect(UsePacks).to receive(:add_dependency!).with(pack_name: 'packs/my_dependent_pack', dependency_name: 'packs/my_dependency')
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
      expect(UsePacks).to receive(:make_public!).with(
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
      expect(UsePacks).to receive(:move_to_pack!).with(
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
      expect(UsePacks).to receive(:move_to_pack!).with(
        pack_name: 'packs/my_destination_pack',
        paths_relative_to_root: ['packs/my_pack/path/to/file.rb', 'packs/my_pack/path/to/other_file.rb'],
        per_file_processors: anything
      )
      subject
    end

    it 'allows visualizing packs interactively' do
      write_package_yml('packs/my_destination_pack', owner: 'Artists')
      write_file('config/teams/artists.yml', 'name: Artists')

      prompt.input << "Visualize\r" # Hello! What would you like to do?
      prompt.input << INPUTS::DOWN # Do you want the graph nodes to be teams or packs?
      prompt.input << INPUTS::DOWN # Do you select packs by name or by owner?

      prompt.input << "Artists" # Please select team owners
      prompt.input << INPUTS::SPACE
      prompt.input << INPUTS::RETURN
      prompt.input.rewind

      expect(VisualizePackwerk).to receive(:package_graph!).with([ParsePackwerk.all.first])

      subject
    end

    it 'fails to visualize if no packs are selected' do
      write_package_yml('packs/my_destination_pack', owner: 'Artists')
      write_file('config/teams/artists.yml', 'name: Artists')

      prompt.input << "Visualize\r" # Hello! What would you like to do?
      prompt.input << INPUTS::DOWN # Do you want the graph nodes to be teams or packs?
      prompt.input << INPUTS::DOWN # Do you select packs by name or by owner?

      prompt.input << "Artists" # Please select team owners
      # prompt.input << INPUTS::SPACE # Forgot to use space here!
      prompt.input << INPUTS::RETURN
      prompt.input.rewind

      expect(VisualizePackwerk).to receive(:package_graph!).with([])

      subject
    end
  end
end
