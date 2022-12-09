# typed: strict

module UsePacks
  class RubocopPostProcessor
    include PerFileProcessorInterface
    extend T::Sig

    sig { override.params(file_move_operation: Private::FileMoveOperation).void }
    def before_move_file!(file_move_operation)
      relative_path_to_origin = file_move_operation.origin_pathname
      relative_path_to_destination = file_move_operation.destination_pathname

      rubocop_todo = Pathname.new('.rubocop_todo.yml')
      if rubocop_todo.exist?
        UsePacks.replace_in_file(
          file: rubocop_todo.to_s,
          find: relative_path_to_origin,
          replace_with: relative_path_to_destination
        )
      end

      if file_move_operation.origin_pack.name != ParsePackwerk::ROOT_PACKAGE_NAME && file_move_operation.destination_pack.name != ParsePackwerk::ROOT_PACKAGE_NAME
        origin_rubocop_todo = file_move_operation.origin_pack.directory.join(RuboCop::Packs::PACK_LEVEL_RUBOCOP_TODO_YML)
        # If there were TODOs for this file in the origin pack's pack-based rubocop, we want to move it to the destination
        if origin_rubocop_todo.exist?
          loaded_origin_rubocop_todo = YAML.load_file(origin_rubocop_todo)
          new_origin_rubocop_todo = loaded_origin_rubocop_todo.dup

          loaded_origin_rubocop_todo.each do |cop_name, cop_config|
            next unless cop_config['Exclude'].include?(relative_path_to_origin.to_s)

            new_origin_rubocop_todo[cop_name]['Exclude'] = cop_config['Exclude'] - [relative_path_to_origin.to_s]
            origin_rubocop_todo.write(YAML.dump(new_origin_rubocop_todo))

            destination_rubocop_todo = file_move_operation.destination_pack.directory.join(RuboCop::Packs::PACK_LEVEL_RUBOCOP_TODO_YML)
            if destination_rubocop_todo.exist?
              new_destination_rubocop_todo = YAML.load_file(destination_rubocop_todo).dup
            else
              new_destination_rubocop_todo = {}
            end

            new_destination_rubocop_todo[cop_name] ||= { 'Exclude' => [] }

            new_destination_rubocop_todo[cop_name]['Exclude'] += [relative_path_to_destination.to_s]
            destination_rubocop_todo.write(YAML.dump(new_destination_rubocop_todo))
          end
        end
      end
    end

    sig { params(file_move_operations: T::Array[Private::FileMoveOperation]).void }
    def after_move_files!(file_move_operations)
      # There could also be no TODOs for this file, but moving it produced TODOs. This could happen if:
      # 1) The origin pack did not enforce a rubocop, such as typed public APIs
      # 2) The file satisfied the cop in the origin pack, such as the Packs/RootNamespaceIsPackName, but the desired
      # namespace changed once the file was moved to a different pack.
      files = []
      file_move_operations.each do |file_move_operation|
        if file_move_operation.destination_pathname.exist?
          files << file_move_operation.destination_pathname.to_s
        end
      end

      RuboCop::Packs.regenerate_todo(files: files)
    end
  end
end
