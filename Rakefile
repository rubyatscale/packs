# typed: ignore

require 'bundler/gem_tasks'
require 'rspec/core/rake_task'

RSpec::Core::RakeTask.new(:spec)

require 'rb_sys/extensiontask'

task build: :compile

RbSys::ExtensionTask.new('hello_rust') do |ext|
  ext.lib_dir = 'lib/hello_rust'
end

task default: %i[compile spec]
