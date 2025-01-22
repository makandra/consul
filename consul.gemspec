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
  s.license = 'MIT'

  if RUBY_VERSION.to_f >= 2.0
    s.metadata = {
      'source_code_uri' => s.homepage,
      'bug_tracker_uri' => 'https://github.com/makandra/consul/issues',
      'changelog_uri' => 'https://github.com/makandra/consul/blob/master/CHANGELOG.md',
      'rubygems_mfa_required' => 'true',
    }
  end

  s.files         = `git ls-files`.split("\n").reject { |f| f.match(%r{^(test|spec|features)/}) }
  s.test_files    = `git ls-files -- {test,spec,features}/*`.split("\n")
  s.executables   = `git ls-files -- bin/*`.split("\n").map{ |f| File.basename(f) }
  s.require_paths = ["lib"]

  s.add_dependency('memoized', '>=1.0.2')
  s.add_dependency('activerecord', '>= 6.0')
  s.add_dependency('activesupport', '>= 6.0')
  s.add_dependency('railties', '>= 6.0')
  s.add_dependency('edge_rider', '>= 0.3.0')
end
