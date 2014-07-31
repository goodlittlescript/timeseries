# -*- encoding: utf-8 -*-
lib = File.expand_path('../lib', __FILE__)
$LOAD_PATH.unshift(lib) unless $LOAD_PATH.include?(lib)
require 'timeseries/version'

Gem::Specification.new do |gem|
  gem.name          = "timeseries"
  gem.version       = Timeseries::VERSION
  gem.authors       = ["Simon Chiang"]
  gem.email         = ["simon.a.chiang@gmail.com"]
  gem.description   = %q{Generate time series data}
  gem.summary       = %q{Generate time series data}
  gem.homepage      = ""
  gem.license       = 'MIT'

  gem.files         = `git ls-files`.split($/)
  gem.executables   = gem.files.grep(%r{^bin/}).map{ |f| File.basename(f) }
  gem.test_files    = gem.files.grep(%r{^(test|spec|features)/})
  gem.require_paths = ["lib"]

  gem.add_dependency "activesupport", "~> 4.0"
  gem.add_dependency "tzinfo", "~> 1.2"
end
