# typed: strict

module UsePackwerk
  module Private
    module InteractiveCli
      module UseCases
        class MakePublic
          extend T::Sig
          extend T::Helpers
          include Interface

          sig { override.returns(String) }
          def user_facing_name
            'Make files or directories public'
          end

          sig { override.params(prompt: TTY::Prompt).void }
          def perform!(prompt)
            raw_paths_relative_to_root = prompt.multiline('Please copy in a space or new line separated list of files or directories to make public')
            paths_relative_to_root = T.let([], T::Array[String])
            raw_paths_relative_to_root.each do |path|
              paths_relative_to_root += path.chomp.split
            end

            UsePackwerk.make_public!(
              paths_relative_to_root: paths_relative_to_root,
              per_file_processors: [UsePackwerk::RubocopPostProcessor.new, UsePackwerk::CodeOwnershipPostProcessor.new]
            )
          end
        end
      end
    end
  end
end
