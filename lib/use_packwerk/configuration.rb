# typed: strict

require 'use_packwerk/user_event_logger'
require 'use_packwerk/default_user_event_logger'

module UsePackwerk
  class Configuration
    extend T::Sig

    sig { params(enforce_dependencies: T::Boolean).void }
    attr_writer :enforce_dependencies

    sig { returns(UserEventLogger) }
    attr_accessor :user_event_logger

    OnDeprecatedReferencesLintFailure = T.type_alias do
      T.proc.params(output: String).void
    end

    sig { returns(OnDeprecatedReferencesLintFailure) }
    attr_accessor :on_deprecated_references_lint_failure

    sig { void }
    def initialize
      @enforce_dependencies = T.let(default_enforce_dependencies, T::Boolean)
      @user_event_logger = T.let(DefaultUserEventLogger.new, UserEventLogger)
      @on_deprecated_references_lint_failure = T.let(-> (output) {}, OnDeprecatedReferencesLintFailure)
    end

    sig { returns(T::Boolean) }
    def enforce_dependencies
      @enforce_dependencies
    end

    sig { void }
    def bust_cache!
      @enforce_dependencies = default_enforce_dependencies
    end

    sig { returns(T::Boolean) }
    def default_enforce_dependencies
      true
    end
  end

  class << self
    extend T::Sig

    sig { returns(Configuration) }
    def config
      Private.load_client_configuration
      @config = T.let(@config, T.nilable(Configuration))
      @config ||= Configuration.new
    end

    sig { params(blk: T.proc.params(arg0: Configuration).void).void }
    def configure(&blk)
      yield(config)
    end
  end
end
