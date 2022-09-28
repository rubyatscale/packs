# typed: strict

module UsePackwerk
  module PerFileProcessorInterface
    extend T::Sig
    extend T::Helpers

    abstract!

    sig { abstract.params(file_move_operation: Private::FileMoveOperation).void }
    def before_move_file!(file_move_operation); end

    sig { void }
    def print_final_message!
      nil
    end
  end
end
