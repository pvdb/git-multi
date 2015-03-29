require "git/meta/version"
require "git/meta/commands"
require "git/meta/nike"
require "git/meta/notify"

require 'ext/string'
require 'ext/sawyer/resource'

require 'octokit'

require 'yaml'
require 'shellwords'

module Git
  module Meta

    USER  = `git config --global github.user`.chomp.freeze
    TOKEN = `git config --global gitmeta.token`.chomp.freeze

    YAML_CACHE = File.join(ENV['HOME'].to_s, '.gitmeta.yaml')
    JSON_CACHE = File.join(ENV['HOME'].to_s, '.gitmeta.json')

    PROJECTS_HOME = File.join(ENV['HOME'].to_s, 'Workarea')

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

    @user_repositories = Hash.new { |repos, type|
      repos[type] = begin
        client.repositories(:type => type).
        sort_by { |repo| repo[:name].downcase }
      end
    }

    def user_repositories(type = :owner)
      type ? @user_repositories[type] : @user_repositories
    end

    def github_repositories
      @github_repositories ||= user_repositories
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
              project.parent_dir = File.join(PROJECTS_HOME, project.owner.login)
              project.local_path = File.join(PROJECTS_HOME, project.full_name)
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
      Dir.glob(File.join(Git::Meta::PROJECTS_HOME, Git::Meta::USER, '*')).map { |path|
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
