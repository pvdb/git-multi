require 'octokit'

begin
  require 'net/http/persistent'
  if Octokit.middleware.adapter == Faraday::Adapter::NetHttp
    adapter = Faraday::RackBuilder::Handler.new(Faraday::Adapter::NetHttpPersistent)
    Octokit.middleware.instance_variable_set(:@adapter, adapter)
  end
rescue LoadError
  # NOOP  -  `Net::HTTP::Persistent` is optional, so
  # if the gem isn't installed, then we run with the
  # default `Net::HTTP` Faraday adapter;  if however
  # the gem is installed then we make Faraday use it
  # to benefit from persistent HTTP connections
end

module Git
  module Hub
    module_function

    def client
      @client ||= Octokit::Client.new(
        access_token: Git::Multi::TOKEN,
        auto_paginate: true,
      )
    end

    private_class_method :client

    def connected?
      @connected ||= begin
        client.validate_credentials
        true
      rescue Faraday::ConnectionFailed
        false
      end
    end

    # FIXME: update login as part of `--refresh`

    def login
      @login ||= begin
        client.user.login
      rescue Octokit::Unauthorized, Faraday::ConnectionFailed
        nil
      end
    end

    # FIXME: update orgs as part of `--refresh`

    def orgs
      @orgs ||= begin
        client.organizations.map(&:login)
      rescue Octokit::Unauthorized, Faraday::ConnectionFailed
        []
      end
    end

    # pick a (semi-)random repo from GitHub

    def repository_fields
      client.repo('git/git').fields
    end

    def query_args
      # rubocop:disable Style/FormatStringToken
      repository_fields.sort.each_slice(3).map { |foo, bar, qux|
        format('%-20s %-20s %-20s', foo, bar, qux).rstrip
      }.join("\n    ")
      # rubocop:enable Style/FormatStringToken
    end

    #
    # https://developer.github.com/v3/repos/#list-user-repositories
    #

    @user_repositories = Hash.new { |repos, (user, type)|
      repos[[user, type]] = begin
        client
          .repositories(user, type: type)
          .sort_by { |repo| repo[:name].downcase }
      end
    }

    def user_repositories(user, type = :owner)
      # type can be one of: all, owner, member
      @user_repositories[[user, type]]
    end

    #
    # https://developer.github.com/v3/repos/#list-organization-repositories
    #

    @org_repositories = Hash.new { |repos, (org, type)|
      repos[[org, type]] = begin
        client
          .org_repositories(org, type: type)
          .sort_by { |repo| repo[:name].downcase }
      end
    }

    def org_repositories(org, type = :owner)
      # type can be one of: all, public, private, forks, sources, member
      @org_repositories[[org, type]]
    end
  end
end
