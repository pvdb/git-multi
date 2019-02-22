# rubocop:disable Style/SymbolArray
# rubocop:disable Style/HashSyntax

require 'bundler/gem_tasks'

task :validate_gemspec do
  Bundler.load_gemspec('git-multi.gemspec').validate
end

task :version => :validate_gemspec do
  puts Git::Multi.version
end

require 'rubocop/rake_task'

RuboCop::RakeTask.new(:rubocop)

require 'rake/testtask'

Rake::TestTask.new(:test) do |t|
  t.libs << 'test'
  t.libs << 'lib'
  t.test_files = FileList['test/**/*_test.rb']
end

task :default => [:version, :rubocop, :test]

require 'git/multi'

git_workarea  = File.join(Git::Multi::WORKAREA, 'git', 'git')
documentation = File.join(git_workarea, 'Documentation')
git_asciidoc  = File.join(documentation, 'git-multi.txt')

require 'erb'

file 'man/git-multi.erb' => 'lib/git/multi/version.rb' # version changes

file git_asciidoc => 'man/git-multi.erb' do |task|
  File.write(task.name, ERB.new(File.read(task.source)).result)
end

task :documentation => git_asciidoc do
  Dir.chdir(documentation) do
    # use git's documentation framework
    `make git-multi.1 git-multi.html`
    FileUtils.cp 'git-multi.1',    Git::Multi::MAN_PAGE
    FileUtils.cp 'git-multi.html', Git::Multi::HTML_PAGE
  end
end

Rake::Task['build'].enhance([:default, :documentation])

# rubocop:enable Style/HashSyntax
# rubocop:enable Style/SymbolArray
