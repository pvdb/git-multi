module Git
  module Multi
    module_function

    def local_option(path, name, default = nil)
      value = `git -C #{path} config --local --get #{name}`.chomp.freeze
      value.empty? && default ? default : value
    end

    def global_options(name)
      list = `git config --global --get-all #{name}`
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
      ENV.fetch(name, default)
    end
  end
end
