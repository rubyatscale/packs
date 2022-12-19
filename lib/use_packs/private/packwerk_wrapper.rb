# typed: strict

require 'packwerk'
require 'use_packs/private/packwerk_wrapper/offenses_aggregator_formatter'

module UsePacks
  module Private
    module PackwerkWrapper
      extend T::Sig

      #
      # execute_command is like `run` except it does not `exit`
      #
      sig { params(argv: T.untyped, formatter: T.nilable(Packwerk::OffensesFormatter)).void }
      def self.packwerk_cli_execute_safely(argv, formatter = nil)
        with_safe_exit_if_no_files_found do
          packwerk_cli(formatter).execute_command(argv)
        end
      end

      sig { params(block: T.proc.returns(T.untyped)).void }
      def self.with_safe_exit_if_no_files_found(&block)
        block.call
      rescue SystemExit => e
        # Packwerk should probably exit positively here rather than raising an error -- there should be no
        # errors if the user has excluded all files being checked.
        unless e.message == 'No files found or given. Specify files or check the include and exclude glob in the config file.'
          raise
        end
      end

      sig { params(formatter: T.nilable(Packwerk::OffensesFormatter)).returns(Packwerk::Cli) }
      def self.packwerk_cli(formatter)
        # This is mostly copied from exe/packwerk within the packwerk gem, but we use our own formatters
        # Note that packwerk does not allow you to pass in your own progress formatter currently
        ENV['RAILS_ENV'] = 'test'

        style = Packwerk::OutputStyles::Coloured.new
        Packwerk::Cli.new(style: style, offenses_formatter: formatter)
      end

      sig { params(files: T::Array[String]).returns(T::Array[Packwerk::ReferenceOffense]) }
      def self.get_offenses_for_files(files)
        formatter = OffensesAggregatorFormatter.new
        packwerk_cli_execute_safely(['check', *files], formatter)
        formatter.aggregated_offenses.compact
      end

      sig { params(files: T::Array[String]).returns(T::Array[Packwerk::ReferenceOffense]) }
      def self.get_offenses_for_files_by_package(files)
        packages = package_names_for_files(files)
        argv = ['check', '--packages', packages.join(',')]
        formatter = OffensesAggregatorFormatter.new
        packwerk_cli_execute_safely(argv, formatter)
        formatter.aggregated_offenses.compact
      end

      sig { params(files: T::Array[String]).returns(T::Array[String]) }
      def self.package_names_for_files(files)
        files.map { |f| ParsePackwerk.package_from_path(f).name }.compact.uniq
      end
    end
  end
end
