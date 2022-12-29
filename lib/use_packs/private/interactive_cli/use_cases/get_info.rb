# typed: strict

module UsePacks
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

            inbound_violations = {}
            outbound_violations = {}
            ParsePackwerk.all.each do |p|
              p.violations.each do |violation|
                outbound_violations[p.name] ||= []
                outbound_violations[p.name] << violation
                inbound_violations[violation.to_package_name] ||= []
                inbound_violations[violation.to_package_name] << violation
              end
            end

            puts "You've selected #{selected_packs.count} packs. Wow! Here's all the info."
            all_inbound = T.let([], T::Array[ParsePackwerk::Violation])
            all_outbound = T.let([], T::Array[ParsePackwerk::Violation])
            selected_packs.each do |pack|
              all_inbound += inbound_violations[pack.name] || []
              all_outbound += outbound_violations[pack.name] || []
            end

            puts "There are #{all_inbound.select(&:privacy?).sum { |v| v.files.count }} total inbound privacy violations"
            puts "There are #{all_inbound.select(&:dependency?).sum { |v| v.files.count }} total inbound dependency violations"
            puts "There are #{all_outbound.select(&:privacy?).sum { |v| v.files.count }} total outbound privacy violations"
            puts "There are #{all_outbound.select(&:dependency?).sum { |v| v.files.count }} total outbound dependency violations"

            selected_packs.sort_by { |p| -p.relative_path.glob('**/*.rb').count }.each do |pack|
              puts "\n=========== Info about: #{pack.name}"
              
              owner = CodeOwnership.for_package(pack)
              puts "Owned by: #{owner.nil? ? 'No one' : owner.name}"
              puts "Size: #{pack.relative_path.glob('**/*.rb').count} ruby files"
              puts "Public API: #{pack.relative_path.join('app/public')}"

              inbound_for_pack = inbound_violations[pack.name] || []
              outbound_for_pack = outbound_violations[pack.name] || []
              puts "There are #{inbound_for_pack.select(&:privacy?).sum { |v| v.files.count }} inbound privacy violations"
              puts "There are #{inbound_for_pack.flatten.select(&:dependency?).sum { |v| v.files.count }} inbound dependency violations"
              puts "There are #{outbound_for_pack.select(&:privacy?).sum { |v| v.files.count }} outbound privacy violations"
              puts "There are #{outbound_for_pack.flatten.select(&:dependency?).sum { |v| v.files.count }} outbound dependency violations"
            end
          end
        end
      end
    end
  end
end
