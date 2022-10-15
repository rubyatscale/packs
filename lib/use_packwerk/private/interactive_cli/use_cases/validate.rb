# typed: strict

module UsePackwerk
  module Private
    module InteractiveCli
      module UseCases
        class Validate
          extend T::Sig
          extend T::Helpers
          include Interface

          sig { override.returns(String) }
          def user_facing_name
            'Run bin/packwerk validate (detects cycles)'
          end

          sig { override.params(prompt: TTY::Prompt).void }
          def perform!(prompt)
            system('bin/packwerk validate')
          end
        end
      end
    end
  end
end
