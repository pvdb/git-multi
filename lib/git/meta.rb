require 'etc'
require 'yaml'
require 'fileutils'
require 'shellwords'

require 'octokit'

require 'ext/dir'
require 'ext/string'
require 'ext/commify'
require 'ext/sawyer/resource'

require "git/meta/version"
require "git/meta/settings"
require "git/meta/commands"
require "git/meta/nike"
require "git/meta/notify"

module Git
  module Meta

    MAN_PAGE = File.expand_path('../../../doc/git-meta.man', __FILE__)

    module_function

    def client
      @client ||= Octokit::Client.new(
        :access_token => TOKEN,
        :auto_paginate => true,
      )
    end

    def login
      @login ||= begin
        client.user.login
      rescue Octokit::Unauthorized, Faraday::ConnectionFailed
        nil
      end
    end

    # FIXME update organizations as part of `--refresh`

    def github_organizations
      @github_organizations ||= begin
        client.organizations
      rescue Octokit::Unauthorized, Faraday::ConnectionFailed
        []
      end
    end

    def git_option name, default = nil
      value = `git config #{name}`.chomp.freeze
      value.empty? && default ? default : value
    end

    def env_var name, default = nil
      value = ENV[name].to_s.freeze
      value.empty? && default ? default : value
    end

    class << self
      private :client, :login, :git_option, :env_var
    end

    def connected?
      client.validate_credentials
      true
    rescue Faraday::ConnectionFailed
      false
    end

    USER          = git_option 'github.user'
    ORGANIZATIONS = git_option('github.organizations').split(/\s*,\s*/)

    TOKEN         = git_option 'gitmeta.token'
    LOGIN         = login # AFTER setting TOKEN!
    ORGS          = github_organizations.map(&:login)

    HOME          = env_var 'HOME', Etc.getpwuid.dir

    WORKAREA      = git_option 'gitmeta.workarea',  File.join(HOME, 'Workarea')
    YAML_CACHE    = git_option 'gitmeta.yamlcache', File.join(HOME, '.gitmeta.yaml')
    JSON_CACHE    = git_option 'gitmeta.jsoncache', File.join(HOME, '.gitmeta.json')

    #
    # https://developer.github.com/v3/repos/#list-user-repositories
    #

    @github_user_repositories = Hash.new { |repos, (user, type)|
      repos[[user, type]] = begin
        client.repositories(user, :type => type).
        sort_by { |repo| repo[:name].downcase }
      end
    }

    def github_user_repositories(user, type = :owner) # all, owner, member
      @github_user_repositories[[user, type]]
    end

    @local_user_repositories = Hash.new { |repos, user|
      repos[user] = Dir.new(WORKAREA).git_repos(user)
    }

    def local_user_repositories(user)
      @local_user_repositories[user]
    end

    #
    # https://developer.github.com/v3/repos/#list-organization-repositories
    #

    @github_org_repositories = Hash.new { |repos, (org, type)|
      repos[[org, type]] = begin
        client.org_repositories(org, :type => type).
        sort_by { |repo| repo[:name].downcase }
      end
    }

    def github_org_repositories(org, type = :owner) # all, public, private, forks, sources, member
      @github_org_repositories[[org, type]]
    end

    @local_org_repositories = Hash.new { |repos, org|
      repos[org] = Dir.new(WORKAREA).git_repos(org)
    }

    def local_org_repositories(org)
      @local_org_repositories[org]
    end

    #
    # all together now ...
    #

    def github_repositories
      @github_repositories ||= (
        github_user_repositories(USER) +
        ORGANIZATIONS.map { |org| github_org_repositories(org) }
      ).flatten
    end

    def local_repositories
      (
        local_user_repositories(USER) +
        ORGANIZATIONS.map { |org| local_org_repositories(org) }
      ).flatten
    end

    def refresh_repositories
      File.open(YAML_CACHE, 'w') do |file|
        file.write(github_repositories.to_yaml)
      end
      File.open(JSON_CACHE, 'w') do |file|
        github_repositories.each do |sawyer_resource|
          file.puts(sawyer_resource.to_json)
        end
      end
    end

    def repositories
      if File.exists? YAML_CACHE
        if (yaml_cache = File.read(YAML_CACHE)).empty?
          refresh_repositories and repositories
        else
          @repositories ||= YAML.load(yaml_cache).tap do |projects|
            projects.each_with_index do |project, index|
              # ensure #method_missing works for Sawyer::Resource instances
              project.instance_eval("@_metaclass = (class << self; self ; end)")
              project.owner.instance_eval("@_metaclass = (class << self; self ; end)")
              # adorn 'project', which is a Sawyer::Resource
              project.parent_dir = File.join(WORKAREA, project.owner.login)
              project.local_path = File.join(WORKAREA, project.full_name)
              project.fractional_index = "#{index + 1}/#{projects.count}"
              # extend 'project' with 'just do it' capabilities
              project.extend Nike
              # extend 'project' with some cheeky knowledge
              # project.extend Prometheus
            end
          end
        end
      else
        refresh_repositories and repositories
      end
    end

    def excess_repositories
      local_repositories.reject { |project|
        repositories.map(&:full_name).include? project.full_name
      }
    end

    def stale_repositories
      repositories.reject { |project|
        github_repositories.map(&:full_name).include? project.full_name
      }
    end

    def missing_repositories
      repositories.find_all { |project|
        !File.directory? project.local_path
      }
    end

    def cloned_repositories
      repositories.find_all { |project|
        File.directory? project.local_path
      }
    end

  end
end
