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
        when Git::Multi.git_option('github.token')
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

    def git_all(config, name)
      list = `git config --file #{config} --get-all #{name}`
      list.split($RS).map(&:strip)
    end

    def git_local(path, name, default = nil)
      value = `git -C #{path} config --get #{name}`.chomp.freeze
      value.empty? && default ? default : value
    end

    def git_option(name, default = nil)
      value = `git config #{name}`.chomp.freeze
      value.empty? && default ? default : value
    end

    def git_list(name, default = nil)
      git_option(name, default).split(',').map(&:strip)
    end

    def env_var(name, default = nil)
      value = ENV[name].freeze
      (value.nil? || value.empty?) && default ? default : value
    end

  end
end
