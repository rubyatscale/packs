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
      @enforce_dependencies = T.let(@enforce_dependencies, T.nilable(T::Boolean))
      @documentation_link = T.let(documentation_link, T.nilable(String) )
    end

    sig { returns(T::Boolean) }
    def enforce_dependencies
      if !@enforce_dependencies.nil?
        @enforce_dependencies
      else
        true
      end
    end

    # Configure a link to show up for users who are looking for more info
    sig { returns(String) }
    def documentation_link
      "https://go/packwerk"
    end
  end

  class << self
    extend T::Sig

    sig { returns(Configuration) }
    def config
      @config = T.let(@config, T.nilable(Configuration))
      @config ||= Configuration.new
    end

    sig { params(blk: T.proc.params(arg0: Configuration).void).void }
    def configure(&blk) # rubocop:disable Lint/UnusedMethodArgument
      yield(config)
    end
  end
end
