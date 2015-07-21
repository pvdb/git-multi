module Git
  module Meta
    module Settings

      TICK  = ["2714".hex].pack("U*").green.freeze
      CROSS = ["2718".hex].pack("U*").red.freeze
      ARROW = ["2794".hex].pack("U*").blue.freeze

      module_function

      def setting_status setting, value, valid, optional = false
        if Nike.interactive?
          print "   %s: %s\x0d" % [setting, value]
          sleep 0.75
          puts "%s" % (valid ? TICK : optional ? ARROW : CROSS)
        else
          puts "%s  %s: %s" % [
            (valid ? TICK : optional ? ARROW : CROSS),
            setting, value,
          ]
        end
      end

      def file_status setting, file
        setting_status(
          setting,
          "%s (%s bytes)" % [
            Git::Meta.abbreviate(file),
            File.size(file).commify
          ],
          file && !file.empty? && File.file?(file),
          true
        )
      end

      def directory_status setting, value, directory
        setting_status(
          setting,
          value,
          directory && !directory.empty? && File.directory?(directory),
          false
        )
      end

      def workarea_status setting, workarea
        directory_status(
          setting,
          "%s (%s repos)" % [
            Git::Meta.abbreviate(workarea, :workarea),
            Dir.new(workarea).git_repos.count.commify
          ],
          workarea
        )
      end

      def user_status user
        setting_status("User", user, user && !user.empty?)
      end

      def organization_status orgs
        for org in orgs
          setting_status("Organization", org, org && !org.empty?, true)
          setting_status("Organization", "member?", Git::Meta::ORGS.include?(org), optional = !Git::Meta.connected?)
        end
      end

      def token_status token
        setting_status("Token", token, token && !token.empty?)
        setting_status("Token", "valid?", token && !token.empty? && Git::Meta::LOGIN, optional = !Git::Meta.connected?)
        setting_status("Token", "owned by #{Git::Meta::USER}?", Git::Meta::LOGIN == Git::Meta::USER, optional = !Git::Meta.connected?)
      end

      def home_status home
        directory_status("Home", home, home)
      end

      def main_workarea_status workarea
        directory_status("Workarea (main)", Git::Meta.abbreviate(workarea, :home), workarea)
      end

      def user_workarea_status user
        workarea_status("Workarea (user: #{user})", File.join(Git::Meta::WORKAREA, user))
      end

      def organization_workarea_status orgs
        for org in orgs
          workarea_status("Workarea (org: #{org})", File.join(Git::Meta::WORKAREA, org))
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
