# coding: utf-8
lib = File.expand_path('../lib', __FILE__)
$LOAD_PATH.unshift(lib) unless $LOAD_PATH.include?(lib)
require 'listener/version'

Gem::Specification.new do |spec|
  spec.name          = "listener"
  spec.version       = Listener::VERSION
  spec.authors       = ["Chris Hanks"]
  spec.email         = ["christopher.m.hanks@gmail.com"]
  spec.description   = %q{Share the LISTEN functionality of a single PG connection}
  spec.summary       = %q{Utility to allow multiple codebases to share a single listening Postgres connection}
  spec.homepage      = 'https://github.com/chanks/listener'
  spec.license       = 'MIT'

  spec.files         = `git ls-files`.split($/)
  spec.executables   = spec.files.grep(%r{^bin/}) { |f| File.basename(f) }
  spec.test_files    = spec.files.grep(%r{^(test|spec|features)/})
  spec.require_paths = ["lib"]

  spec.add_development_dependency 'bundler', '~> 1.3'
  spec.add_development_dependency 'rake'

  spec.add_dependency 'pg'
end
