# typed: false
# frozen_string_literal: true

require 'packs'
# This require should eventually be done in packs/rspec/support, since it's needed to load the Dir.mktmpdir method
require 'tmpdir'
require 'packs/rspec/support'

RSpec.configure do |config|
  # Enable flags like --only-failures and --next-failure
  config.example_status_persistence_file_path = '.rspec_status'

  # Disable RSpec exposing methods globally on `Module` and `main`
  config.disable_monkey_patching!

  config.expect_with :rspec do |c|
    c.syntax = :expect
  end

  config.before do |_example|
    ParsePackwerk.bust_cache!
    allow(Packs.const_get(:Private)).to receive(:exit_with)
  end

  config.around do |example|
    ParsePackwerk.bust_cache!
    example.run
  end
end

extend T::Sig # rubocop:disable Style/MixinUsage:

sig do
  params(
    pack_name: String,
    dependencies: T::Array[String],
    violations: T::Array[ParsePackwerk::Violation],
    enforce_dependencies: T.nilable(T::Boolean),
    enforce_privacy: T::Boolean,
    enforce_layers: T::Boolean,
    visible_to: T::Array[String],
    metadata: T.untyped,
    owner: T.nilable(String),
    config: T::Hash[String, T.untyped]
  ).void
end
def write_package_yml(
  pack_name,
  dependencies: [],
  violations: [],
  enforce_dependencies: true,
  enforce_privacy: true,
  enforce_layers: true,
  visible_to: [],
  metadata: {},
  owner: nil,
  config: {}
)
  if owner
    metadata.merge!({ 'owner' => owner })
  end

  package = ParsePackwerk::Package.new(
    name: pack_name,
    dependencies: dependencies,
    violations: violations,
    enforce_dependencies: enforce_dependencies,
    enforce_privacy: enforce_privacy,
    enforce_layers: enforce_layers,
    metadata: metadata,
    config: config
  )

  ParsePackwerk.write_package_yml!(package)
end
