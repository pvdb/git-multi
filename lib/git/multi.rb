require 'etc'
require 'json'
require 'pathname'
require 'fileutils'
require 'shellwords'

require 'octokit'
require 'sawyer'

require 'ext/dir'
require 'ext/string'
require 'ext/notify'
require 'ext/kernel'
require 'ext/commify'
require 'ext/sawyer/resource'

require 'git/hub'

require 'git/multi/utils'
require 'git/multi/version'
require 'git/multi/settings'
require 'git/multi/commands'

module Git
  module Multi

    HOME             = Dir.home

    DEFAULT_WORKAREA = File.join(HOME, 'Workarea')
    WORKAREA         = git_option('git.multi.workarea', DEFAULT_WORKAREA)

    DEFAULT_TOKEN    = env_var('OCTOKIT_ACCESS_TOKEN') # same as Octokit
    TOKEN            = git_option('github.token', DEFAULT_TOKEN)

    CACHE            = File.join(HOME, '.git', 'multi')
    REPOSITORIES     = File.join(CACHE, 'repositories.byte')

    USERS            = git_list('github.users')
    ORGANIZATIONS    = git_list('github.organizations')

    MAN_PAGE         = File.expand_path('../../man/git-multi.1', __dir__)
    HTML_PAGE        = File.expand_path('../../man/git-multi.html', __dir__)

    module_function

    #
    # multi-repo support
    #

    def valid?(multi_repo)
      (USERS + ORGANIZATIONS).include? multi_repo
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
      @local_repositories ||= (
        USERS.map { |user| @local_user_repositories[user] } +
        ORGANIZATIONS.map { |org| @local_org_repositories[org] }
      ).flatten
    end

    def local_repositories_for(multi_repo = nil)
      case (owner = multi_repo)
      when nil
        local_repositories
      when *USERS
        @local_user_repositories[owner]
      when *ORGANIZATIONS
        @local_org_repositories[owner]
      else
        raise "Unknown multi repo: #{multi_repo}"
      end
    end

    #
    # remote repositories (on GitHub)
    #

    @github_user_repositories = Hash.new { |repos, user|
      repos[user] = Git::Hub.user_repositories(user)
    }

    @github_org_repositories = Hash.new { |repos, org|
      repos[org] = Git::Hub.org_repositories(org)
    }

    def github_repositories
      @github_repositories ||= (
        USERS.map { |user| @github_user_repositories[user] } +
        ORGANIZATIONS.map { |org| @github_org_repositories[org] }
      ).flatten
    end

    def github_repositories_for(multi_repo = nil)
      case (owner = multi_repo)
      when nil
        github_repositories
      when *USERS
        @github_user_repositories[owner]
      when *ORGANIZATIONS
        @github_org_repositories[owner]
      else
        raise "Unknown multi repo: #{multi_repo}"
      end
    end

    #
    # manage the local repository cache
    #

    def refresh_repositories
      File.directory?(CACHE) || FileUtils.mkdir_p(CACHE)

      File.open(REPOSITORIES, 'wb') do |file|
        Marshal.dump(github_repositories, file)
      end
    end

    #
    # the main `Git::Multi` capabilities
    #

    module Nike

      def just_do_it(interactive, pipeline, options = {})
        working_dir = case (options[:in] || '').to_sym
                      when :parent_dir then parent_dir
                      when :local_path then local_path
                      else Dir.pwd
                      end
        Dir.chdir(working_dir) do
          if interactive?
            puts "#{full_name.invert} (#{fractional_index})"
            interactive.call(self)
          else
            pipeline.call(self)
          end
        end
      end

    end

    def repositories
      if File.size?(REPOSITORIES)
        # rubocop:disable Security/MarshalLoad
        @repositories ||= Marshal.load(File.read(REPOSITORIES)).tap do |projects|
          notify "Finished loading #{REPOSITORIES}"
          projects.each_with_index do |project, index|
            # ensure 'project' has handle on an Octokit client
            project.client = Git::Hub.send(:client)
            # adorn 'project', which is a Sawyer::Resource
            project.parent_dir = Pathname.new(File.join(WORKAREA, project.owner.login))
            project.local_path = Pathname.new(File.join(WORKAREA, project.full_name))
            project.fractional_index = "#{index + 1}/#{projects.count}"
            # fix 'project' => https://github.com/octokit/octokit.rb/issues/727
            project.compliant_ssh_url = 'ssh://' + project.ssh_url.split(':', 2).join('/')
            # remove optional '.git' suffix from 'git@github.com:pvdb/git-multi.git'
            project.abbreviated_ssh_url = project.ssh_url.chomp('.git')
            # extend 'project' with 'just do it' capabilities
            project.extend Nike
          end
        end
        # rubocop:enable Security/MarshalLoad
      else
        refresh_repositories
        repositories # retry
      end
    end

    #
    # lists of repos for a given multi-repo
    #

    def repositories_for(multi_repo = nil)
      if multi_repo.nil?
        repositories
      else
        repositories.find_all { |repository|
          repository.owner.login == multi_repo
        }
      end
    end

    #
    # lists of repositories with a given state
    #

    def archived_repositories_for(multi_repo = nil)
      repositories_for(multi_repo).find_all(&:archived)
    end

    def forked_repositories_for(multi_repo = nil)
      repositories_for(multi_repo).find_all(&:fork)
    end

    def private_repositories_for(multi_repo = nil)
      repositories_for(multi_repo).find_all(&:private)
    end

    #
    # derived lists of repositories
    #

    def excess_repositories_for(multi_repo = nil)
      repository_full_names = repositories_for(multi_repo).map(&:full_name)
      local_repositories_for(multi_repo).reject { |project|
        repository_full_names.include? project.full_name
      }
    end

    def stale_repositories_for(multi_repo = nil)
      repository_full_names = github_repositories_for(multi_repo).map(&:full_name)
      repositories_for(multi_repo).reject { |project|
        repository_full_names.include? project.full_name
      }
    end

    def spurious_repositories
      cloned_repositories.find_all { |project|
        origin_url = `git -C #{project.local_path} config --get remote.origin.url`.chomp
        ![
          project.clone_url,
          project.ssh_url,
          project.compliant_ssh_url,
          project.abbreviated_ssh_url,
          project.git_url,
        ].include? origin_url
      }
    end

    def missing_repositories_for(multi_repo = nil)
      repositories_for(multi_repo).find_all { |project|
        !File.directory? project.local_path
      }
    end

    def cloned_repositories_for(multi_repo = nil)
      repositories_for(multi_repo).find_all { |project|
        File.directory? project.local_path
      }
    end

  end
end
