# typed: false
# frozen_string_literal: true

require 'packs'
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
    allow(Packs.const_get(:Private)).to receive(:safe_exit)
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
    metadata: metadata,
    config: {}
  )

  ParsePackwerk.write_package_yml!(package)
end
