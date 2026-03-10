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
  s.metadata = {
    'source_code_uri' => s.homepage,
    'bug_tracker_uri' => 'https://github.com/makandra/consul/issues',
    'changelog_uri' => 'https://github.com/makandra/consul/blob/master/CHANGELOG.md',
    'rubygems_mfa_required' => 'true',
  }

  s.files = `git ls-files`.split("\n").reject { |f| File.symlink?(f) }.reject { |f| f.match(%r{^(spec|dev|media|.github)/}) }
  s.require_paths = ["lib"]

  s.bindir = 'exe'
  s.executables = []

  s.required_ruby_version = '>= 3.0.0'

  s.add_dependency('memoized', '>=1.0.2')
  s.add_dependency('activerecord', '>= 7.2')
  s.add_dependency('activesupport', '>= 7.2')
  s.add_dependency('railties', '>= 7.2')
  s.add_dependency('edge_rider', '>= 0.3.0')
end
