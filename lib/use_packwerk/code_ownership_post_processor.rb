# typed: strict

module UsePackwerk
  class CodeOwnershipPostProcessor
    include PerFileProcessorInterface
    extend T::Sig

    sig { void }
    def initialize
      @teams = T.let([], T::Array[String])
      @did_move_files = T.let(false, T::Boolean)
    end

    sig { override.params(file_move_operation: Private::FileMoveOperation).void }
    def before_move_file!(file_move_operation)
      relative_path_to_origin = file_move_operation.origin_pathname
      relative_path_to_destination = file_move_operation.destination_pathname

      code_owners_allow_list_file = Pathname.new('config/code_ownership.yml')

      if code_owners_allow_list_file.exist?
        UsePackwerk.replace_in_file(
          file: code_owners_allow_list_file.to_s,
          find: relative_path_to_origin,
          replace_with: relative_path_to_destination
        )
      end

      team = CodeOwnership.for_file(relative_path_to_origin.to_s)

      if team
        @teams << team.name
      else
        @teams << 'Unknown'
      end

      if !CodeOwnership.for_package(file_move_operation.destination_pack).nil?
        CodeOwnership.remove_file_annotation!(relative_path_to_origin.to_s)
        @did_move_files = true
      end
    end

    sig { void }
    def after_move_files!
      if @teams.any?
        Logging.section('Code Ownership') do
          Logging.print('This section contains info about the current ownership distribution of the moved files.')
          @teams.group_by { |team| team }.sort_by { |_team, instances| -instances.count }.each do |team, instances|
            Logging.print "  #{team} - #{instances.count} files"
          end
          if @did_move_files
            Logging.print 'Since the destination package has package-based ownership, file-annotations were removed from moved files.'
          end
        end
      end
    end
  end
end
