require 'octokit'

module Git
  module Hub

    TOKEN = env_var 'GITMETA_GITHUB_API_TOKEN'

    module_function

    def client
      @client ||= Octokit::Client.new(
        :access_token => TOKEN,
        :auto_paginate => true,
      )
    end

    class << self
      private :client
    end

    def connected?
      @connected ||= begin
        client.validate_credentials
        true
      rescue Faraday::ConnectionFailed
        false
      end
    end

    # FIXME update login as part of `--refresh`

    def login
      @login ||= begin
        client.user.login
      rescue Octokit::Unauthorized, Faraday::ConnectionFailed
        nil
      end
    end

    # FIXME update orgs as part of `--refresh`

    def orgs
      @orgs ||= begin
        client.organizations.map(&:login)
      rescue Octokit::Unauthorized, Faraday::ConnectionFailed
        []
      end
    end

    #
    # https://developer.github.com/v3/repos/#list-user-repositories
    #

    @user_repositories = Hash.new { |repos, (user, type)|
      repos[[user, type]] = begin
        notify("Refreshing #{type} '#{user}' repositories from GitHub")
        client.repositories(user, :type => type).
        sort_by { |repo| repo[:name].downcase }
      end
    }

    def user_repositories(user, type = :owner) # all, owner, member
      @user_repositories[[user, type]]
    end

    #
    # https://developer.github.com/v3/repos/#list-organization-repositories
    #

    @org_repositories = Hash.new { |repos, (org, type)|
      repos[[org, type]] = begin
        notify("Refreshing #{type} '#{org}' repositories from GitHub")
        client.org_repositories(org, :type => type).
        sort_by { |repo| repo[:name].downcase }
      end
    }

    def org_repositories(org, type = :owner) # all, public, private, forks, sources, member
      @org_repositories[[org, type]]
    end

  end
end
