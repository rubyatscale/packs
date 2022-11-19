# typed: strict
# frozen_string_literal: true

require 'use_packwerk'
require 'tmpdir'

RSpec.configure do |config|
  # Enable flags like --only-failures and --next-failure
  config.example_status_persistence_file_path = '.rspec_status'

  # Disable RSpec exposing methods globally on `Module` and `main`
  config.disable_monkey_patching!

  config.expect_with :rspec do |c|
    c.syntax = :expect
  end

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

extend T::Sig # rubocop:disable Style/MixinUsage:

sig { params(path: String, content: String).returns(Integer) }
def write_file(path, content = '')
  pathname = Pathname.new(path)
  FileUtils.mkdir_p(pathname.dirname)
  pathname.write(content)
end

sig do
  params(
    pack_name: String,
    dependencies: T::Array[String],
    enforce_dependencies: T::Boolean,
    enforce_privacy: T::Boolean,
    visible_to: T::Array[String],
    metadata: T.untyped,
    owner: T.nilable(String)
  ).void
end
def write_package_yml(
  pack_name,
  dependencies: [],
  enforce_dependencies: true,
  enforce_privacy: true,
  visible_to: [],
  metadata: {},
  owner: nil
)
  if owner
    metadata.merge!({ 'owner' => owner })
  end

  package = ParsePackwerk::Package.new(
    name: pack_name,
    dependencies: dependencies,
    enforce_dependencies: enforce_dependencies,
    enforce_privacy: enforce_privacy,
    metadata: metadata
  )

  ParsePackwerk.write_package_yml!(package)
end
