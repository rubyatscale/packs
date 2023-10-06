# typed: strict

module Packs
  module Private
    module InteractiveCli
      module UseCases
        class GetInfo
          extend T::Sig
          extend T::Helpers
          include Interface

          sig { override.returns(String) }
          def user_facing_name
            'Get info on one or more packs'
          end

          sig { override.params(prompt: TTY::Prompt).void }
          def perform!(prompt)
            team_or_pack = prompt.select('Do you want info by team or by pack?', ['By team', 'By pack'])
            if team_or_pack == 'By team'
              teams = TeamSelector.multi_select(prompt)
              selected_packs = Packs.all.select do |p|
                teams.map(&:name).include?(CodeOwnership.for_package(p)&.name)
              end
            else
              selected_packs = PackSelector.single_or_all_pack_multi_select(prompt, question_text: 'What pack(s) would you like info on?')
            end

            format = prompt.select('What output format do you want?', %w[Detail CSV])

            types = prompt.multi_select(
              'What violation types do you want stats for?',
              %w[Privacy Dependency Architecture]
            )

            include_date = !prompt.no?('Should the current date be included in the report?')

            puts "You've selected #{selected_packs.count} packs. Wow! Here's all the info."

            Private.get_info(
              packs: selected_packs,
              format: format.downcase.to_sym,
              types: types.map(&:downcase).map(&:to_sym),
              include_date: include_date
            )
          end
        end
      end
    end
  end
end
