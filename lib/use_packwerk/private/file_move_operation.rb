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
        parts = origin_pathname.to_s.split('/')
        toplevel_directory = parts[0]

        case toplevel_directory.to_s
        # This allows us to move files from monolith to packs
        when 'app', 'spec', 'lib'
          new_package_root.join(origin_pathname).cleanpath
        # This allows us to move files from packs to packs
        when *PERMITTED_PACK_LOCATIONS # parts looks like ['packs', 'organisms', 'app', 'services', 'bird_like', 'eagle.rb']
          new_package_root.join(T.must(parts[2..]).join('/')).cleanpath
        else
          raise StandardError.new("Don't know how to find destination path for #{origin_pathname.inspect}")
        end
      end

      sig { params(origin_pathname: Pathname).returns(Pathname) }
      def self.destination_pathname_for_new_public_api(origin_pathname)
        parts = origin_pathname.to_s.split('/')
        toplevel_directory = Pathname.new(parts[0])

        case toplevel_directory.to_s
        # This allows us to make API in the monolith public
        when 'app', 'spec'
          toplevel_directory.join('public').join(T.must(parts[2..]).join('/')).cleanpath
        # This allows us to make API in existing packs public
        when *PERMITTED_PACK_LOCATIONS # parts looks like ['packs', 'organisms', 'app', 'services', 'bird_like', 'eagle.rb']
          pack_name = Pathname.new(parts[1])
          toplevel_directory.join(pack_name).join('app/public').join(T.must(parts[4..]).join('/')).cleanpath
        else
          raise StandardError.new("Don't know how to find destination path for #{origin_pathname.inspect}")
        end
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
