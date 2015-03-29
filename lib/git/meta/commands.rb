module Git
  module Meta
    module Commands

      module_function

      def version
        puts Git::Meta::VERSION
      end

      def user
        puts Git::Meta::USER
      end

      def files
        puts Git::Meta::JSON_CACHE
        puts Git::Meta::YAML_CACHE
      end

      def help
        # instead of maintaining a list of valid query args in the help-
        # file, we determine it at runtime... less is more, and all that
        # TODO remove attributes we 'adorned' the repos with on line 95?
        query_args = Git::Meta::github_repositories.sample.fields.sort.each_slice(3).map {
          |foo, bar, qux| '%-20s  %-20s %-20s' % [foo, bar, qux]
        }
        puts File.read(Git::Meta::MAN_PAGE) % {
          :version => Git::Meta::VERSION,
          :query_args => query_args.join("\n    "),
        }
      end

      def report
        if (missing_repos = Git::Meta::missing_repositories).any?
          Git::Meta::notify(missing_repos.map(&:full_name), :subtitle => "#{missing_repos.count} missing repos")
        end
      end

      def orgs
        puts Git::Meta.github_organizations.map(&:login)
      end

      def list
        puts Git::Meta.repositories.map(&:full_name)
      end

      def missing
        puts Git::Meta.missing_repositories.map(&:full_name)
      end

      def excess
        puts Git::Meta.excess_repositories.map(&:full_name)
      end

      def stale
        puts Git::Meta.stale_repositories.map(&:full_name)
      end

      def token
        puts Git::Meta::TOKEN
      end

      def check
        login = begin
          Git::Meta.client.user.login
        rescue Octokit::Unauthorized
          nil
        end
        if login
          puts "#{'SUCCESS'.bold}: github user: %s ; github login: %s" % [Git::Meta::USER, login]
        else
          puts "#{'ERROR'.bold}: 401 - Bad credentials"
        end
      end

      def count
        #
        # From: https://developer.github.com/v3/repos/#list-user-repositories
        #
        # `type` - can be one of `all`, `owner`, `member`
        #          (default: `owner`)
        #
        %w{ all owner member }.each { |type|
          puts [type, Git::Meta.user_repositories(type).count].join("\t")
        }
      end

      def refresh
        Git::Meta.refresh_repositories
      end

      def clone
        Git::Meta.missing_repositories.each do |project|
          project_ssh_url = project.rels[:ssh].href
          project.just_do_it(
            ->(project) {
              Kernel.system "git clone #{project_ssh_url.shellescape}"
            },
            ->(project) {
              Kernel.system "git clone -q #{project_ssh_url.shellescape}"
            },
            :in_dir => :parent_dir
          )
        end
      end

      def query args = []
        Git::Meta.repositories.each do |project|
          project.just_do_it(
            ->(project) {
              args.each do |attribute|
                puts "#{attribute}: #{project[attribute]}"
              end
            },
            ->(project) {
              print "#{project.full_name}: "
              puts args.map { |attribute| project[attribute] }.join(' ')
            },
          )
        end
      end

      def system args = []
        args.map!(&:shellescape)
        Git::Meta.cloned_repositories.each do |project|
          project.just_do_it(
            ->(project) {
              Kernel.system "#{args.join(' ')}"
            },
            ->(project) {
              Kernel.system "#{args.join(' ')} 2>&1 | sed -e 's#^##{project.full_name.shellescape}: #'"
            },
            :in_dir => :local_path
          )
        end
      end

      def raw args
        args.unshift ['sh', '-c']
        system args.flatten
      end

      def exec command, args = []
        args.unshift ['git', command]
        system args.flatten
      end

      def eval command
        Git::Meta.cloned_repositories.each do |project|
          Dir.chdir(project.local_path) do
            project.instance_eval(command)
          end
        end
      end

    end
  end
end
