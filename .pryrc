# configure a logger
require 'logger'
logger = Logger.new(STDOUT)
logger.level = Logger::INFO

# configure Octokit middleware with logger
require 'octokit'
Octokit.middleware.response :logger, logger

# enumerator for Faraday middleware apps
def (middleware = Octokit.middleware).each_app
  Enumerator.new do |yielder|
    next_app = app
    while next_app do
      yielder << next_app
      next_app = next_app.instance_variable_get(:@app)
    end
  end
end

# this loads all of "git meta"
load "bin/git-meta" unless Kernel.const_defined? 'Git::Meta'

# this loads all "git meta" contribs
Dir.glob File.join(__dir__, 'contrib', '*', '*.rb'), &method(:require)

# utility function to set pry context
# to an instance of <Octokit::Client>
def client() pry Git::Hub.send(:client) ; end

# utility function to set pry context
# to the Array of github repositories
def repos() pry Git::Meta.repositories ; end
