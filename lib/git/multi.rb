require 'etc'
require 'json'
require 'tmpdir'
require 'pathname'
require 'fileutils'
require 'shellwords'

require 'English'

require 'octokit'
require 'sawyer'
require 'faraday'
require 'addressable'

require 'ext/dir'
require 'ext/string'
require 'ext/commify'
require 'ext/sawyer/resource'

require 'git/hub'

require 'git/multi/config'
require 'git/multi/report'
require 'git/multi/version'
require 'git/multi/commands'

module Git
  module Multi
    class Error < StandardError; end

    HOME             = Dir.home

    DEFAULT_WORKAREA = File.join(HOME, 'Workarea')
    WORKAREA         = global_option('git.multi.workarea', DEFAULT_WORKAREA)

    DEFAULT_TOKEN    = env_var('OCTOKIT_ACCESS_TOKEN') # same as Octokit
    TOKEN            = global_option('github.token', DEFAULT_TOKEN)

    GIT_MULTI_DIR    = File.join(HOME, '.git', 'multi')
    GITHUB_CACHE     = File.join(GIT_MULTI_DIR, 'repositories.byte')

    USERS            = global_list('git.multi.users')
    ORGANIZATIONS    = global_list('git.multi.organizations')
    SUPERPROJECTS    = global_list('git.multi.superprojects')

    MULTI_REPOS      = (USERS + ORGANIZATIONS + SUPERPROJECTS)
    EXCLUDED_REPOS   = global_options('git.multi.exclude')

    MAN_PAGE         = File.expand_path('../../man/git-multi.1', __dir__)
    HTML_PAGE        = File.expand_path('../../man/git-multi.html', __dir__)

    module_function

    #
    # multi-repo support
    #

    def valid?(multi_repo)
      MULTI_REPOS.include? multi_repo
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

    def local_repositories_for(owner = nil)
      case owner
      when nil
        local_repositories # all of them
      when *USERS
        @local_user_repositories[owner]
      when *ORGANIZATIONS
        @local_org_repositories[owner]
      else
        raise "Unknown owner: #{owner}"
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

    def github_repositories_for(owner = nil)
      case owner
      when nil
        github_repositories # all of them
      when *USERS
        @github_user_repositories[owner]
      when *ORGANIZATIONS
        @github_org_repositories[owner]
      else
        raise "Unknown owner: #{owner}"
      end
    end

    #
    # manage the local repository cache
    #

    def refresh_repositories
      # ensure `~/.git/multi` directory exists
      FileUtils.mkdir_p(GIT_MULTI_DIR)

      File.open(GITHUB_CACHE, 'wb') do |file|
        Marshal.dump(github_repositories, file)
      end
    end

    #
    # the main `Git::Multi` capabilities
    #

    module Nike
      # rubocop:disable Metrics/PerceivedComplexity
      # rubocop:disable Metrics/CyclomaticComplexity
      def just_do_it(interactive, pipelined, captured = nil, options = {})
        working_dir = case (options[:in] || '').to_sym
                      when :parent_dir then parent_dir
                      when :local_path then local_path
                      else Dir.pwd
                      end
        Dir.chdir(working_dir) do
          if $stdout.tty? && $stderr.tty?
            $stdout.puts "#{full_name.invert} (#{fractional_index})"
            interactive.call(self)
          elsif $stderr.tty? && captured
            errors = File.join(Dir.tmpdir, "git-multi.#{$PID}")
            captured.call(self, errors)
            if File.exist?(errors) && !File.zero?(errors)
              # rubocop:disable Style/StderrPuts
              $stderr.puts "#{full_name.invert} (#{fractional_index})"
              Kernel.system "cat #{errors} > /dev/tty ;"
              # rubocop:enable Style/StderrPuts
            end
          else
            pipelined.call(self)
          end
        end
      end
      # rubocop:enable Metrics/CyclomaticComplexity
      # rubocop:enable Metrics/PerceivedComplexity

      def spputs(*args)
        # split, prefix and puts
        args.each do |arg|
          case arg
          when Array
            arg.each do |argh| puts("#{full_name}: #{argh}"); end
          when String
            spputs(arg.split($RS))
          else
            ssputs(arg.to_s)
          end
        end
      end
    end

    def repositories
      if File.size?(GITHUB_CACHE)
        # rubocop:disable Security/MarshalLoad
        @repositories ||= Marshal.load(File.read(GITHUB_CACHE)).tap do |repos|
          repos.each_with_index do |repo, index|
            # ensure 'repo' has handle on an Octokit client
            repo.client = Git::Hub.send(:client)
            # adorn 'repo', which is a Sawyer::Resource
            repo.parent_dir = Pathname.new(File.join(WORKAREA, repo.owner.login))
            repo.local_path = Pathname.new(File.join(WORKAREA, repo.full_name))
            repo.fractional_index = "#{index + 1}/#{repos.count}"
            # git multi will "hard ignore" all excluded repos
            repo.excluded = EXCLUDED_REPOS.include?(repo.full_name)
            # fix 'repo' => https://github.com/octokit/octokit.rb/issues/727
            repo.compliant_ssh_url = "ssh://#{repo.ssh_url.split(':', 2).join('/')}"
            # remove optional '.git' suffix from 'git@github.com:pvdb/git-multi.git'
            repo.abbreviated_ssh_url = repo.ssh_url.chomp('.git')
            # extend 'repo' with 'just do it' capabilities
            repo.extend Nike
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

    def full_names_for(superproject)
      global_options("superproject.#{superproject}.repo")
    end

    def all_repositories_for(multi_repo = nil)
      case (owner = superproject = full_names = multi_repo)
      when nil
        repositories # all of them
      when Array
        repositories.find_all { |repository|
          full_names.include?(repository.full_name)
        }
      when *USERS, *ORGANIZATIONS
        repositories.find_all { |repository|
          repository.owner.login == owner
        }
      when *SUPERPROJECTS
        all_repositories_for(full_names_for(superproject))
      else
        raise ArgumentError, multi_repo
      end
    end

    def repositories_for(multi_repo = nil)
      all_repositories_for(multi_repo).delete_if(&:excluded)
    end

    #
    # lists of repositories with a given state
    #

    def archived_repositories_for(multi_repo = nil)
      all_repositories_for(multi_repo).find_all(&:archived)
    end

    def forked_repositories_for(multi_repo = nil)
      all_repositories_for(multi_repo).find_all(&:fork)
    end

    def private_repositories_for(multi_repo = nil)
      all_repositories_for(multi_repo).find_all(&:private)
    end

    def excluded_repositories_for(multi_repo = nil)
      all_repositories_for(multi_repo).find_all(&:excluded)
    end

    #
    # derived lists of repositories
    #

    def excess_repositories_for(multi_repo = nil)
      repository_full_names = repositories_for(multi_repo).map(&:full_name)
      local_repositories_for(multi_repo).reject { |repo|
        repository_full_names.include? repo.full_name
      }
    end

    def stale_repositories_for(multi_repo = nil)
      repository_full_names = github_repositories_for(multi_repo).map(&:full_name)
      repositories_for(multi_repo).reject { |repo|
        repository_full_names.include? repo.full_name
      }
    end

    def spurious_repositories_for(multi_repo = nil)
      cloned_repositories_for(multi_repo).find_all { |repo|
        origin_url = local_option(repo.local_path, 'remote.origin.url')

        ![
          repo.clone_url,
          repo.ssh_url,
          repo.compliant_ssh_url,
          repo.abbreviated_ssh_url,
          repo.git_url,
        ].include? origin_url
      }
    end

    def missing_repositories_for(multi_repo = nil)
      repositories_for(multi_repo).find_all { |repo|
        !File.directory? repo.local_path
      }
    end

    def cloned_repositories_for(multi_repo = nil)
      repositories_for(multi_repo).find_all { |repo|
        File.directory? repo.local_path
      }
    end
  end
end
