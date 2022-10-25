# typed: strict

module UsePackwerk
  module Private
    module PackwerkWrapper
      #
      # This formatter simply collects offenses so we can feed them into PackageProtections
      #
      class OffensesAggregatorFormatter
        extend T::Sig
        include Packwerk::OffensesFormatter

        sig { returns(T::Array[Packwerk::ReferenceOffense]) }
        attr_reader :aggregated_offenses

        sig { void }
        def initialize
          @aggregated_offenses = T.let([], T::Array[Packwerk::ReferenceOffense])
        end

        sig { override.params(offenses: T::Array[T.nilable(Packwerk::Offense)]).returns(String) }
        def show_offenses(offenses)
          @aggregated_offenses = T.unsafe(offenses)
          ''
        end

        sig { override.params(offense_collection: Packwerk::OffenseCollection, for_files: T::Set[String]).returns(String) }
        def show_stale_violations(offense_collection, for_files)
          ''
        end
      end
    end
  end
end
