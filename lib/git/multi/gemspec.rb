module Git
  module Multi
    PIM = <<~"EOPIM" # gem post_install_message, used in git-multi.gemspec

      The required settings for \033[1mgit multi\33[0m are as follows:

      \tgit config --global --add \033[1mgithub.user\033[0m <your_github_username>
      \tgit config --global --add \033[1mgithub.organizations\033[0m <your_github_orgs>
      \tgit config --global --add \033[1mgithub.token\033[0m <your_github_oauth_token>

      Unless your top-level workarea is `${HOME}/Workarea` you should also set:

      \tgit config --global --add \033[1mgit.multi.workarea\033[0m <your_root_workarea>

      Thanks for using \033[1mgit multi\033[0m ... the ultimate multi-repo utility for git!

    EOPIM
  end
end
