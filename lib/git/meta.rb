require "git/meta/version"
require "git/meta/commands"

module Git
  module Meta
    USER = `git config --global github.user`.chomp.freeze
  end
end
