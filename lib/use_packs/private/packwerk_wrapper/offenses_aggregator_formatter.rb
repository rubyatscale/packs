# typed: strict

module UsePacks
  module Private
    module PackwerkWrapper
      #
      # This formatter simply collects offenses so we can feed them into other systems
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

        # T.untyped should be Packwerk::OffenseCollection, but is currently private until
        # https://github.com/Shopify/packwerk/pull/289 merges
        sig { override.params(offense_collection: T.untyped, for_files: T::Set[String]).returns(String) }
        def show_stale_violations(offense_collection, for_files)
          ''
        end

        sig { override.params(strict_mode_violations: T::Array[::Packwerk::ReferenceOffense]).returns(::String) }
        def show_strict_mode_violations(strict_mode_violations)
          ''
        end

        sig { override.returns(::String) }
        def identifier
          'offenses_aggregator'
        end
      end
    end
  end
end
