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

task :documentation => 'man/git-multi.txt'

require 'git/multi'

file 'man/git-multi.txt' => 'man/git-multi.erb' do |task|
  require 'erb'
  File.write(task.name, ERB.new(File.read(task.source)).result)
end

# rubocop:enable Style/HashSyntax
