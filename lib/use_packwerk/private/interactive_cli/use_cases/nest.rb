# typed: strict

module UsePackwerk
  module Private
    module InteractiveCli
      module UseCases
        class Nest
          extend T::Sig
          extend T::Helpers
          include Interface

          sig { override.params(prompt: TTY::Prompt).void }
          def perform!(prompt)
            child_pack = PackSelector.single_pack_select(prompt, question_text: 'Please select the pack that will be nested')
            parent_pack = PackSelector.single_pack_select(prompt, question_text: 'Please select the pack that will be the parent')
            UsePackwerk.move_to_parent!(
              parent_name: parent_pack.name,
              pack_name: child_pack.name,
              per_file_processors: [UsePackwerk::RubocopPostProcessor.new, UsePackwerk::CodeOwnershipPostProcessor.new]
            )
          end

          sig { override.returns(String) }
          def user_facing_name
            'Nest one pack under another'
          end
        end
      end
    end
  end
end
