require 'octokit'

module Git
  module Meta
    NAME = 'git-meta'
    VERSION = '0.1.0'

    LONG_VERSION = "%s v%s (%s v%s)" % [
      NAME,
      VERSION,
      'octokit.rb',
      Octokit::VERSION,
    ]
  end
end
