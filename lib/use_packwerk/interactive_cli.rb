# typed: strict

# https://github.com/piotrmurach/tty-prompt
require "tty-prompt"

module UsePackwerk
  class InteractiveCli
    extend T::Sig

    class UseCase < T::Enum
      enums do
        Create = new
        Move = new
        AddDependency = new
        GetInfo = new
        ListTopDependencyViolations = new
      end
    end

    sig { void }
    def self.start!
      prompt = TTY::Prompt.new
      choice = prompt.select("Hello! What would you like to do?",
        cycle: true,
        per_page: 15) do |menu|
        menu.enum "."

        menu.choice "Create a new pack", UseCase::Create
        menu.choice "Move files", UseCase::Move
        menu.choice "Add a dependency", UseCase::AddDependency
        menu.choice "Get info on a pack", UseCase::GetInfo
        menu.choice "List a pack's top outgoing dependency violations", UseCase::ListTopDependencyViolations
      end

      process_choice_from_main_menu(prompt, choice)
    end

    sig { params(prompt: TTY::Prompt, choice: UseCase).void }
    def self.process_choice_from_main_menu(prompt, choice)
      case choice
      when UseCase::Create
        prompt.ok "TODO: #{choice}"
      when UseCase::Move
        prompt.ok "TODO: #{choice}"
      when UseCase::AddDependency
        prompt.ok "TODO: #{choice}"
      when UseCase::GetInfo
        prompt.ok "TODO: #{choice}"
        all_packs = "All packs!"
        packs = [all_packs, *ParsePackwerk.all.map(&:name)]
        help = "(Start typing, or use ↑/↓ arrow key. Press Space to select and Enter to finish)"
        selected = prompt.multi_select("What pack(s) would you like info on?", packs, filter: true, per_page: 10, help: help)
        prompt.ok("You selected: #{selected}")
        if selected.include?(all_packs)
          puts "There are #{ParsePackwerk.all.count} packs. That's cool."
        else
          selected.each do |pack|
            puts "======== Info about: #{pack}"
            puts T.must(ParsePackwerk.find(pack)).yml.read
            puts "\n"
          end
        end
      when UseCase::ListTopDependencyViolations
        packs = [all_packs, *ParsePackwerk.all.map(&:name)]
        # help = "(Start typing, or use ↑/↓ arrow key. Press Space to select and Enter to finish)"
        selected_pack = prompt.select("Select a pack", packs, filter: true, per_page: 10)
        limit = prompt.ask("Specify the limit of constants to analyze", default: 10, convert: :integer)
        prompt.ok({ selected_pack: selected_pack, limit: limit}.to_s)
        UsePackwerk.list_top_dependency_violations(
          pack_name: selected_pack,
          limit: limit
        )
      else
        T.absurd(choice)
      end
    end
  end
end
