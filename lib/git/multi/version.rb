require 'octokit'
require 'sawyer'
require 'psych'

module Git
  module Multi
    NAME = 'git-multi'
    VERSION = '1.0.0'

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

    PIM = <<~"EOPIM" # gem post_install_message

    The required settings are as follows:

    git config --global --add github.user <your_github_username>
    git config --global --add github.organizations <your_github_orgs>
    git config --global --add github.token <your_github_token>
    git config --global --add gitmulti.workarea <your_root_workarea>

    EOPIM
  end
end
