# typed: strict

module Packs
  module Private
    module InteractiveCli
      class FileSelector
        extend T::Sig

        sig { params(prompt: TTY::Prompt).returns(T::Array[String]) }
        def self.select(prompt)
          prompt.on(:keytab) do
            raw_paths_relative_to_root = prompt.multiline('Please copy in a space or new line separated list of files or directories')
            paths_relative_to_root = T.let([], T::Array[String])
            raw_paths_relative_to_root.each do |path|
              paths_relative_to_root += path.chomp.split
            end

            return paths_relative_to_root
          end

          [prompt.ask('Please input a file or directory to move (press tab to enter multiline mode)')]
        end
      end
    end
  end
end
