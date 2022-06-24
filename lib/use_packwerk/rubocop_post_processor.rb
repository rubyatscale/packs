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
      return if !rubocop_todo.exist?
      UsePackwerk.replace_in_file(
        file: rubocop_todo.to_s,
        find: relative_path_to_origin,
        replace_with: relative_path_to_destination,
      )
    end
  end
end
