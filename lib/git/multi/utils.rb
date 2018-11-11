module Git
  module Multi

    module Settings

      module_function

      def describe(token)
        if token.nil?
          '(nil)'
        elsif token.empty?
          '(empty)'
        else
          "#{'*' * 36}#{token[36..-1]}"
        end
      end

      def symbolize(token)
        case token
        when Git::Multi.env_var('OCTOKIT_ACCESS_TOKEN')
          then '${OCTOKIT_ACCESS_TOKEN}'
        when Git::Multi.global_option('github.token')
          then 'github.token'
        else '(unset)'
        end
      end

      def abbreviate(directory, root_dir = nil)
        case root_dir
        when :home
          then directory.gsub(Git::Multi::HOME, '${HOME}')
        when :workarea
          then directory.gsub(Git::Multi::WORKAREA, '${WORKAREA}')
        else abbreviate(abbreviate(directory, :workarea), :home)
        end
      end

    end

    module_function

    def local_option(path, name, default = nil)
      value = `git -C #{path} config --local --get #{name}`.chomp.freeze
      value.empty? && default ? default : value
    end

    def local_list(filename, name)
      list = `git config --file #{filename} --get-all #{name}`
      list.split($RS).map(&:strip).map(&:freeze)
    end

    def global_option(name, default = nil)
      value = `git config --global --get #{name}`.chomp.freeze
      value.empty? && default ? default : value
    end

    def global_list(name, default = nil)
      global_option(name, default).split(',').map(&:strip).map(&:freeze)
    end

    def env_var(name, default = nil)
      value = ENV[name].dup.freeze
      (value.nil? || value.empty?) && default ? default : value
    end

  end
end
