module Git
  module Multi
    module Report

      TICK  = ['2714'.hex].pack('U*').green.freeze
      CROSS = ['2718'.hex].pack('U*').red.freeze
      ARROW = ['2794'.hex].pack('U*').blue.freeze

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

      def setting_status(messages, valid = false, optional = true)
        fields = messages.compact.join(' - ')
        icon = valid ? TICK : optional ? ARROW : CROSS
        puts "#{icon}  #{fields}"
      end

      def file_status(file, message = 'File')
        setting_status(
          [
            message,
            abbreviate(file),
            File.file?(file) ? "#{File.size(file).commify} bytes" : nil,
          ],
          file && !file.empty? && File.file?(file),
          false
        )
      end

      def directory_status(messages, directory)
        setting_status(
          messages,
          directory && !directory.empty? && File.directory?(directory),
          false
        )
      end

      def owner_status(message, workarea, owner)
        directory_status(
          [
            message,
            File.join(abbreviate(workarea, :workarea), owner),
          ],
          File.join(workarea, owner)
        )

        github_count = Git::Multi.repositories_for(owner).count
        cloned_count = Git::Multi.cloned_repositories_for(owner).count
        missing_count = (github_count - cloned_count)
        subdir_count = Dir.new(workarea).git_repos(owner).count
        surplus_count = (subdir_count - cloned_count)

        setting_status(["\tGitHub ", "#{github_count} repositories"])
        setting_status(["\tcloned ", cloned_count, "(#{missing_count} missing)"])
        Git::Multi.missing_repositories_for(owner).each do |missing|
          setting_status(["\tmissing", missing.full_name], false, false)
        end
        setting_status(["\tsubdirs", subdir_count, "(#{surplus_count} surplus)"])
      end

      def project_status(message, superproject)
        github_count = Git::Multi.repositories_for(superproject).count

        if github_count.zero?
          setting_status([message, 'listed but not configured'], false, false)
        else
          setting_status([message], true)

          cloned_count = Git::Multi.cloned_repositories_for(superproject).count
          missing_count = (github_count - cloned_count)

          setting_status(["\tGitHub ", "#{github_count} repositories"])
          setting_status(["\tcloned ", cloned_count, "(#{missing_count} missing)"])
          Git::Multi.missing_repositories_for(superproject).each do |missing|
            setting_status(["\tmissing", missing.full_name], false, false)
          end
        end
      end

      def user_status(user)
        setting_status(['User', user], user && !user.empty?)
      end

      def organization_status(orgs)
        orgs.each do |org|
          setting_status(['Organization', org], org && !org.empty?, true)
          setting_status(['Organization', 'member?'], Git::Hub.orgs.include?(org), !Git::Hub.connected?)
        end
      end

      def token_status(token)
        setting_status(['Token', symbolize(token), describe(token)], !token.nil? && !token.empty?)
        setting_status(['Token', 'valid?'], !token.nil? && !token.empty? && Git::Hub.login, !Git::Hub.connected?)
        setting_status(['Token', "owned by #{Git::Multi::USER}?"], Git::Hub.login == Git::Multi::USER, !Git::Hub.connected?)
      end

      def home_status(home)
        directory_status(['${HOME}', home], home)
      end

      def workarea_status(workarea)
        directory_status(['${WORKAREA}', abbreviate(workarea, :home)], workarea)
      end

      def for(multi_repo)
        case (user = org = project = multi_repo)
        when *USERS
          owner_status("user \"#{user}\"", Git::Multi::WORKAREA, user)
        when *ORGANIZATIONS
          owner_status("org \"#{org}\"", Git::Multi::WORKAREA, org)
        when *SUPERPROJECTS
          project_status("superproject \"#{project}\"", project)
        else
          raise "Unknown multi repo: #{multi_repo}"
        end
      end

    end
  end
end
