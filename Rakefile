require 'rake'
require 'spec/rake/spectask'
require 'bundler/gem_tasks'

desc 'Default: Run all specs.'
task :default => :spec

desc "Run all specs"
Spec::Rake::SpecTask.new() do |t|
  t.spec_opts = ['--options', "\"spec/support/spec.opts\""]
  t.spec_files = FileList['spec/**/*_spec.rb']
end
