# typed: strict

module Packs
  module Private
    module InteractiveCli
      module UseCases
        class MovePack
          extend T::Sig
          extend T::Helpers
          include Interface

          sig { override.params(prompt: TTY::Prompt).void }
          def perform!(prompt)
            move_type = prompt.select(
              'What do you want to do?',
              {
                'Move a child pack to be nested under a parent pack' => :move_to_parent,
                'Move a pack to a folder that is not a pack' =>
                 :move_to_folder
              }
            )

            case move_type
            when :move_to_parent
              child_pack = PackSelector.single_pack_select(prompt, question_text: 'Please select the child pack that will be nested')
              parent_pack = PackSelector.single_pack_select(prompt, question_text: 'Please select the pack that will be the parent')

              Packs.move_to_parent!(
                parent_name: parent_pack.name,
                pack_name: child_pack.name,
                per_file_processors: [Packs::RubocopPostProcessor.new, Packs::CodeOwnershipPostProcessor.new]
              )
            when :move_to_folder
              pack = PackSelector.single_pack_select(prompt, question_text: 'Please select the pack that you want to move')
              destination = PackDirectorySelector.select(prompt, question_text: "What directory do you want to move #{pack.name} to?")

              if Packs.find(destination)
                use_move_to_parent = prompt.select(
                  "The directory #{destination} is a pack. Add #{pack.last_name} as a dependency?",
                  { 'Yes' => true, 'No' => false }
                )

                if use_move_to_parent
                  Packs.move_to_parent!(
                    parent_name: destination,
                    pack_name: pack.name,
                    per_file_processors: [Packs::RubocopPostProcessor.new, Packs::CodeOwnershipPostProcessor.new]
                  )

                  return
                end
              end

              Packs.move_to_folder!(
                pack_name: pack.name,
                destination: destination,
                per_file_processors: [Packs::RubocopPostProcessor.new, Packs::CodeOwnershipPostProcessor.new]
              )
            end
          end

          sig { override.returns(String) }
          def user_facing_name
            'Move a pack'
          end
        end
      end
    end
  end
end
