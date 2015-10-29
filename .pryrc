# this loads all of "git meta"
load "bin/git-meta" unless Kernel.const_defined? 'Git::Meta'

# this loads all "git meta" contribs
Dir.glob File.join(__dir__, 'contrib', '*', '*.rb'), &method(:require)

# utility function to set pry context
# to an instance of <Octokit::Client>
def client() pry Git::Meta.send(:client) ; end

# utility function to set pry context
# to the Array of github repositories
def repos() pry Git::Meta.repositories ; end
