require 'octokit'
require 'sawyer'
require 'faraday'
require 'addressable'

module Git
  module Multi
    NAME = 'git-multi'
    VERSION = '1.0.5'

    LONG_VERSION = "%s v%s (%s v%s, %s v%s, %s v%s, %s v%s)" % [
      NAME,
      VERSION,
      'octokit.rb',
      Octokit::VERSION,
      'sawyer',
      Sawyer::VERSION,
      'faraday',
      Faraday::VERSION,
      'addressable',
      Addressable::VERSION::STRING,
    ]
  end
end
