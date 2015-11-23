$INTERACTIVE = (STDOUT.tty? && STDERR.tty?)

def git_option name, default = nil
  value = `git config #{name}`.chomp.freeze
  value.empty? && default ? default : value
end

def env_var name, default = nil
  value = ENV[name].freeze
  (value.nil? || value.empty?) && default ? default : value
end

def abbreviate directory, root_dir = nil
  case root_dir
  when :home     then directory.gsub Regexp.escape(Git::Meta::HOME),     '${HOME}'
  when :workarea then directory.gsub Regexp.escape(Git::Meta::WORKAREA), '${WORKAREA}'
  else
    abbreviate(abbreviate(directory, :workarea), :home)
  end
end
