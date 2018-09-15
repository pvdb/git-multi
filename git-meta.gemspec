# frozen_string_literal: true

lib = File.expand_path('lib', __dir__)
$LOAD_PATH.unshift(lib) unless $LOAD_PATH.include?(lib)
require 'git/meta/version'

Gem::Specification.new do |spec|
  spec.name          = Git::Meta::NAME
  spec.version       = Git::Meta::VERSION
  spec.authors       = ['Peter Vandenberk']
  spec.email         = ['pvandenberk@mac.com']

  spec.summary       = 'The ultimate multi-repo utility for git!'
  spec.description   = 'Run the same git command in a set of related repos'
  spec.homepage      = 'https://github.com/pvdb/git-meta'
  spec.license       = 'MIT'

  spec.files         = begin
                         `git ls-files -z`
                           .split("\x0")
                           .reject { |f| f.match(%r{^(test|spec|features)/}) }
                       end
  spec.bindir        = 'exe'
  spec.executables   = spec.files.grep(%r{^exe/}) { |f| File.basename(f) }
  spec.require_paths = ['lib']

  spec.add_dependency 'octokit', '~> 4.8'

  spec.add_development_dependency 'bundler'
  spec.add_development_dependency 'pry'
  spec.add_development_dependency 'rake'
end
