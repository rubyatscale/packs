# typed: strict

module UsePacks
  module Private
    module InteractiveCli
      module UseCases
        class Update
          extend T::Sig
          extend T::Helpers
          include Interface

          sig { override.returns(String) }
          def user_facing_name
            'Run bin/packwerk update'
          end

          sig { override.params(prompt: TTY::Prompt).void }
          def perform!(prompt)
            system('bin/packwerk update')
          end
        end
      end
    end
  end
end
