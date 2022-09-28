# typed: strict

module UsePackwerk
  module Private
    module PackRelationshipAnalyzer
      extend T::Sig

      sig do
        params(
          pack_name: T.nilable(String),
          limit: Integer
        ).void
      end
      def self.list_top_privacy_violations(pack_name, limit)
        all_packages = ParsePackwerk.all
        if pack_name.nil?
          pack_specific_content = <<~PACK_CONTENT
            You are listing top #{limit} privacy violations for all packs. See #{UsePackwerk.config.documentation_link} for other utilities!
            Pass in a limit to display more or less, e.g. `bin/use_packwerk list_top_privacy_violations #{pack_name} -l 1000`

            This script is intended to help you find which of YOUR pack's private classes, constants, or modules other packs are using the most.
            Anything not in pack_name/app/public is considered private API.
          PACK_CONTENT

          to_package_names = all_packages.map(&:name)
        else
          pack_name = Private.clean_pack_name(pack_name)
          package = all_packages.find { |package| package.name == pack_name }
          if package.nil?
            raise StandardError, "Can not find package with name #{pack_name}. Make sure the argument is of the form `packs/my_pack/`"
          end

          pack_specific_content = <<~PACK_CONTENT
            You are listing top #{limit} privacy violations for #{pack_name}. See #{UsePackwerk.config.documentation_link} for other utilities!
            Pass in a limit to display more or less, e.g. `bin/use_packwerk list_top_privacy_violations #{pack_name} -l 1000`

            This script is intended to help you find which of YOUR pack's private classes, constants, or modules other packs are using the most.
            Anything not in #{pack_name}/app/public is considered private API.
          PACK_CONTENT

          to_package_names = [pack_name]
        end

        violations_by_count = {}
        total_pack_violation_count = 0

        Logging.section('👋 Hi there') do
          intro = <<~INTRO
            #{pack_specific_content}

            When using this script, ask yourself some questions like:
            - What do I want to support?
            - What do I *not* want to support?
            - What is considered simply an implementation detail, and what is essential to the behavior of my pack?
            - What is a simple, minimialistic API for clients to engage with the behavior of your pack?
            - How do I ensure my public API is not coupled to specific client's use cases?

            Looking at privacy violations can help guide the development of your public API, but it is just the beginning!

            The script will output in the following format:

            SomeConstant # This is the name of a class, constant, or module defined in your pack, outside of app/public
              - Total Count: 5 # This is the total number of uses of this outside your pack
              - By package: # This is a breakdown of the use of this constant by other packages
                # This is the number of files in this pack that this constant is used.
                # Check `packs/other_pack_a/deprecated_references.yml` under the '#{pack_name}'.'SomeConstant' key to see where this constant is used
                - packs/other_pack_a: 3
                - packs/other_pack_b: 2
            SomeClass # This is the second most violated class, constant, or module defined in your pack
              - Total Count: 2
              - By package:
                - packs/other_pack_a: 1
                - packs/other_pack_b: 1

            Lastly, remember you can use `bin/use_packwerk make_public #{pack_name}/path/to/file.rb` to make your class, constant, or module public API.
          INTRO
          Logging.print_bold_green(intro)
        end

        # TODO: This is a copy of the implementation below. We may want to refactor out this implementation detail before making changes that apply to both.
        all_packages.each do |client_package|
          PackageProtections::ProtectedPackage.from(client_package).violations.select(&:privacy?).each do |violation|
            next unless to_package_names.include?(violation.to_package_name)

            if pack_name.nil?
              violated_symbol = "#{violation.class_name} (#{violation.to_package_name})"
            else
              violated_symbol = "#{violation.class_name}"
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

      sig do
        params(
          pack_name: T.nilable(String),
          limit: Integer
        ).void
      end
      def self.list_top_dependency_violations(pack_name, limit)
        all_packages = ParsePackwerk.all

        if pack_name.nil?
          pack_specific_content = <<~PACK_CONTENT
            You are listing top #{limit} dependency violations for all packs. See #{UsePackwerk.config.documentation_link} for other utilities!
            Pass in a limit to display more or less, e.g. `use_packwerk list_top_dependency_violations #{pack_name} -l 1000`

            This script is intended to help you find which of YOUR pack's private classes, constants, or modules other packs are using the most.
            Anything not in pack_name/app/public is considered private API.
          PACK_CONTENT

          to_package_names = all_packages.map(&:name)
        else
          pack_name = Private.clean_pack_name(pack_name)
          package = all_packages.find { |package| package.name == pack_name }
          if package.nil?
            raise StandardError, "Can not find package with name #{pack_name}. Make sure the argument is of the form `packs/my_pack/`"
          end

          pack_specific_content = <<~PACK_CONTENT
            You are listing top #{limit} dependency violations for #{pack_name}. See #{UsePackwerk.config.documentation_link} for other utilities!
            Pass in a limit to display more or less, e.g. `bin/use_packwerk list_top_dependency_violations #{pack_name} -l 1000`

            This script is intended to help you find which of YOUR pack's private classes, constants, or modules other packs are using the most.
            Anything not in #{pack_name}/app/public is considered private API.
          PACK_CONTENT

          to_package_names = [pack_name]
        end

        violations_by_count = {}
        total_pack_violation_count = 0

        Logging.section('👋 Hi there') do
          intro = <<~INTRO
            #{pack_specific_content}

            When using this script, ask yourself some questions like:
            - What do I want to support?
            - What do I *not* want to support?
            - Which direction should a dependency go?
            - What packs should depend on you, and what packs should not depend on you?
            - Would it be simpler if other packs only depended on interfaces to your pack rather than implementation?

            Looking at dependency violations can help guide the development of your public API, but it is just the beginning!

            The script will output in the following format:

            SomeConstant # This is the name of a class, constant, or module defined in your pack, outside of app/public
              - Total Count: 5 # This is the total number of unstated uses of this outside your pack
              - By package: # This is a breakdown of the use of this constant by other packages
                # This is the number of files in this pack that this constant is used.
                # Check `packs/other_pack_a/deprecated_references.yml` under the '#{pack_name}'.'SomeConstant' key to see where this constant is used
                - packs/other_pack_a: 3
                - packs/other_pack_b: 2
            SomeClass # This is the second most violated class, constant, or module defined in your pack
              - Total Count: 2
              - By package:
                - packs/other_pack_a: 1
                - packs/other_pack_b: 1
          INTRO
          Logging.print_bold_green(intro)
        end

        # TODO: This is a copy of the implementation above. We may want to refactor out this implementation detail before making changes that apply to both.
        all_packages.each do |client_package|
          PackageProtections::ProtectedPackage.from(client_package).violations.select(&:dependency?).each do |violation|
            next unless to_package_names.include?(violation.to_package_name)

            if pack_name.nil?
              violated_symbol = "#{violation.class_name} (#{violation.to_package_name})"
            else
              violated_symbol = "#{violation.class_name}"
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
