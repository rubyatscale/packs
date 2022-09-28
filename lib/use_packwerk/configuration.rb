# typed: strict

module UsePackwerk
  class Configuration
    extend T::Sig

    sig { params(enforce_dependencies: T::Boolean).void }
    attr_writer :enforce_dependencies

    sig { params(documentation_link: String).void }
    attr_writer :documentation_link

    sig { void }
    def initialize
      @enforce_dependencies = T.let(default_enforce_dependencies, T::Boolean)
      @documentation_link = T.let(default_documentation_link, String)
    end

    sig { returns(T::Boolean) }
    def enforce_dependencies
      @enforce_dependencies
    end

    # Configure a link to show up for users who are looking for more info
    sig { returns(String) }
    def documentation_link
      @documentation_link
    end

    sig { void }
    def bust_cache!
      @enforce_dependencies = default_enforce_dependencies
      @documentation_link = default_documentation_link
    end

    sig { returns(String) }
    def default_documentation_link
      'https://go/packwerk'
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
