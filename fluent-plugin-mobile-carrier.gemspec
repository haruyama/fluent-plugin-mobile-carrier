# -*- encoding: utf-8 -*-
require 'English'

Gem::Specification.new do |gem|
  gem.name          = 'fluent-plugin-mobile-carrier'
  gem.version       = '0.0.4'
  gem.authors       = ['HARUYAMA Seigo']
  gem.email         = ['haruyama@unixuser.org']
  gem.description   = %q(judge mobile carrier by ip address.)
  gem.summary       = %q(Fluentd plugin to judge mobile carrier by ip address.)
  gem.homepage      = 'http://github.com/haruyama/fluent-plugin-mobile-carrier'
  gem.license       = 'APLv2'

  gem.files         = `git ls-files`.split($OUTPUT_RECORD_SEPARATOR)
  gem.executables   = gem.files.grep(/^bin\//).map { |f| File.basename(f) }
  gem.test_files    = gem.files.grep(/^(test|spec|features)\//)
  gem.require_paths = ['lib']

  gem.add_development_dependency 'rake'
  gem.add_runtime_dependency 'fluentd'
end
