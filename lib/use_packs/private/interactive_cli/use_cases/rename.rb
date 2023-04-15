# typed: strict

module UsePacks
  module Private
    module InteractiveCli
      module UseCases
        class Rename
          extend T::Sig
          extend T::Helpers
          include Interface

          sig { override.returns(String) }
          def user_facing_name
            'Rename a pack'
          end

          sig { override.params(prompt: TTY::Prompt).void }
          def perform!(prompt)
            prompt.warn(Private.rename_pack)
          end
        end
      end
    end
  end
end
