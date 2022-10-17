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
            packs.each do |p|
              new_package = ParsePackwerk::Package.new(
                name: p.name,
                enforce_privacy: p.enforce_privacy,
                enforce_dependencies: p.enforce_dependencies,
                dependencies: p.dependencies.uniq.sort,
                metadata: p.metadata
              )
              ParsePackwerk.write_package_yml!(new_package)
            end
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
