# typed: strict

module Packs
  module Private
    module PackRelationshipAnalyzer
      extend T::Sig

      sig do
        params(
          type: String,
          pack_name: T.nilable(String),
          limit: Integer
        ).void
      end
      def self.list_top_violations(type, pack_name, limit)
        all_packages = ParsePackwerk.all

        if pack_name.nil?
          to_package_names = all_packages.map(&:name)
        else
          pack_name = Private.clean_pack_name(pack_name)
          package = all_packages.find { |p| p.name == pack_name }
          if package.nil?
            raise StandardError, "Can not find package with name #{pack_name}. Make sure the argument is of the form `packs/my_pack/`"
          end

          to_package_names = [pack_name]
        end

        Logging.section('👋 Hi there') do
          intro = Packs.config.user_event_logger.before_list_top_violations(type, pack_name, limit)
          Logging.print_bold_green(intro)
        end

        violations_by_count = {}
        total_pack_violation_count = 0

        all_packages.each do |client_package|
          client_package.violations.select { _1.type == type }.each do |violation|
            next unless to_package_names.include?(violation.to_package_name)

            if pack_name.nil?
              violated_symbol = "#{violation.class_name} (#{violation.to_package_name})"
            else
              violated_symbol = violation.class_name
            end
            violations_by_count[violated_symbol] ||= {}
            violations_by_count[violated_symbol][:total_count] ||= 0
            violations_by_count[violated_symbol][:by_package] ||= {}
            violations_by_count[violated_symbol][:by_package][client_package.name] ||= 0
            violations_by_count[violated_symbol][:total_count] += violation.files.count
            violations_by_count[violated_symbol][:by_package][client_package.name] += violation.files.count
            total_pack_violation_count += violation.files.count
          end
        end

        Logging.print("Total Count: #{total_pack_violation_count}")

        sorted_violations = violations_by_count.sort_by { |violated_symbol, count_info| [-count_info[:total_count], violated_symbol] }
        sorted_violations.first(limit).each do |violated_symbol, count_info|
          percentage_of_total = (count_info[:total_count] * 100.0 / total_pack_violation_count).round(2)
          Logging.print(violated_symbol)
          Logging.print("  - Total Count: #{count_info[:total_count]} (#{percentage_of_total}% of total)")
          Logging.print('  - By package:')
          count_info[:by_package].sort_by { |client_package_name, count| [-count, client_package_name] }.each do |client_package_name, count|
            Logging.print("    - #{client_package_name}: #{count}")
          end
        end
      end
    end
  end
end
