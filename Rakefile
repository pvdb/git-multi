require "bundler/gem_tasks"

task :default => :validate

def gemspec
  @gemspec ||= eval(File.read(Dir["*.gemspec"].first))
end

desc "Validate the gemspec"
task :validate do
  gemspec.validate
end
