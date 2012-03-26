# -*- encoding: utf-8 -*-

$:.push File.expand_path('../lib', __FILE__)

require 'stream_logic/version'


Gem::Specification.new do |s|
  s.name        = 'stream_logic'
  s.version     = StreamLogic::VERSION
  s.authors     = %w[Theo Hultberg]
  s.email       = %w[theo@iconara.net]
  s.homepage    = 'http://github.com/iconara/stream_logic'
  s.summary     = %q{Lazy set operations on sorted streams}
  s.description = %q{StreamLogic lazily applies AND and OR operations to sorted streams (any Enumerable, actually)}

  s.rubyforge_project = 'stream_logic'

  s.files         = `git ls-files`.split("\n")
  #s.test_files    = `git ls-files -- {test,spec,features}/*`.split("\n")
  #s.executables   = `git ls-files -- bin/*`.split("\n").map{ |f| File.basename(f) }
  s.require_paths = %w[lib]

  # specify any dependencies here; for example:
  # s.add_development_dependency "rspec"
  # s.add_runtime_dependency "rest-client"
end
