# typed: strict

module Packs
  module Private
    class FileMoveOperation < T::Struct
      extend T::Sig

      const :origin_pathname, Pathname
      const :destination_pathname, Pathname
      const :destination_pack, ParsePackwerk::Package

      sig { returns(T.nilable(Packs::Pack)) }
      def origin_pack
        self.class.get_origin_pack(origin_pathname)
      end

      sig { params(origin_pathname: Pathname).returns(T.nilable(Packs::Pack)) }
      def self.get_origin_pack(origin_pathname)
        Packs.for_file(origin_pathname)
      end

      sig { params(origin_pathname: Pathname, new_package_root: Pathname).returns(Pathname) }
      def self.destination_pathname_for_package_move(origin_pathname, new_package_root)
        origin_pack = get_origin_pack(origin_pathname)
        if origin_pack
          Pathname.new(origin_pathname.to_s.gsub(origin_pack.name, new_package_root.to_s)).cleanpath
        else
          new_package_root.join(origin_pathname).cleanpath
        end
      end

      sig { params(origin_pathname: Pathname).returns(Pathname) }
      def self.destination_pathname_for_new_public_api(origin_pathname)
        origin_pack = get_origin_pack(origin_pathname)
        if origin_pack
          filepath_without_pack_name = origin_pathname.to_s.gsub("#{origin_pack.name}/", '')
        else
          filepath_without_pack_name = origin_pathname.to_s
        end

        # We join the pack name with the rest of the path...
        path_parts = filepath_without_pack_name.split('/')
        Pathname.new(origin_pack&.name || ParsePackwerk::ROOT_PACKAGE_NAME).join(
          # ... keeping the "app" or "spec"
          T.must(path_parts[0]),
          # ... substituting "controllers," "services," etc. with "public"
          'public',
          # ... then the rest is the same
          T.must(path_parts[2..]).join('/')
          # and we take the cleanpath so `./app/...` becomes `app/...`
        ).cleanpath
      end

      sig { returns(FileMoveOperation) }
      def spec_file_move_operation
        # This could probably be implemented by some "strategy pattern" where different extension types are handled by different helpers
        # Such a thing could also include, for example, when moving a controller, moving its ERB view too.
        if origin_pathname.extname == '.rake'
          new_origin_pathname = origin_pathname.sub('/lib/', '/spec/lib/').sub(%r{^lib/}, 'spec/lib/').sub('.rake', '_spec.rb')
          new_destination_pathname = destination_pathname.sub('/lib/', '/spec/lib/').sub(%r{^lib/}, 'spec/lib/').sub('.rake', '_spec.rb')
        else
          new_origin_pathname = origin_pathname.sub('/app/', '/spec/').sub(%r{^app/}, 'spec/').sub('.rb', '_spec.rb')
          new_destination_pathname = destination_pathname.sub('/app/', '/spec/').sub(%r{^app/}, 'spec/').sub('.rb', '_spec.rb')
        end
        FileMoveOperation.new(
          origin_pathname: new_origin_pathname,
          destination_pathname: new_destination_pathname,
          destination_pack: destination_pack
        )
      end

      private

      sig { params(path: Pathname).returns(FileMoveOperation) }
      def relative_to(path)
        FileMoveOperation.new(
          origin_pathname: origin_pathname.relative_path_from(path),
          destination_pathname: destination_pathname.relative_path_from(path),
          destination_pack: destination_pack
        )
      end
    end
  end
end
