# typed: strict

module UsePackwerk
  module Private
    module InteractiveCli
      module UseCases
        class RegenerateRubocopTodo
          extend T::Sig
          extend T::Helpers
          include Interface

          sig { override.params(prompt: TTY::Prompt).void }
          def perform!(prompt)
            packs = PackSelector.single_or_all_pack_multi_select(prompt, question_text: 'Please select the packs you want to regenerate `.rubocop_todo.yml` for')
            RuboCop::Packs.auto_generate_rubocop_todo(packs: packs)
          end

          sig { override.returns(String) }
          def user_facing_name
            'Regenerate packs/*/.rubocop_todo.yml for one or more packs'
          end
        end
      end
    end
  end
end
