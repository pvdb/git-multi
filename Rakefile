require 'bundler/gem_tasks'

def gemspec
  @gemspec ||= begin
                 # rubocop:disable Security/Eval
                 eval(File.read('git-multi.gemspec'))
                 # rubocop:enable Security/Eval
               end
end

desc 'Validate the gemspec'
task :validate do
  gemspec.validate
end

require 'rake/testtask'

Rake::TestTask.new(:test) do |t|
  t.libs << 'test'
  t.libs << 'lib'
  t.test_files = FileList['test/**/*_test.rb']
end

# rubocop:disable Style/HashSyntax

task :default => :test

task :documentation => 'doc/git-multi.txt'

def query_args
  require 'git/multi'

  client = Git::Hub.send(:client) # Octokit GitHub API client
  repo = client.repo('git/git')   # random GitHub repository

  # instead of maintaining a list of valid query args in the help-
  # file, we determine it at runtime... less is more, and all that
  repo.fields.sort.each_slice(3).map { |foo, bar, qux|
    format('%-20s %-20s %-20s', foo, bar, qux).rstrip
  }.join("\n    ")
end

file 'doc/git-multi.txt' => 'doc/git-multi.erb' do |task|
  File.write(task.name, File.read(task.source) % {
    :vv => Git::Multi::VERSION,
    :query_args => query_args,
  })
end

# rubocop:enable Style/HashSyntax
