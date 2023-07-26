# typed: strict

# https://github.com/piotrmurach/tty-prompt
require 'tty-prompt'

require 'use_packs/private/interactive_cli/team_selector'
require 'use_packs/private/interactive_cli/pack_selector'
require 'use_packs/private/interactive_cli/file_selector'
require 'use_packs/private/interactive_cli/use_cases/interface'
require 'use_packs/private/interactive_cli/use_cases/create'
require 'use_packs/private/interactive_cli/use_cases/move'
require 'use_packs/private/interactive_cli/use_cases/add_dependency'
require 'use_packs/private/interactive_cli/use_cases/get_info'
require 'use_packs/private/interactive_cli/use_cases/query'
require 'use_packs/private/interactive_cli/use_cases/make_public'
require 'use_packs/private/interactive_cli/use_cases/move_to_parent'
require 'use_packs/private/interactive_cli/use_cases/rename'
require 'use_packs/private/interactive_cli/use_cases/check'
require 'use_packs/private/interactive_cli/use_cases/update'
require 'use_packs/private/interactive_cli/use_cases/validate'
require 'use_packs/private/interactive_cli/use_cases/lint_package_yml_files'
require 'use_packs/private/interactive_cli/use_cases/visualize'

module UsePacks
  module Private
    module InteractiveCli
      extend T::Sig

      sig { params(prompt: T.nilable(TTY::Prompt)).void }
      def self.start!(prompt: nil)
        prompt ||= TTY::Prompt.new(interrupt: lambda {
                                              puts "\n\nGoodbye! I hope you have a good day."
                                              exit 1 })
        help_text = '(Press ↑/↓ arrow to move, Enter to select and letters to filter)'
        choice = prompt.select('Hello! What would you like to do?',
          cycle: true,
          filter: true,
          help: help_text,
          show_help: :always,
          per_page: 15) do |menu|
          menu.enum '.'

          UseCases::Interface.all.each do |use_case|
            menu.choice use_case.user_facing_name, use_case
          end
        end

        choice.perform!(prompt)
      end
    end
  end
end
