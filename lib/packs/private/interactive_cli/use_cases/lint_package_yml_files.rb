# typed: strict

module Packs
  module Private
    module InteractiveCli
      module UseCases
        class LintPackageYmlFiles
          extend T::Sig
          extend T::Helpers
          include Interface

          sig { override.params(prompt: TTY::Prompt).void }
          def perform!(prompt)
            Packs.lint_package_yml_files!
          end

          sig { override.returns(String) }
          def user_facing_name
            'Lint packs/*/package.yml for one or more packs'
          end
        end
      end
    end
  end
end
