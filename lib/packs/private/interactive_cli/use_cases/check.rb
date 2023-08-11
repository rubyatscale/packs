# typed: strict

module Packs
  module Private
    module InteractiveCli
      module UseCases
        class Check
          extend T::Sig
          extend T::Helpers
          include Interface

          sig { override.returns(String) }
          def user_facing_name
            'Run bin/packs check'
          end

          sig { override.params(prompt: TTY::Prompt).void }
          def perform!(prompt)
            Private.exit_with(Packs.check([]))
          end
        end
      end
    end
  end
end
