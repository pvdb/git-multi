module Git
  module Meta
    module Settings

      TICK  = ["2714".hex].pack("U*").green.freeze
      CROSS = ["2718".hex].pack("U*").red.freeze
      ARROW = ["2794".hex].pack("U*").blue.freeze

      module_function

      def setting_status messages, valid, optional = false
        fields = messages.join(' - ')
        icon = valid ? TICK : optional ? ARROW : CROSS
        if $INTERACTIVE
          print "   #{fields}" ; sleep 0.75 ; puts "\x0d#{icon}"
        else
          puts "#{icon}  #{fields}"
        end
      end

      def file_status message, file
        setting_status(
          [
            message,
            abbreviate(file),
            "#{File.size(file).commify} bytes",
          ],
          file && !file.empty? && File.file?(file),
          true
        )
      end

      def directory_status messages, directory
        setting_status(
          messages,
          directory && !directory.empty? && File.directory?(directory),
          false
        )
      end

      def workarea_status message, workarea, subdir
        directory_status(
          [
            message,
            File.join(abbreviate(workarea, :workarea), subdir),
            "#{Dir.new(workarea).git_repos(subdir).count.commify} repos"
          ],
          workarea
        )
      end

      def user_status user
        setting_status(["User", user], user && !user.empty?)
      end

      def organization_status orgs
        for org in orgs
          setting_status(["Organization", org], org && !org.empty?, true)
          setting_status(["Organization", "member?"], Git::Hub.orgs.include?(org), !Git::Hub.connected?)
        end
      end

      def token_status token
        setting_status(["Token", token], token && !token.empty?)
        setting_status(["Token", "valid?"], token && !token.empty? && Git::Hub.login, !Git::Hub.connected?)
        setting_status(["Token", "owned by #{Git::Meta::USER}?"], Git::Hub.login == Git::Meta::USER, !Git::Hub.connected?)
      end

      def home_status home
        directory_status(["Home", home], home)
      end

      def main_workarea_status workarea
        directory_status(["Workarea (main)", abbreviate(workarea, :home)], workarea)
      end

      def user_workarea_status user
        workarea_status("Workarea (user: #{user})", Git::Meta::WORKAREA, user)
      end

      def organization_workarea_status orgs
        for org in orgs
          workarea_status("Workarea (org: #{org})", Git::Meta::WORKAREA, org)
        end
      end

      def yaml_cache_status yaml_cache
        file_status("YAML cache", yaml_cache)
      end

      def json_cache_status json_cache
        file_status("JSON cache", json_cache)
      end

    end
  end
end
