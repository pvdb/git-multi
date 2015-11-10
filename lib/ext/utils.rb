def git_option name, default = nil
  value = `git config #{name}`.chomp.freeze
  value.empty? && default ? default : value
end

def env_var name, default = nil
  value = ENV[name].to_s.freeze
  value.empty? && default ? default : value
end
