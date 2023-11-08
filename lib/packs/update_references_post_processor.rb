# typed: strict

require 'open3'
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

      origin_pack = T.must(file_move_operations.first).origin_pack.name
      destination_pack = T.must(file_move_operations.first).destination_pack.name

      if self.class.ripgrep_enabled?
        cmd = "rg '#{origin_pack}' -l --hidden | xargs sed -i 's,#{origin_pack},#{destination_pack},g'"
        puts cmd
        puts "current dir: #{Dir.pwd}"
        puts "current dir ls: #{Dir.children(Dir.pwd)}"
        `#{cmd}`
      else
        Logging.print('For faster UpdateReferences install ripgrep: https://github.com/BurntSushi/ripgrep/tree/master')
        Dir.glob('./**/*', File::FNM_DOTMATCH) do |file_name|
          next if File.directory?(file_name)

          text = File.read(file_name)
          replace = text.gsub(origin_pack, destination_pack)
          File.open(file_name, 'w') { |file| file.puts replace }
        end
      end
    end

    sig { returns(T::Boolean) }
    def self.ripgrep_enabled?
      !!system('which', 'rg', out: File::NULL, err: :out)
    end

    private
    def i_arg
      _stdout_str, _stderr_str, status = Open3.capture3('sed', '--version')
      puts "sed version: #{_stdout_str}"
      puts "sed help: #{`sed --help`}`}"
      status.success? ? "" : "''"
    end
  end
end
