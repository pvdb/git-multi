require "git/meta/version"
require "git/meta/commands"

require 'ext/string'

require 'octokit'

module Git
  module Meta

    USER  = `git config --global github.user`.chomp.freeze
    TOKEN = `git config --global github.token`.chomp.freeze

    module_function

    def client
      @client ||= Octokit::Client.new(
        :access_token => Git::Meta::TOKEN,
        :auto_paginate => true,
      )
    end

  end
end
