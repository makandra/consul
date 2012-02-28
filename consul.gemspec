$:.push File.expand_path("../lib", __FILE__)
require "consul/version"

Gem::Specification.new do |s|
  s.name = 'consul'
  s.version = Consul::VERSION
  s.authors = ["Henning Koch"]
  s.email = 'henning.koch@makandra.de'
  s.homepage = 'https://github.com/makandra/consul'
  s.summary = 'A scope-based authorization solution for Ruby on Rails.'
  s.description = s.summary

  s.files         = `git ls-files`.split("\n")
  s.test_files    = `git ls-files -- {test,spec,features}/*`.split("\n")
  s.executables   = `git ls-files -- bin/*`.split("\n").map{ |f| File.basename(f) }
  s.require_paths = ["lib"]

  s.add_dependency('rails')
  s.add_dependency('assignable_values')

  # s.add_development_dependency('assignable_values')
  s.add_development_dependency('rails', '~>2.3')
  s.add_development_dependency('rspec', '~>1.3')
  s.add_development_dependency('rspec-rails', '~>1.3')
  s.add_development_dependency('shoulda-matchers')
  s.add_development_dependency('sqlite3')
end
