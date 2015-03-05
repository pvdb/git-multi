require "git/meta/version"
require "git/meta/commands"
require "git/meta/nike"

require 'ext/string'
require 'ext/sawyer/resource'

require 'octokit'

require 'yaml'
require 'shellwords'

module Git
  module Meta

    USER  = `git config --global github.user`.chomp.freeze
    TOKEN = `git config --global gitmeta.token`.chomp.freeze

    YAML_CACHE = File.join(ENV['HOME'].to_s, '.gitmeta.yml')
    JSON_CACHE = File.join(ENV['HOME'].to_s, '.gitmeta.json')

    PROJECTS_HOME = File.join(ENV['HOME'].to_s, 'Workarea')

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

    def github_repositories(type = :all)
      @github_repositories ||= begin
        client.repositories(
          :type => type,
        ).sort_by { |repo| repo[:name].downcase }
      end
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

    def user_repositories
      if File.exists? YAML_CACHE
        if (yaml_cache = File.read(YAML_CACHE)).empty?
          refresh_repositories and user_repositories
        else
          @user_repositories ||= YAML.load(yaml_cache).tap do |projects|
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
        refresh_repositories and user_repositories
      end
    end

    def missing_repositories
      user_repositories.find_all { |project|
        !File.directory? project.local_path
      }
    end

    def cloned_repositories
      user_repositories.find_all { |project|
        File.directory? project.local_path
      }
    end

  end
end
