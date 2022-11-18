# typed: strict

module UsePackwerk
  module Private
    module InteractiveCli
      module UseCases
        class LintPackageYml
          extend T::Sig
          extend T::Helpers
          include Interface

          sig { override.params(prompt: TTY::Prompt).void }
          def perform!(prompt)
            packs = PackSelector.single_or_all_pack_multi_select(prompt, question_text: 'Please select the packs you want to lint package.yml files for')
            UsePackwerk.lint_package_yml_files!(packs)
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
