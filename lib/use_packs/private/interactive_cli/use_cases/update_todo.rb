# typed: strict

module UsePacks
  module Private
    module InteractiveCli
      module UseCases
        class UpdateTodo
          extend T::Sig
          extend T::Helpers
          include Interface

          sig { override.returns(String) }
          def user_facing_name
            'Run bin/packwerk update-todo'
          end

          sig { override.params(prompt: TTY::Prompt).void }
          def perform!(prompt)
            system('bin/packwerk update-todo')
          end
        end
      end
    end
  end
end
