# typed: strict

module UsePackwerk
  class RubocopPostProcessor
    include PerFileProcessorInterface
    extend T::Sig

    sig { override.params(file_move_operation: Private::FileMoveOperation).void }
    def before_move_file!(file_move_operation)
      relative_path_to_origin = file_move_operation.origin_pathname
      relative_path_to_destination = file_move_operation.destination_pathname

      rubocop_todo = Pathname.new('.rubocop_todo.yml')
      if rubocop_todo.exist?
        UsePackwerk.replace_in_file(
          file: rubocop_todo.to_s,
          find: relative_path_to_origin,
          replace_with: relative_path_to_destination
        )
      end

      if file_move_operation.origin_pack.name != ParsePackwerk::ROOT_PACKAGE_NAME && file_move_operation.destination_pack.name != ParsePackwerk::ROOT_PACKAGE_NAME
        origin_rubocop_todo = file_move_operation.origin_pack.directory.join('.rubocop_todo.yml')
        if origin_rubocop_todo.exist?
          loaded_origin_rubocop_todo = YAML.load_file(origin_rubocop_todo)
          new_origin_rubocop_todo = loaded_origin_rubocop_todo.dup

          loaded_origin_rubocop_todo.each do |cop_name, cop_config|
            next unless cop_config['Exclude'].include?(relative_path_to_origin.to_s)

            new_origin_rubocop_todo[cop_name]['Exclude'] = cop_config['Exclude'] - [relative_path_to_origin.to_s]
            origin_rubocop_todo.write(YAML.dump(new_origin_rubocop_todo))

            destination_rubocop_todo = file_move_operation.destination_pack.directory.join('.rubocop_todo.yml')
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
  end
end
