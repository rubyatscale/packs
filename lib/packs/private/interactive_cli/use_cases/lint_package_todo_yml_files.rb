# typed: strict

module Packs
  module Private
    module InteractiveCli
      module UseCases
        class LintPackageYmlTodoFiles
          extend T::Sig
          extend T::Helpers
          include Interface

          sig { override.params(prompt: TTY::Prompt).void }
          def perform!(prompt)
            Private.lint_package_todo_yml_files!
          end

          sig { override.returns(String) }
          def user_facing_name
            'Lint .package_todo.yml files'
          end
        end
      end
    end
  end
end
