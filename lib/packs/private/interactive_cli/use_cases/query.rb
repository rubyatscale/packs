# typed: strict

module Packs
  module Private
    module InteractiveCli
      module UseCases
        #
        # We have not yet pulled QueryPackwerk into open source, so we cannot include it in this CLI yet
        #
        class Query
          extend T::Sig
          extend T::Helpers
          include Interface

          sig { override.returns(String) }
          def user_facing_name
            'Query violations about a pack'
          end

          sig { override.params(prompt: TTY::Prompt).void }
          def perform!(prompt)
            selection = prompt.select('For one pack or all packs?', ['One pack', 'All packs'])
            if selection == 'All packs'
              # Probably should just make `list_top_violations` take in an array of things
              # Better yet we might just want to replace these functions with `QueryPackwerk`
              selected_pack = nil
            else
              selected_pack = PackSelector.single_pack_select(prompt).name
            end

            limit = prompt.ask('Specify the limit of constants to analyze', default: 10, convert: :integer)

            selection = prompt.select('Are you interested in dependency, or privacy violations?', %w[Dependency Privacy Architecture], default: 'Privacy')

            Packs.list_top_violations(
              type: selection.downcase,
              pack_name: selected_pack,
              limit: limit
            )
          end
        end
      end
    end
  end
end
