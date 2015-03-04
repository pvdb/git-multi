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

    end
  end
end
