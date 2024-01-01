# frozen_string_literal: true

require 'tty/prompt/test'

module Packs
  RSpec.describe Private::InteractiveCli::PackDirectorySelector do
    let(:prompt) { TTY::Prompt::Test.new }

    it 'passes pack subdirectories to the prompt' do
      write_file 'packs/admin/.keep'
      write_file 'packs/utilities/subdir/.keep'
      write_file 'not_packs/some_other_dir/.keep'

      expected = [
        'packs/admin',
        'packs/utilities',
        'packs/utilities/subdir'
      ]

      expect(prompt).to receive(:select) do |_, directories, _, _, _|
        expect(directories).to eq(expected)
      end.and_return(expected.first)

      described_class.select(prompt)
    end
  end
end
