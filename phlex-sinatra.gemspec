# frozen_string_literal: true

require_relative 'lib/phlex/sinatra/version'

Gem::Specification.new do |spec|
  spec.name = 'phlex-sinatra'
  spec.version = Phlex::Sinatra::VERSION
  spec.authors = ['Ben Pickles']
  spec.email = ['spideryoung@gmail.com']

  spec.summary = 'A Phlex adapter for Sinatra'
  spec.description = 'A Phlex adapter for Sinatra'
  spec.homepage = 'https://github.com/benpickles/phlex-sinatra'
  spec.license = 'MIT'
  spec.required_ruby_version = '>= 2.7' # Match Phlex.

  spec.metadata['changelog_uri'] = 'https://github.com/benpickles/phlex-sinatra/blob/main/CHANGELOG.md'
  spec.metadata['homepage_uri'] = spec.homepage
  spec.metadata['rubygems_mfa_required'] = 'true'
  spec.metadata['source_code_uri'] = 'https://github.com/benpickles/phlex-sinatra'

  # Specify which files should be added to the gem when it is released.
  # The `git ls-files -z` loads the files in the RubyGem that have been added into git.
  spec.files = Dir.chdir(__dir__) do
    `git ls-files -z`.split("\x0").reject do |f|
      (File.expand_path(f) == __FILE__) || f.start_with?(*%w[bin/ test/ spec/ features/ .git .circleci appveyor])
    end
  end
  spec.bindir = 'exe'
  spec.executables = spec.files.grep(%r{\Aexe/}) { |f| File.basename(f) }
  spec.require_paths = ['lib']

  spec.add_dependency 'phlex', '>= 1.7.0'
end
