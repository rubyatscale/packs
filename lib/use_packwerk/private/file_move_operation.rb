# typed: strict

module UsePackwerk
  module Private
    class FileMoveOperation < T::Struct
      extend T::Sig

      const :origin_pathname, Pathname
      const :destination_pathname, Pathname
      const :destination_pack, ParsePackwerk::Package

      sig { returns(ParsePackwerk::Package) }
      def origin_pack
        T.must(ParsePackwerk.package_from_path(origin_pathname))
      end

      sig { params(origin_pathname: Pathname, new_package_root: Pathname).returns(Pathname) }
      def self.destination_pathname_for_package_move(origin_pathname, new_package_root)
        origin_pack = T.must(ParsePackwerk.package_from_path(origin_pathname))

        new_implementation = nil
        if origin_pack.name == ParsePackwerk::ROOT_PACKAGE_NAME
          new_package_root.join(origin_pathname).cleanpath
        else
          Pathname.new(origin_pathname.to_s.gsub(origin_pack.name, new_package_root.to_s)).cleanpath
        end
      end

      sig { params(origin_pathname: Pathname).returns(Pathname) }
      def self.destination_pathname_for_new_public_api(origin_pathname)

        origin_pack = T.must(ParsePackwerk.package_from_path(origin_pathname))
        if origin_pack.name == ParsePackwerk::ROOT_PACKAGE_NAME
          filepath_without_pack_name = origin_pathname.to_s
        else
          filepath_without_pack_name = origin_pathname.to_s.gsub("#{origin_pack.name}/", '')
        end

        # We join the pack name with the rest of the path...
        path_parts = filepath_without_pack_name.split("/")
        Pathname.new(origin_pack.name).join(
          # ... keeping the "app" or "spec"
          T.must(path_parts[0]),
          # ... substituting "controllers," "services," etc. with "public"
          'public',
          # ... then the rest is the same
          T.must(path_parts[2..]).join("/")
        # and we take the cleanpath so `./app/...` becomes `app/...`
        ).cleanpath
      end

      sig { returns(FileMoveOperation) }
      def spec_file_move_operation
        # This could probably be implemented by some "strategy pattern" where different extension types are handled by different helpers
        # Such a thing could also include, for example, when moving a controller, moving its ERB view too.
        if origin_pathname.extname == '.rake'
          new_origin_pathname = origin_pathname.sub('/lib/', '/spec/lib/').sub(/^lib\//, 'spec/lib/').sub('.rake', '_spec.rb')
          new_destination_pathname = destination_pathname.sub('/lib/', '/spec/lib/').sub(/^lib\//, 'spec/lib/').sub('.rake', '_spec.rb')
        else
          new_origin_pathname = origin_pathname.sub('/app/', '/spec/').sub(/^app\//, 'spec/').sub('.rb', '_spec.rb')
          new_destination_pathname = destination_pathname.sub('/app/', '/spec/').sub(/^app\//, 'spec/').sub('.rb', '_spec.rb')
        end
        FileMoveOperation.new(
          origin_pathname: new_origin_pathname,
          destination_pathname: new_destination_pathname,
          destination_pack: destination_pack,
        )
      end

      private

      sig { params(path: Pathname).returns(FileMoveOperation) }
      def relative_to(path)
        FileMoveOperation.new(
          origin_pathname: origin_pathname.relative_path_from(path),
          destination_pathname: destination_pathname.relative_path_from(path),
          destination_pack: destination_pack,
        )
      end
    end
  end
end
