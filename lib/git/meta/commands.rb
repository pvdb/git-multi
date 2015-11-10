module Git
  module Meta
    module Commands

      module_function

      def version
        puts Git::Meta::VERSION
      end

      def check
        Settings.user_status(Git::Meta::USER)
        Settings.organization_status(Git::Meta::ORGANIZATIONS)
        Settings.token_status(Git::Meta::TOKEN)
        Settings.home_status(Git::Meta::HOME)
        Settings.main_workarea_status(Git::Meta::WORKAREA)
        Settings.user_workarea_status(Git::Meta::USER)
        Settings.organization_workarea_status(Git::Meta::ORGANIZATIONS)
        Settings.yaml_cache_status(Git::Meta::YAML_CACHE)
        Settings.json_cache_status(Git::Meta::JSON_CACHE)
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

      def spurious
        puts Git::Meta.spurious_repositories.map(&:full_name)
      end

      def count
        # https://developer.github.com/v3/repos/#list-user-repositories
        user = Git::Meta::USER
        %w{ all owner member }.each { |type|
          puts ["#{user}/#{type}", Git::Meta.github_user_repositories(user, type).count].join("\t")
        }
        # https://developer.github.com/v3/repos/#list-organization-repositories
        for org in Git::Meta::ORGANIZATIONS
          %w{ all public private forks sources member }.each { |type|
            puts ["#{org}/#{type}", Git::Meta.github_org_repositories(org, type).count].join("\t")
          }
        end
      end

      def refresh
        Git::Meta.refresh_repositories
      end

      def clone
        Git::Meta.missing_repositories.each do |repo|
          FileUtils.mkdir_p repo.parent_dir
          repo.just_do_it(
            ->(project) {
              Kernel.system "git clone #{project.rels[:ssh].href.shellescape}"
            },
            ->(project) {
              Kernel.system "git clone -q #{project.rels[:ssh].href.shellescape}"
            },
            :in_dir => :parent_dir
          )
        end
      end

      def query args = []
        Git::Meta.repositories.each do |repo|
          repo.just_do_it(
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
        Git::Meta.cloned_repositories.each do |repo|
          repo.just_do_it(
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
            begin
              project.instance_eval(command)
            rescue Octokit::NotFound
              # project no longer exists on github.com
              # consider running "git meta --stale"...
            end
          end
        end
      end

    end
  end
end
