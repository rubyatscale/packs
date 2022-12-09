# typed: strict

module UsePacks
  module Private
    module InteractiveCli
      module UseCases
        class Move
          extend T::Sig
          extend T::Helpers
          include Interface

          sig { override.params(prompt: TTY::Prompt).void }
          def perform!(prompt)
            pack = PackSelector.single_pack_select(prompt, question_text: 'Please select a destination pack')
            raw_paths_relative_to_root = prompt.multiline('Please copy in a space or new line separated list of files or directories')
            paths_relative_to_root = T.let([], T::Array[String])
            raw_paths_relative_to_root.each do |path|
              paths_relative_to_root += path.chomp.split
            end

            UsePacks.move_to_pack!(
              pack_name: pack.name,
              paths_relative_to_root: paths_relative_to_root,
              per_file_processors: [UsePacks::RubocopPostProcessor.new, UsePacks::CodeOwnershipPostProcessor.new]
            )
          end

          sig { override.returns(String) }
          def user_facing_name
            'Move files'
          end
        end
      end
    end
  end
end
