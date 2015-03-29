require "git/meta/version"
require "git/meta/commands"
require "git/meta/nike"
require "git/meta/notify"

require 'ext/string'
require 'ext/sawyer/resource'

require 'octokit'

require 'etc'
require 'yaml'
require 'shellwords'

module Git
  module Meta

    MAN_PAGE = File.expand_path('../../../doc/git-meta.man', __FILE__)

    module_function

    def interactive?
      STDOUT.tty? && STDERR.tty?
    end

    def client
      @client ||= Octokit::Client.new(
        :access_token => Git::Meta::TOKEN,
        :auto_paginate => true,
      )
    end

    #
    # https://developer.github.com/v3/repos/#list-user-repositories
    #

    @user_repositories = Hash.new { |repos, (user, type)|
      repos[[user, type]] = begin
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
        client.org_repositories(org, :type => type).
        sort_by { |repo| repo[:name].downcase }
      end
    }

    def org_repositories(org, type = :owner) # all, public, private, forks, sources, member
      @org_repositories[[org, type]]
    end

    #
    # all together now ...
    #

    def github_repositories
      @github_repositories ||= (user_repositories(USER) + org_repositories(ORGANIZATION))
    end

    def github_organizations
      @github_organizations || client.organizations
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

    def local_repositories
      # TODO support org repositories...
      Dir.glob(File.join(Git::Meta::WORKAREA, Git::Meta::USER, '*')).map { |path|
        full_name = path[/#{Git::Meta::USER}\/.*\z/] # e.g. "pvdb/git-meta"
        def full_name.full_name() self ; end         # awesome duck-typing!
        full_name
      }
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
