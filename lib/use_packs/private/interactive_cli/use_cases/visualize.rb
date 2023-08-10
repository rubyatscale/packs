# typed: strict

require 'visualize_packs'

module UsePacks
  module Private
    module InteractiveCli
      module UseCases
        class Visualize
          extend T::Sig
          extend T::Helpers
          include Interface

          sig { override.params(prompt: TTY::Prompt).void }
          def perform!(prompt)
            teams_or_packs = prompt.select('Do you want the graph nodes to be teams or packs?', %w[Teams Packs])

            if teams_or_packs == 'Teams'
              teams = TeamSelector.multi_select(prompt)
              VisualizePacks.team_graph!(teams)
            else
              by_name_or_by_owner = prompt.select('Do you select packs by name or by owner?', ['By name', 'By owner'])
              if by_name_or_by_owner == 'By owner'
                teams = TeamSelector.multi_select(prompt)
                selected_packs = Packs.all.select do |p|
                  teams.map(&:name).include?(CodeOwnership.for_package(p)&.name)
                end
              else
                selected_packs = PackSelector.single_or_all_pack_multi_select(prompt)
              end

              Private.visualize(packs: selected_packs)
            end
          end

          sig { override.returns(String) }
          def user_facing_name
            'Visualize pack relationships'
          end
        end
      end
    end
  end
end
