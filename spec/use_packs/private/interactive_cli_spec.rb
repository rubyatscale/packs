# frozen_string_literal: true

require 'tty/prompt/test'

module UsePacks
  module INPUTS
    UP = "\e[A"
    DOWN = "\e[B"
    LEFT = "\e[D"
    RIGHT = "\e[C"

    TAB = "\t"
    RETURN = "\r"
    SPACE = ' ' # For multi-select to make this explicit
    EOF = "\C-d" # Ctrl-D - End of File
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

    it 'allows creating a pack even if no teams are setup' do
      expect(UsePacks).to receive(:create_pack!).with(pack_name: 'packs/my_new_pack', team: nil)
      prompt.input << "Create\r"
      prompt.input << "my_new_pack\r"
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
      prompt.input << INPUTS::DOWN
      prompt.input << INPUTS::DOWN
      prompt.input << INPUTS::RETURN
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

    it 'allows making files public interactively in single-line mode' do
      prompt.input << "public\r"
      prompt.input << "packs/my_pack/path/to/file.rb\r"
      prompt.input << INPUTS::EOF
      prompt.input.rewind
      expect(UsePacks).to receive(:make_public!).with(
        paths_relative_to_root: ['packs/my_pack/path/to/file.rb'],
        per_file_processors: anything
      )
      subject
    end

    it 'allows making files public interactively in multi-line mode' do
      prompt.input << "public\r"
      prompt.input << INPUTS::TAB
      prompt.input << "packs/my_pack/path/to/file.rb\r"
      prompt.input << "packs/my_pack/path/to/other_file.rb\r"
      prompt.input << INPUTS::EOF
      prompt.input.rewind
      expect(UsePacks).to receive(:make_public!).with(
        paths_relative_to_root: ['packs/my_pack/path/to/file.rb', 'packs/my_pack/path/to/other_file.rb'],
        per_file_processors: anything
      )
      subject
    end

    it 'allows moving files interactively in single-line mode' do
      write_package_yml('packs/my_destination_pack')
      prompt.input << "Move\r"
      prompt.input << "my_destination_pack\r"
      prompt.input << "packs/my_pack/path/to/file.rb\r"
      prompt.input << INPUTS::EOF
      prompt.input.rewind
      expect(UsePacks).to receive(:move_to_pack!).with(
        pack_name: 'packs/my_destination_pack',
        paths_relative_to_root: ['packs/my_pack/path/to/file.rb'],
        per_file_processors: anything
      )
      subject
    end

    it 'allows moving files interactively in multi-line mode' do
      write_package_yml('packs/my_destination_pack')
      prompt.input << "Move\r"
      prompt.input << "my_destination_pack\r"
      prompt.input << INPUTS::TAB
      prompt.input << "packs/my_pack/path/to/file.rb\r"
      prompt.input << "packs/my_pack/path/to/other_file.rb\r"
      prompt.input << INPUTS::EOF
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
      prompt.input << INPUTS::RETURN # (Confirms 'Packs')

      prompt.input << INPUTS::DOWN # Do you select packs by name or by owner?
      prompt.input << INPUTS::RETURN # (Confirms 'owner')

      prompt.input << 'Artists' # Please select team owners
      prompt.input << INPUTS::SPACE # (Select it)
      prompt.input << INPUTS::RETURN # (Confirm selection)
      prompt.input << INPUTS::EOF

      prompt.input.rewind

      expect(VisualizePacks).to receive(:package_graph!).with([Packs.all.first])

      subject
    end

    it 'fails to visualize if no packs are selected' do
      write_package_yml('packs/my_destination_pack', owner: 'Artists')
      write_file('config/teams/artists.yml', 'name: Artists')

      prompt.input << "Visualize\r" # Hello! What would you like to do?

      prompt.input << INPUTS::DOWN # Do you want the graph nodes to be teams or packs?
      prompt.input << INPUTS::RETURN # (Confirms 'Packs')

      prompt.input << INPUTS::DOWN # Do you select packs by name or by owner?
      prompt.input << INPUTS::RETURN # (Confirms 'owner')

      prompt.input << 'Artists' # Please select team owners
      # prompt.input << INPUTS::SPACE # We "forgot" to use space here! (simulate failure case)
      prompt.input << INPUTS::RETURN # (submit invalid)

      # ...please select an owner using the space key before pressing enter.

      prompt.input << 'Artists' # Please select team owners
      prompt.input << INPUTS::SPACE # Rememebered the space this time
      prompt.input << INPUTS::RETURN # (Confirm selection)

      prompt.input << INPUTS::EOF

      prompt.input.rewind

      expect(VisualizePacks).to receive(:package_graph!).with([Packs.all.first])

      subject
    end
  end
end
