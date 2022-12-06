# typed: strict

require 'visualize_packwerk'

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
              VisualizePackwerk.team_graph!(teams)
            else
              by_name_or_by_owner = prompt.select(
                'Do you select packs by name or by owner?',
                ['By name', 'By owner']
              )

              selected_packs = get_selected_packs(prompt, select_by: by_name_or_by_owner)

              while selected_packs.empty?
                prompt.error(
                  'No owners were selected, please select an owner using the space key before pressing enter.'
                )

                selected_packs = get_selected_packs(prompt, select_by: by_name_or_by_owner)
              end

              VisualizePackwerk.package_graph!(selected_packs)
            end
          end

          sig { params(prompt: TTY::Prompt, select_by: String).returns(T::Array[ParsePackwerk::Package]) }
          def get_selected_packs(prompt, select_by:)
            if select_by == 'By owner'
              teams = TeamSelector.multi_select(prompt)

              ParsePackwerk.all.select do |p|
                teams.map(&:name).include?(CodeOwnership.for_package(p)&.name)
              end
            else
              PackSelector.single_or_all_pack_multi_select(prompt)
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
