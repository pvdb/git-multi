module Git
  module Meta
    module Settings

      TICK  = ["2714".hex].pack("U*").green.freeze
      CROSS = ["2718".hex].pack("U*").red.freeze
      ARROW = ["2794".hex].pack("U*").blue.freeze

      module_function

      def setting_status setting, value, valid, optional = false
        print "   %s: %s\x0d" % [setting, value]
        sleep 0.75
        puts "%s" % (valid ? TICK : optional ? ARROW : CROSS)
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
        setting_status("Home", home, home && !home.empty? && File.directory?(home))
      end

      def workarea_status workarea
        setting_status("Workarea", workarea, workarea && !workarea.empty? && File.directory?(workarea))
      end

      def user_workarea_status user_workarea
        setting_status("User workarea", user_workarea, user_workarea && !user_workarea.empty? && File.directory?(user_workarea))
      end

      def organization_workarea_status organization_workarea
        setting_status("Organization workarea", organization_workarea, organization_workarea && !organization_workarea.empty? && File.directory?(organization_workarea))
      end

      def yaml_cache_status yaml_cache
        setting_status("YAML cache", yaml_cache, yaml_cache && !yaml_cache.empty? && File.file?(yaml_cache), true)
      end

      def json_cache_status json_cache
        setting_status("JSON cache", json_cache, json_cache && !json_cache.empty? && File.file?(json_cache), true)
      end

    end
  end
end
