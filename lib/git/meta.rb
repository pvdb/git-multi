require "git/meta/version"
require "git/meta/commands"

module Git
  module Meta
    USER  = `git config --global github.user`.chomp.freeze
    TOKEN = `git config --global github.token`.chomp.freeze
  end
end
