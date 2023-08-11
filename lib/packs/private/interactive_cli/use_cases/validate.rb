# typed: strict

module Packs
  module Private
    module InteractiveCli
      module UseCases
        class Validate
          extend T::Sig
          extend T::Helpers
          include Interface

          sig { override.returns(String) }
          def user_facing_name
            'Run bin/packs validate (detects cycles)'
          end

          sig { override.params(prompt: TTY::Prompt).void }
          def perform!(prompt)
            Private.exit_with(Packs.validate)
          end
        end
      end
    end
  end
end
