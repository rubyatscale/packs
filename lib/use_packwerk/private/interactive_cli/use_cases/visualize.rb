# typed: strict

require 'visualize_packwerk'

module UsePackwerk
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
              VisualizePackwerk.team_graph!(teams)
            else
              by_name_or_by_owner = prompt.select('Do you select packs by name or by owner?', ['By name', 'By owner'])
              if by_name_or_by_owner == 'By owner'
                teams = TeamSelector.multi_select(prompt)
                selected_packs = ParsePackwerk.all.select do |p|
                  teams.map(&:name).include?(CodeOwnership.for_package(p)&.name)
                end
              else
                selected_packs = PackSelector.single_or_all_pack_multi_select(prompt)
              end

              VisualizePackwerk.package_graph!(selected_packs)
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
