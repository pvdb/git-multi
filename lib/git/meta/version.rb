require 'octokit'
require 'sawyer'
require 'psych'

module Git
  module Meta
    NAME = 'git-meta'
    VERSION = '0.1.0'

    LONG_VERSION = "%s v%s (%s v%s, %s v%s, %s v%s)" % [
      NAME,
      VERSION,
      'octokit.rb',
      Octokit::VERSION,
      'sawyer',
      Sawyer::VERSION,
      'psych',
      Psych::VERSION,
    ]
  end
end
