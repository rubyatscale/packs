# typed: strict

module Packs
  class UpdateReferencesPostProcessor
    include PerFileProcessorInterface

    extend T::Sig

    sig { override.params(file_move_operation: Private::FileMoveOperation).void }
    def before_move_file!(file_move_operation)
      nil
    end

    sig { override.params(file_move_operations: T::Array[Private::FileMoveOperation]).void }
    def after_move_files!(file_move_operations)
      return if file_move_operations.empty?

      unless self.class.ripgrep_enabled?
        Logging.print('Skipping UpdateReferencesPostProcessor since ripgrep is not installed')
        return
      end

      origin_pack = T.must(file_move_operations.first).origin_pack.name
      destination_pack = T.must(file_move_operations.first).destination_pack.name

      `rg '#{origin_pack}' -l --hidden | xargs sed -i '' 's,#{origin_pack},#{destination_pack},g'`
    end

    sig { returns(T::Boolean) }
    def self.ripgrep_enabled?
      !!system('which', 'rg', out: File::NULL, err: :out)
    end
  end
end
