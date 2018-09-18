$INTERACTIVE = (STDOUT.tty? && STDERR.tty?)

def git_option name, default = nil
  value = `git config #{name}`.chomp.freeze
  value.empty? && default ? default : value
end

def env_var name, default = nil
  value = ENV[name].freeze
  (value.nil? || value.empty?) && default ? default : value
end

def describe token
  token.nil? ? '(nil)' : token.empty? ? '(empty)' : "#{'*'*36}#{token[36..-1]}"
end

def symbolize token
  case token
  when env_var('OCTOKIT_ACCESS_TOKEN') then '${OCTOKIT_ACCESS_TOKEN}'
  when git_option('github.token')      then 'github.token'
  else '(unset)'
  end
end

def abbreviate directory, root_dir = nil
  case root_dir
  when :home     then directory.gsub(Git::Multi::HOME,     '${HOME}')
  when :workarea then directory.gsub(Git::Multi::WORKAREA, '${WORKAREA}')
  else abbreviate(abbreviate(directory, :workarea), :home)
  end
end
