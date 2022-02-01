module Git
  module Multi
    module Commands
      module_function

      def version
        dependencies = [
          "octokit.rb v#{Octokit::VERSION}",
          "sawyer v#{Sawyer::VERSION}",
          "faraday v#{Faraday::VERSION}",
          "addressable v#{Addressable::VERSION::STRING}",
          "#{RUBY_ENGINE} #{RUBY_VERSION}p#{RUBY_PATCHLEVEL}",
        ].join(', ')

        puts "#{Git::Multi::NAME} v#{Git::Multi::VERSION} (#{dependencies})"
      end

      def help
        Kernel.exec "man #{Git::Multi::MAN_PAGE}"
      end

      def html
        Kernel.exec "open #{Git::Multi::HTML_PAGE}"
      end

      def report(multi_repo = nil)
        case multi_repo
        when nil
          Report.home_status(Git::Multi::HOME)
          Report.workarea_status(Git::Multi::WORKAREA)
          Report.for(*MULTI_REPOS)
        when *MULTI_REPOS
          Report.for(multi_repo)
        else
          raise ArgumentError, multi_repo
        end
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

      def list(multi_repo = nil)
        puts Git::Multi.repositories_for(multi_repo).map(&:full_name)
      end

      def archived(multi_repo = nil)
        puts Git::Multi.archived_repositories_for(multi_repo).map(&:full_name)
      end

      def forked(multi_repo = nil)
        puts Git::Multi.forked_repositories_for(multi_repo).map(&:full_name)
      end

      def private(multi_repo = nil)
        puts Git::Multi.private_repositories_for(multi_repo).map(&:full_name)
      end

      def paths(multi_repo = nil)
        puts Git::Multi.repositories_for(multi_repo).map(&:local_path)
      end

      def missing(multi_repo = nil)
        puts Git::Multi.missing_repositories_for(multi_repo).map(&:full_name)
      end

      def clone(multi_repo = nil)
        Git::Multi.missing_repositories_for(multi_repo).each do |repository|
          FileUtils.mkdir_p repository.parent_dir # create multi-repo workarea
          repository.just_do_it(
            ->(repo) {
              Kernel.system "git clone -q #{repo.rels[:ssh].href.shellescape}"
            },
            ->(repo) {
              Kernel.system "git clone -q #{repo.rels[:ssh].href.shellescape}"
            },
            nil, # captured
            in: 'parent_dir'
          )
        end
      end

      def stale(multi_repo = nil)
        puts Git::Multi.stale_repositories_for(multi_repo).map(&:full_name)
      end

      def excess(multi_repo = nil)
        puts Git::Multi.excess_repositories_for(multi_repo).map(&:full_name)
      end

      def spurious(multi_repo = nil)
        puts Git::Multi.spurious_repositories_for(multi_repo).map(&:full_name)
      end

      def query(args = [], multi_repo = nil)
        Git::Multi.repositories_for(multi_repo).each do |repository|
          repository.just_do_it(
            ->(repo) {
              args.each do |attribute|
                puts "#{attribute}: #{repo[attribute]}"
              end
            },
            ->(repo) {
              print "#{repo.full_name}: "
              puts args.map { |attribute| repo[attribute] }.join(' ')
            },
          )
        end
      end

      def find(commands, multi_repo = nil)
        Git::Multi.cloned_repositories_for(multi_repo).each do |repository|
          Dir.chdir(repository.local_path) do
            begin
              if repository.instance_eval(commands.join(' && '))
                repository.just_do_it(
                  ->(_repo) {}, # empty lambda: nil
                  ->(repo) { puts repo.full_name },
                )
              end
            rescue Octokit::NotFound
              # repository no longer exists on GitHub
              # consider running "git multi --stale"!
            end
          end
        end
      end

      def eval(commands, multi_repo)
        Git::Multi.cloned_repositories_for(multi_repo).each do |repo|
          Dir.chdir(repo.local_path) do
            begin
              repo.instance_eval(commands.join(' ; '))
            rescue Octokit::NotFound
              # repository no longer exists on GitHub
              # consider running "git multi --stale"!
            end
          end
        end
      end

      def shell(args, multi_repo)
        args.unshift [ENV.fetch('SHELL', '/bin/sh'), '-l']
        system(args.flatten, multi_repo)
      end

      def raw(args, multi_repo = nil)
        args.unshift ['sh', '-c']
        system(args.flatten, multi_repo)
      end

      def exec(command, args = [], multi_repo = nil)
        args.unshift ['git', '--no-pager', command]
        system(args.flatten, multi_repo)
      end

      def system(args = [], multi_repo = nil)
        cmd = args.map!(&:shellescape).join(' ')
        Git::Multi.cloned_repositories_for(multi_repo).each do |repository|
          repository.just_do_it(
            ->(_repo) {
              Kernel.system cmd
            },
            ->(repo) {
              prefix = "sed -e 's#^##{repo.full_name.shellescape}: #'"
              Kernel.system "#{cmd} 2>&1 | #{prefix} ;"
            },
            ->(repo, errors) {
              #
              # because `Kernel.system()` uses the standard shell,
              # which always means "/bin/sh" on Unix-like systems,
              # the following version using "process substitution"
              # doesn't work:
              #
              # Kernel.system "#{cmd} 2> >(#{prefix}) | #{prefix} ;"
              #
              prefix = "sed -e 's#^##{repo.full_name.shellescape}: #'"
              Kernel.system "#{cmd} 2> #{errors} | #{prefix} ;"
            },
            in: 'local_path'
          )
        end
      end

      private_class_method :system
    end
  end
end
