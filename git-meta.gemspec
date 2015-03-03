# coding: utf-8
lib = File.expand_path('../lib', __FILE__)
$LOAD_PATH.unshift(lib) unless $LOAD_PATH.include?(lib)
require 'git/meta/version'

Gem::Specification.new do |spec|
  spec.name          = "git-meta"
  spec.version       = Git::Meta::VERSION
  spec.authors       = ["Peter Vandenberk"]
  spec.email         = ["pvandenberk@mac.com"]
  spec.summary       = %q{Execute the same git command in a set of related repos}
  spec.description   = %q{Execute the same git command in a set of related repos}
  spec.homepage      = "https://github.com/pvdb/git-meta"
  spec.license       = "MIT"

  spec.files         = `git ls-files -z`.split("\x0").reject { |f| f.match(%r{^(test|spec|features)/}) }
  spec.executables   = spec.files.grep(%r{^(exe|bin)/}) { |f| File.basename(f) }
  spec.require_paths = ["lib"]

  spec.add_dependency "slop", "~> 4.0"

  spec.add_development_dependency "bundler", "~> 1.8"
  spec.add_development_dependency "rake", "~> 10.0"
end
