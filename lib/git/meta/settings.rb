module Git
  module Meta
    module Settings

      def git_option name, default = nil
        value = `git config #{name}`.chomp.freeze
        value.empty? && default ? default : value
      end

      def env_var name, default = nil
        value = ENV[name].to_s.freeze
        value.empty? && default ? default : value
      end

      module_function :git_option, :env_var

      Git::Meta::USER          = git_option 'github.user'
      Git::Meta::ORGANIZATIONS = git_option 'github.organizations'

      Git::Meta::TOKEN         = git_option 'gitmeta.token'

      Git::Meta::HOME          = env_var 'HOME', Etc.getpwuid.dir

      Git::Meta::WORKAREA      = git_option 'gitmeta.workarea',  File.join(HOME, 'Workarea')
      Git::Meta::YAML_CACHE    = git_option 'gitmeta.yamlcache', File.join(HOME, '.gitmeta.yaml')
      Git::Meta::JSON_CACHE    = git_option 'gitmeta.jsoncache', File.join(HOME, '.gitmeta.json')

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

      def organizations_status orgs
        setting_status("Organizations", orgs, orgs && !orgs.empty?, true)
      end

      def token_status token
        setting_status("Token", token, token && !token.empty?)
        token_valid = begin
          Git::Meta.client.user.login
          true
        rescue Octokit::Unauthorized
          false
        end
        setting_status("Token", "valid?", token && !token.empty? && token_valid)
        token_owner = begin
          Git::Meta.client.user.login
        rescue Octokit::Unauthorized
          nil
        end
        setting_status("Token", "owned by #{Git::Meta::USER}?", token_owner == Git::Meta::USER)
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
        setting_status("User workarea", organization_workarea, organization_workarea && !organization_workarea.empty? && File.directory?(organization_workarea))
      end

      def yaml_cache_status yaml_cache
        setting_status("YAML cache", yaml_cache, yaml_cache && !yaml_cache.empty? && File.file?(yaml_cache), true)
      end

      def json_cache_status json_cache
        setting_status("JSON cache", json_cache, json_cache && !json_cache.empty? && File.directory?(json_cache), true)
      end

    end
  end
end
