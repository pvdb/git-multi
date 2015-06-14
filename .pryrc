# this loads all of "git meta"
load "bin/git-meta"

# utility function to set pry context
# to an instance of <Octokit::Client>
def client() pry Git::Meta.client ; end

# utility function to set pry context
# to the Array of github repositories
def projects() pry Git::Meta.repositories ; end
