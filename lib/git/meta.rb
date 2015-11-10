require 'etc'
require 'yaml'
require 'fileutils'
require 'shellwords'

require 'ext/dir'
require 'ext/utils'
require 'ext/string'
require 'ext/notify'
require 'ext/commify'
require 'ext/sawyer/resource'

require 'git/hub'

require 'git/meta/version'
require 'git/meta/settings'
require 'git/meta/commands'
require 'git/meta/nike'
require 'git/meta/persistent'

module Git
  module Meta

    MAN_PAGE = File.expand_path('../../../doc/git-meta.man', __FILE__)

    module_function

    USER          = git_option 'github.user'
    ORGANIZATIONS = git_option('github.organizations').split(/\s*,\s*/)

    HOME          = env_var 'HOME', Etc.getpwuid.dir

    WORKAREA      = git_option 'gitmeta.workarea',  File.join(HOME, 'Workarea')
    YAML_CACHE    = git_option 'gitmeta.yamlcache', File.join(HOME, '.gitmeta.yaml')
    JSON_CACHE    = git_option 'gitmeta.jsoncache', File.join(HOME, '.gitmeta.json')

    def abbreviate directory, root_dir = nil
      case root_dir
      when :home     then directory.gsub Regexp.escape(Git::Meta::HOME),     '${HOME}'
      when :workarea then directory.gsub Regexp.escape(Git::Meta::WORKAREA), '${WORKAREA}'
      else
        abbreviate(abbreviate(directory, :workarea), :home)
      end
    end

    #
    # local repositories (in WORKAREA)
    #

    @local_user_repositories = Hash.new { |repos, user|
      repos[user] = Dir.new(WORKAREA).git_repos(user)
    }

    @local_org_repositories = Hash.new { |repos, org|
      repos[org] = Dir.new(WORKAREA).git_repos(org)
    }

    def local_repositories
      (
        @local_user_repositories[USER] +
        ORGANIZATIONS.map { |org| @local_org_repositories[org] }
      ).flatten
    end

    #
    # remote repositories (on GitHub)
    #

    def github_repositories
      @github_repositories ||= (
        Git::Hub.user_repositories(USER) +
        ORGANIZATIONS.map { |org| Git::Hub.org_repositories(org) }
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

    #
    # the main entry point for `Git::Meta`
    #

    def repositories
      if File.size? YAML_CACHE
        @repositories ||= YAML.load(File.read(YAML_CACHE)).tap do |projects|
          notify "Finished loading #{YAML_CACHE}"
          projects.each_with_index do |project, index|
            # ensure #method_missing works for Sawyer::Resource instances
            project.instance_eval("@_metaclass = (class << self; self ; end)")
            project.owner.instance_eval("@_metaclass = (class << self; self ; end)")
            # adorn 'project', which is a Sawyer::Resource
            project.parent_dir = File.join(WORKAREA, project.owner.login)
            project.local_path = File.join(WORKAREA, project.full_name)
            project.fractional_index = "#{index + 1}/#{projects.count}"
            # ensure 'project' has handle on an Octokit client
            def project.client() @client ||= Git::Hub.send(:client) ; end
            # extend 'project' with 'just do it' capabilities
            project.extend Nike
            # extend 'project' with some cheeky knowledge
            # project.extend Prometheus
          end
        end
      else
        refresh_repositories and repositories
      end
    end

    #
    # derived lists of repositories
    #

    def excess_repositories
      repository_full_names = repositories.map(&:full_name)
      local_repositories.reject { |project|
        repository_full_names.include? project.full_name
      }
    end

    def stale_repositories
      repository_full_names = github_repositories.map(&:full_name)
      repositories.reject { |project|
        repository_full_names.include? project.full_name
      }
    end

    def spurious_repositories
      cloned_repositories.find_all { |project|
        origin_url = `git -C #{project.local_path} config --get remote.origin.url`.chomp
        ![project.clone_url, project.ssh_url, project.git_url].include? origin_url
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
