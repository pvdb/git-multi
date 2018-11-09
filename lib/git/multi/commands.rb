module Git
  module Multi
    module Commands

      module_function

      def version
        puts Git::Multi::LONG_VERSION
      end

      def check
        # Settings.user_status(Git::Multi::USER)
        # Settings.organization_status(Git::Multi::ORGANIZATIONS)
        # Settings.token_status(Git::Multi::TOKEN)
        Settings.home_status(Git::Multi::HOME)
        Settings.main_workarea_status(Git::Multi::WORKAREA)
        Settings.user_workarea_status(Git::Multi::USERS)
        Settings.organization_workarea_status(Git::Multi::ORGANIZATIONS)
        # Settings.file_status(Git::Multi::REPOSITORIES)
      end

      def help
        Kernel.exec "man #{Git::Multi::MAN_PAGE}"
      end

      def html
        Kernel.exec "open #{Git::Multi::HTML_PAGE}"
      end

      def report
        (missing_repos = Git::Multi.missing_repositories).any? &&
          notify(missing_repos.map(&:full_name), subtitle: "#{missing_repos.count} missing repos")
      end

      def list(multi_repo = nil)
        puts Git::Multi.repositories_for(multi_repo).map(&:full_name)
      end

      def archived
        puts Git::Multi.archived_repositories.map(&:full_name)
      end

      def forked
        puts Git::Multi.forked_repositories.map(&:full_name)
      end

      def private
        puts Git::Multi.private_repositories.map(&:full_name)
      end

      def paths(multi_repo = nil)
        puts Git::Multi.repositories_for(multi_repo).map(&:local_path)
      end

      def missing(multi_repo = nil)
        puts Git::Multi.missing_repositories_for(multi_repo).map(&:full_name)
      end

      def excess
        puts Git::Multi.excess_repositories.map(&:full_name)
      end

      def stale
        puts Git::Multi.stale_repositories.map(&:full_name)
      end

      def spurious
        puts Git::Multi.spurious_repositories.map(&:full_name)
      end

      def count
        # https://developer.github.com/v3/repos/#list-user-repositories
        Git::Multi::USERS.each do |user|
          %w[all owner member].each { |type|
            puts ["#{user}/#{type}", Git::Hub.user_repositories(user, type).count].join("\t")
          }
        end
        # https://developer.github.com/v3/repos/#list-organization-repositories
        Git::Multi::ORGANIZATIONS.each do |org|
          %w[all public private forks sources member].each { |type|
            puts ["#{org}/#{type}", Git::Hub.org_repositories(org, type).count].join("\t")
          }
        end
      end

      def refresh
        Git::Multi.refresh_repositories
      end

      def json(multi_repo = nil)
        puts Git::Multi.repositories_for(multi_repo).to_json
      end

      def clone(multi_repo)
        Git::Multi.missing_repositories_for(multi_repo).each do |repo|
          FileUtils.mkdir_p repo.parent_dir
          repo.just_do_it(
            ->(project) {
              notify "Cloning '#{repo.full_name}' repo into #{repo.parent_dir.parent}"
              Kernel.system "git clone -q #{project.rels[:ssh].href.shellescape}"
            },
            ->(project) {
              Kernel.system "git clone -q #{project.rels[:ssh].href.shellescape}"
            },
            in: 'parent_dir'
          )
        end
      end

      def query(args = [])
        Git::Multi.repositories.each do |repo|
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

      def system(args = [], multi_repo = nil)
        cmd = args.map!(&:shellescape).join(' ')
        Git::Multi.cloned_repositories_for(multi_repo).each do |repo|
          repo.just_do_it(
            ->(_project) {
              Kernel.system cmd
            },
            ->(project) {
              Kernel.system "#{cmd} 2>&1 | sed -e 's#^##{project.full_name.shellescape}: #'"
            },
            in: 'local_path'
          )
        end
      end

      def raw(args)
        args.unshift ['sh', '-c']
        system args.flatten
      end

      def exec(command, args = [], multi_repo = nil)
        args.unshift ['git', '--no-pager', command]
        system(args.flatten, multi_repo)
      end

      def find(commands)
        Git::Multi.cloned_repositories.each do |repo|
          Dir.chdir(repo.local_path) do
            if repo.instance_eval(commands.join(' && '))
              repo.just_do_it(
                ->(_project) { nil },
                ->(project) { puts project.full_name },
              )
            end
          rescue Octokit::NotFound
            # project no longer exists on github.com
            # consider running "git multi --stale"...
          end
        end
      end

      def eval(commands)
        Git::Multi.cloned_repositories.each do |repo|
          Dir.chdir(repo.local_path) do
            repo.instance_eval(commands.join(' ; '))
          rescue Octokit::NotFound
            # project no longer exists on github.com
            # consider running "git multi --stale"...
          end
        end
      end

    end
  end
end
