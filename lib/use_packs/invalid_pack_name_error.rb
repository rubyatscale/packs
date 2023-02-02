
module UsePacks
  class InvalidPackNameError < StandardError
    class << self
      def configured_pack_locations
        @configured_pack_locations ||= Packs.config.pack_paths
      end

      def permitted_pack_locations
        return @permitted_pack_locations if defined?(@permitted_pack_locations)

        if configured_pack_locations == %w[packs/* packs/*/*]
          @permitted_pack_locations = %w[gems/* components/* packs/* packs/*/*]
        else
          @permitted_pack_locations = configured_pack_locations
        end
      end

      def folders
        @folders ||= permitted_pack_locations.map { _1.scan(/\w*/).join }.uniq.sort
      end
    end

    DEFAULT_MESSAGE = <<~MSG.freeze
      UsePacks supports packages in directories based on configuration set in packs.yml.

      Currently permitted directories: \n\t#{folders.join("\n\t")}

      Please make sure to pass in the name of the pack including the full
      directory path, e.g. `#{folders.first}/my_pack`."
    MSG

    def initialize(msg = DEFAULT_MESSAGE)
      super
    end
  end

  PERMITTED_PACK_LOCATIONS = T.let(
    InvalidPackNameError.permitted_pack_locations,
    T::Array[String]
  )
end
