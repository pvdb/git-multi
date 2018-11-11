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
  end
end
