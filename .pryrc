# this loads all of "git meta"
load "bin/git-meta" unless Kernel.const_defined? 'Git::Meta'

# utility function to set pry context
# to an instance of <Octokit::Client>
def client() pry Git::Meta.send(:client) ; end

# utility function to set pry context
# to the Array of github repositories
def repos() pry Git::Meta.repositories ; end
