Gem::Specification.new do |spec|
  spec.name          = 'packs'
  spec.version       = '0.0.37'
  spec.authors       = ['Gusto Engineers']
  spec.email         = ['dev@gusto.com']

  spec.summary       = 'Provides CLI tools for working with ruby packs.'
  spec.description   = 'Provides CLI tools for working with ruby packs.'
  spec.homepage      = 'https://github.com/rubyatscale/packs'
  spec.license       = 'MIT'

  if spec.respond_to?(:metadata)
    spec.metadata['homepage_uri'] = spec.homepage
    spec.metadata['source_code_uri'] = 'https://github.com/rubyatscale/packs'
    spec.metadata['changelog_uri'] = 'https://github.com/rubyatscale/packs/releases'
    spec.metadata['allowed_push_host'] = 'https://rubygems.org'
  else
    raise 'RubyGems 2.0 or newer is required to protect against ' \
          'public gem pushes.'
  end

  spec.required_ruby_version = Gem::Requirement.new('>= 2.6.0')
  # Specify which files should be added to the gem when it is released.
  spec.files = Dir['README.md', 'lib/**/*', 'bin/**/*']

  # https://guides.rubygems.org/make-your-own-gem/#adding-an-executable
  # and
  # https://bundler.io/blog/2015/03/20/moving-bins-to-exe.html
  spec.executables = %w[packs]

  spec.add_dependency 'code_ownership', '>= 1.33.0'
  spec.add_dependency 'packs-specification'
  spec.add_dependency 'packwerk'
  spec.add_dependency 'parse_packwerk'
  spec.add_dependency 'rainbow'
  spec.add_dependency 'sorbet-runtime'
  spec.add_dependency 'thor'
  spec.add_dependency 'tty-prompt'

  # rubocop:disable Gemspec/DevelopmentDependencies
  spec.add_development_dependency 'bundler', '~> 2.2'
  spec.add_development_dependency 'pry'
  spec.add_development_dependency 'pry-byebug'
  spec.add_development_dependency 'rake'
  spec.add_development_dependency 'rspec', '~> 3.0'
  spec.add_development_dependency 'rubocop'
  spec.add_development_dependency 'sorbet'
  spec.add_development_dependency 'sorbet-static'
  spec.add_development_dependency 'spoom', '1.2.1' # later versions do not support ruby 2.7
  spec.add_development_dependency 'tapioca'
  # rubocop:enable Gemspec/DevelopmentDependencies
end
