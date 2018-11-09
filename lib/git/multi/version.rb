require 'octokit'
require 'sawyer'
require 'faraday'
require 'addressable'

module Git
  module Multi
    NAME = 'git-multi'.freeze
    VERSION = '1.1.0'.freeze

    DEPENDENCY_VERSIONS = [
      "octokit.rb v#{Octokit::VERSION}",
      "sawyer v#{Sawyer::VERSION}",
      "faraday v#{Faraday::VERSION}",
      "addressable v#{Addressable::VERSION::STRING}",
      "#{RUBY_ENGINE} #{RUBY_VERSION}p#{RUBY_PATCHLEVEL}",
    ].join(', ').freeze

    LONG_VERSION = "#{NAME} v#{VERSION} (#{DEPENDENCY_VERSIONS})".freeze
  end
end
