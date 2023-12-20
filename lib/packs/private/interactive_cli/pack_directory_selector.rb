# typed: strict

module Packs
  module Private
    module InteractiveCli
      class PackDirectorySelector
        extend T::Sig

        sig { params(prompt: TTY::Prompt, question_text: String).returns(String) }
        def self.select(prompt, question_text: 'Select a directory')
          directories = []

          Packs::Specification.config.pack_paths.each do |path|
            directories << Dir.glob(path).select { |f| File.directory? f }
          end

          prompt.select(
          question_text,
            directories,
            filter: true,
            per_page: 10,
            show_help: :always
        )
        end
      end
    end
  end
end
