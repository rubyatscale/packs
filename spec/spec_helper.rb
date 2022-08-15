# typed: strict
# frozen_string_literal: true

require 'use_packwerk'
require 'tmpdir'
require_relative 'support/app_fixtures'
require 'pry'

RSpec.configure do |config|
  # Enable flags like --only-failures and --next-failure
  config.example_status_persistence_file_path = '.rspec_status'

  # Disable RSpec exposing methods globally on `Module` and `main`
  config.disable_monkey_patching!

  config.expect_with :rspec do |c|
    c.syntax = :expect
  end

  config.include_context 'app fixtures'

  config.around do |example|
    ParsePackwerk.bust_cache!
    example.run
  end

  config.around do |example|
    prefix = [File.basename($0), Process.pid].join('-') # rubocop:disable Style/SpecialGlobalVars
    tmpdir = Dir.mktmpdir(prefix)
    Dir.chdir(tmpdir) do
      example.run
    end
  ensure
    FileUtils.rm_rf(T.must(tmpdir))
  end
end

extend T::Sig

sig { params(path: String, content: String).returns(Integer) }
def write_file(path, content = '')
  pathname = Pathname.new(path)
  FileUtils.mkdir_p(pathname.dirname)
  pathname.write(content)
end
