# frozen_string_literal: true

require 'bundler/gem_tasks'

def gemspec
  @gemspec ||= begin
                 # rubocop:disable Security/Eval
                 eval(File.read('git-meta.gemspec'))
                 # rubocop:enable Security/Eval
               end
end

desc 'Validate the gemspec'
task :validate do
  gemspec.validate
end

# the principle of least surprise...
task :default => :validate
