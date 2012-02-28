require 'rake'
require 'rake/rdoctask'
require 'spec/rake/spectask'

task :default => :spec

Spec::Rake::SpecTask.new() do |t|
  t.spec_opts = ['--options', "\"spec/spec.opts\""]
  t.spec_files = FileList['spec/**/*_spec.rb']
end

desc 'Generate documentation for the consul gem'
Rake::RDocTask.new(:rdoc) do |rdoc|
  rdoc.rdoc_dir = 'rdoc'
  rdoc.title    = 'consul'
  rdoc.options << '--line-numbers' << '--inline-source'
  rdoc.rdoc_files.include('README')
  rdoc.rdoc_files.include('lib/**/*.rb')
end

begin
  require 'jeweler'
  Jeweler::Tasks.new do |gemspec|
    gemspec.name = "consul"
    gemspec.summary = "Scope-based authorization solution for Rails"
    gemspec.email = "henning.koch@makandra.de"
    gemspec.homepage = "http://github.com/makandra/consul"
    gemspec.description = "Consul is a scope-based authorization solution for Ruby on Rails."
    gemspec.authors = ["Henning Koch"]
    gemspec.add_dependency 
  end
rescue LoadError
  puts "Jeweler not available. Install it with: sudo gem install technicalpickles-jeweler -s http://gems.github.com"
end
