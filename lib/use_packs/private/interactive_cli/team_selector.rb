# typed: strict

module UsePacks
  module Private
    module InteractiveCli
      class TeamSelector
        extend T::Sig

        sig { params(prompt: TTY::Prompt, question_text: String).returns(CodeTeams::Team) }
        def self.single_select(prompt, question_text: 'Please use space to select a team owner')
          teams = CodeTeams.all.sort_by(&:name).to_h { |t| [t.name, t] }

          team_selection = T.let(prompt.select(
            question_text,
            teams,
            filter: true,
            per_page: 10,
            show_help: :always
          ), T.nilable(CodeTeams::Team))

          while team_selection.nil?
            prompt.error(
              'No owners were selected, please select an owner using the space key before pressing enter.'
            )

            team_selection = single_select(prompt, question_text: question_text)
          end

          team_selection
        end

        sig { params(prompt: TTY::Prompt, question_text: String).returns(T::Array[CodeTeams::Team]) }
        def self.multi_select(prompt, question_text: 'Please use space to select team owners')
          teams = CodeTeams.all.to_h { |t| [t.name, t] }

          team_selection = T.let(prompt.multi_select(
            question_text,
            teams,
            filter: true,
            per_page: 10,
            show_help: :always
          ), T::Array[CodeTeams::Team])

          while team_selection.empty?
            prompt.error(
              'No owners were selected, please select one or more owners using the space key before pressing enter.'
            )

            team_selection = multi_select(prompt, question_text: question_text)
          end

          team_selection
        end
      end
    end
  end
end
