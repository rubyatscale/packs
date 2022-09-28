Gem::Specification.new do |spec|
  spec.name          = 'use_packwerk'
  spec.version       = '0.55.0'
  spec.authors       = ['Gusto Engineers']
  spec.email         = ['dev@gusto.com']

  spec.summary       = 'UsePackwerk is a gem that helps in creating and maintaining packwerk packages.'
  spec.description   = 'UsePackwerk is a gem that helps in creating and maintaining packwerk packages.'
  spec.homepage      = 'https://github.com/rubyatscale/use_packwerk'
  spec.license       = 'MIT'

  if spec.respond_to?(:metadata)
    spec.metadata['homepage_uri'] = spec.homepage
    spec.metadata['source_code_uri'] = 'https://github.com/rubyatscale/use_packwerk'
    spec.metadata['changelog_uri'] = 'https://github.com/rubyatscale/use_packwerk/releases'
    spec.metadata['allowed_push_host'] = 'https://rubygems.org'
  else
    raise 'RubyGems 2.0 or newer is required to protect against ' \
          'public gem pushes.'
  end

  # Specify which files should be added to the gem when it is released.
  spec.files = Dir['README.md', 'lib/**/*', 'bin/**/*']

  # https://guides.rubygems.org/make-your-own-gem/#adding-an-executable
  # and
  # https://bundler.io/blog/2015/03/20/moving-bins-to-exe.html
  spec.executables   = ['use_packwerk']

  spec.add_dependency 'colorize'
  spec.add_dependency 'parse_packwerk'
  spec.add_dependency 'sorbet-runtime'
  spec.add_dependency 'code_ownership'
  spec.add_dependency 'package_protections'
  spec.add_dependency 'thor'

  spec.add_development_dependency 'rake'
  spec.add_development_dependency 'bundler', '~> 2.2'
  spec.add_development_dependency 'pry'
  spec.add_development_dependency 'rspec', '~> 3.0'
  spec.add_development_dependency 'sorbet'
  spec.add_development_dependency 'sorbet-static'
  spec.add_development_dependency 'tapioca'
  spec.add_development_dependency 'pry-byebug'
  spec.add_development_dependency 'rubocop'
  spec.add_development_dependency 'rubocop-rspec'
end
