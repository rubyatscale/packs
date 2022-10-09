# typed: strict

module UsePackwerk
  module Private
    module InteractiveCli
      module UseCases
        class AddDependency
          extend T::Sig
          extend T::Helpers
          include Interface

          sig { override.params(prompt: TTY::Prompt).void }
          def perform!(prompt)
            dependent_pack = PackSelector.single_pack_select(prompt, question_text: 'Please select the pack you are adding a dependency to.')
            dependency_pack = PackSelector.single_pack_select(prompt, question_text: "Please select the pack that #{dependent_pack.name} should depend on.")
            UsePackwerk.add_dependency!(
              pack_name: dependent_pack.name,
              dependency_name: dependency_pack.name
            )
          end

          sig { override.returns(String) }
          def user_facing_name
            'Add a dependency'
          end
        end
      end
    end
  end
end
