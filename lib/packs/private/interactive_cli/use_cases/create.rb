# typed: strict

module Packs
  module Private
    module InteractiveCli
      module UseCases
        class Create
          extend T::Sig
          extend T::Helpers
          include Interface

          sig { override.params(prompt: TTY::Prompt).void }
          def perform!(prompt)
            pack_name = prompt.ask('What should the name of your pack be?', value: 'packs/')
            team = TeamSelector.single_select(prompt)
            Packs.create_pack!(pack_name: pack_name, team: team)
          end

          sig { override.returns(String) }
          def user_facing_name
            'Create a new pack'
          end
        end
      end
    end
  end
end
