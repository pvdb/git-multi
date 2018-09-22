require 'octokit'
require 'sawyer'
require 'psych'

module Git
  module Multi
    NAME = 'git-multi'
    VERSION = '1.0.5'

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
