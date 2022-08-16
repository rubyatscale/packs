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

extend T::Sig

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
    protections: T.untyped,
    global_namespaces: T::Array[String],
    visible_to: T::Array[String],
    owner: T.nilable(String)
  ).void
end
def write_package_yml(
  pack_name,
  dependencies: [],
  enforce_dependencies: true,
  enforce_privacy: true,
  protections: {},
  global_namespaces: [],
  visible_to: [],
  owner: nil
)
  defaults = {
    'prevent_this_package_from_violating_its_stated_dependencies' => 'fail_on_new',
    'prevent_other_packages_from_using_this_packages_internals' => 'fail_on_new',
    'prevent_this_package_from_exposing_an_untyped_api' => 'fail_on_new',
    'prevent_this_package_from_creating_other_namespaces' => 'fail_on_new',
    'prevent_other_packages_from_using_this_package_without_explicit_visibility' => 'fail_never',
  }
  protections_with_defaults = defaults.merge(protections)
  metadata = { 'protections' => protections_with_defaults }

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
