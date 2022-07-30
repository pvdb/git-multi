lib = File.expand_path('lib', __dir__)
$LOAD_PATH.unshift(lib) unless $LOAD_PATH.include?(lib)
require 'git/multi/version'
require 'git/multi/gemspec'

Gem::Specification.new do |spec|
  spec.name          = Git::Multi::NAME
  spec.version       = Git::Multi::VERSION
  spec.authors       = ['Peter Vandenberk']
  spec.email         = ['pvandenberk@mac.com']

  spec.summary       = 'The ultimate multi-repo utility for git!'
  spec.description   = 'Run the same git command in a set of related repos'
  spec.homepage      = 'https://github.com/pvdb/git-multi'
  spec.license       = 'MIT'

  spec.required_ruby_version = ['>= 2.6.0', '< 3.0.0']

  spec.metadata['homepage_uri']    = spec.homepage
  spec.metadata['source_code_uri'] = spec.homepage
  spec.metadata['changelog_uri']   = File.join(spec.homepage, 'blob', 'master', 'README.md')

  spec.metadata['rubygems_mfa_required'] = 'true'

  # Specify which files should be added to the gem when it is released.
  # The `git ls-files -z` loads the files in the RubyGem that have been added into git.
  spec.files = Dir.chdir(File.expand_path(__dir__)) do
    `git ls-files -z`
      .split("\x0")
      .reject { |f| f.match(%r{^(test|spec|features)/}) }
  end
  spec.bindir        = 'exe'
  spec.executables   = spec.files.grep(%r{^exe/}) { |f| File.basename(f) }
  spec.require_paths = ['lib']

  spec.post_install_message = Git::Multi::PIM

  spec.add_dependency 'faraday', '~> 1'
  spec.add_dependency 'octokit', '~> 4'

  spec.add_development_dependency 'bundler'
  spec.add_development_dependency 'minitest'
  spec.add_development_dependency 'pry'
  spec.add_development_dependency 'pry-rescue'
  spec.add_development_dependency 'rake'
  spec.add_development_dependency 'rubocop'
  spec.add_development_dependency 'rubocop-minitest'
  spec.add_development_dependency 'rubocop-rake'
end
