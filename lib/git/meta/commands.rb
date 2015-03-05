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

      def list
        puts Git::Meta.user_repositories.map(&:full_name)
      end

      def missing
        puts Git::Meta.missing_repositories.map(&:full_name)
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

    end
  end
end
