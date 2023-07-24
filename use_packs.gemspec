Gem::Specification.new do |spec|
  spec.name          = 'use_packs'
  spec.version       = '0.0.21'
  spec.authors       = ['Gusto Engineers']
  spec.email         = ['dev@gusto.com']

  spec.summary       = 'UsePacks is a gem that helps in creating and maintaining packwerk packages.'
  spec.description   = 'UsePacks is a gem that helps in creating and maintaining packwerk packages.'
  spec.homepage      = 'https://github.com/rubyatscale/use_packs'
  spec.license       = 'MIT'

  if spec.respond_to?(:metadata)
    spec.metadata['homepage_uri'] = spec.homepage
    spec.metadata['source_code_uri'] = 'https://github.com/rubyatscale/use_packs'
    spec.metadata['changelog_uri'] = 'https://github.com/rubyatscale/use_packs/releases'
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
  spec.add_dependency 'colorize'
  spec.add_dependency 'packs'
  spec.add_dependency 'packwerk'
  spec.add_dependency 'parse_packwerk'
  spec.add_dependency 'rubocop-packs'
  spec.add_dependency 'sorbet-runtime'
  spec.add_dependency 'thor'
  spec.add_dependency 'tty-prompt'
  spec.add_dependency 'visualize_packwerk'

  # rubocop:disable Gemspec/DevelopmentDependencies
  spec.add_development_dependency 'bundler', '~> 2.2'
  spec.add_development_dependency 'pry'
  spec.add_development_dependency 'pry-byebug'
  spec.add_development_dependency 'rake'
  spec.add_development_dependency 'rspec', '~> 3.0'
  spec.add_development_dependency 'rubocop'
  spec.add_development_dependency 'rubocop-rspec'
  spec.add_development_dependency 'sorbet'
  spec.add_development_dependency 'sorbet-static'
  spec.add_development_dependency 'tapioca'
  # rubocop:enable Gemspec/DevelopmentDependencies
end
