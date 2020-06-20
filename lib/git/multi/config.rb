module Git
  module Multi
    module_function

    def local_option(path, name, default = nil)
      value = `git -C #{path} config --local --get #{name}`.chomp.freeze
      value.empty? && default ? default : value
    end

    def full_names_for(superproject)
      list = `git config --get-all superproject.#{superproject}.repo`
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
      value = ENV[name]
      (value.nil? || value.empty?) && default ? default : value
    end
  end
end
