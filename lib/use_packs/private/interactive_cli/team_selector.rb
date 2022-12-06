# typed: strict

module UsePacks
  module Private
    module InteractiveCli
      class TeamSelector
        extend T::Sig

        sig { params(prompt: TTY::Prompt, question_text: String).returns(CodeTeams::Team) }
        def self.single_select(prompt, question_text: 'Please use space to select a team owner')
          teams = CodeTeams.all.sort_by(&:name).to_h { |t| [t.name, t] }
          prompt.select(
            question_text,
            teams,
            filter: true,
            per_page: 10,
            show_help: :always
          )
        end

        sig { params(prompt: TTY::Prompt, question_text: String).returns(T::Array[CodeTeams::Team]) }
        def self.multi_select(prompt, question_text: 'Please use space to select team owners')
          teams = CodeTeams.all.to_h { |t| [t.name, t] }
          # require 'pry'; binding.pry
          prompt.multi_select(
            question_text,
            teams,
            filter: true,
            per_page: 10,
            show_help: :always
          )
        end
      end
    end
  end
end
