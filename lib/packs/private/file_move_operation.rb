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
        path_parts = filepath_without_pack_name.split('/')
        folder = T.must(path_parts[0])
        file_extension = T.must(filepath_without_pack_name.split('.').last)

        # This could probably be implemented by some "strategy pattern" where different extension types are handled by different helpers
        # Such a thing could also include, for example, when moving a controller, moving its ERB view too.
        if folder == 'app'
          new_origin_pathname = spec_pathname_for_app(origin_pathname, file_extension)
          new_destination_pathname = spec_pathname_for_app(destination_pathname, file_extension)
        else
          new_origin_pathname = spec_pathname_for_non_app(origin_pathname, file_extension, folder)
          new_destination_pathname = spec_pathname_for_non_app(destination_pathname, file_extension, folder)
        end

        FileMoveOperation.new(
          origin_pathname: new_origin_pathname,
          destination_pathname: new_destination_pathname,
          destination_pack: destination_pack
        )
      end

      sig { params(filepath: Pathname, pack: T.nilable(Packs::Pack)).returns(String) }
      def self.get_filepath_without_pack_name(filepath, pack)
        if pack
          filepath.to_s.gsub("#{pack.name}/", '')
        else
          filepath.to_s
        end
      end

      private

      sig { returns(String) }
      def filepath_without_pack_name
        self.class.get_filepath_without_pack_name(origin_pathname, origin_pack)
      end

      sig { params(pathname: Pathname, file_extension: String).returns(Pathname) }
      def spec_pathname_for_app(pathname, file_extension)
        pathname
          .sub('/app/', '/spec/')
          .sub(%r{^app/}, 'spec/')
          .sub(".#{file_extension}", '_spec.rb')
      end

      sig { params(pathname: Pathname, file_extension: String, folder: String).returns(Pathname) }
      def spec_pathname_for_non_app(pathname, file_extension, folder)
        pathname
          .sub("/#{folder}/", "/spec/#{folder}/")
          .sub(%r{^#{folder}/}, "spec/#{folder}/")
          .sub(".#{file_extension}", '_spec.rb')
      end

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
