# typed: strict

module UsePacks
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
            paths_relative_to_root = FileSelector.select(prompt)

            UsePacks.make_public!(
              paths_relative_to_root: paths_relative_to_root,
              per_file_processors: [UsePacks::RubocopPostProcessor.new, UsePacks::CodeOwnershipPostProcessor.new]
            )
          end
        end
      end
    end
  end
end
