# typed: strict

module UsePacks
  module Private
    module InteractiveCli
      module UseCases
        class Check
          extend T::Sig
          extend T::Helpers
          include Interface

          sig { override.returns(String) }
          def user_facing_name
            'Run bin/packwerk check'
          end

          sig { override.params(prompt: TTY::Prompt).void }
          def perform!(prompt)
            system('bin/packwerk check')
          end
        end
      end
    end
  end
end
