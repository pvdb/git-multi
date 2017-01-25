require "bundler/gem_tasks"

def gemspec
  @gemspec ||= eval(File.read(Dir["*.gemspec"].first))
end

desc "Validate the gemspec"
task :validate do
  gemspec.validate
end

# the principle of least surprise...
task :default => :validate
