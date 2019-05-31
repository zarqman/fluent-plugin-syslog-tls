# Copyright 2016 Acquia, Inc.
# Copyright 2016-2019 t.e.morgan.
#
# Licensed under the Apache License, Version 2.0 (the "License");
# you may not use this file except in compliance with the License.
# You may obtain a copy of the License at
#
#     http://www.apache.org/licenses/LICENSE-2.0
#
# Unless required by applicable law or agreed to in writing, software
# distributed under the License is distributed on an "AS IS" BASIS,
# WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
# See the License for the specific language governing permissions and
# limitations under the License.

lib = File.expand_path('../lib', __FILE__)
$LOAD_PATH.unshift(lib) unless $LOAD_PATH.include?(lib)
require 'syslog_tls/version'

Gem::Specification.new do |s|
  s.name          = 'fluent-plugin-syslog-tls'
  s.version       = SyslogTls::VERSION
  s.authors       = ['thomas morgan']
  s.email         = ['tm@iprog.com']
  s.summary       = %q{Fluent Syslog TLS output plugin}
  s.description   = %q{Syslog TLS output plugin with formatting support, for Fluentd}
  s.homepage      = 'https://github.com/zarqman/fluent-plugin-syslog-tls'
  s.license       = 'Apache v2'
  s.files         = `git ls-files`.split($/)
  s.executables   = s.files.grep(%r{^bin/}).map{ |f| File.basename(f) }
  s.test_files    = s.files.grep(%r{^(test|spec|features)/})
  s.require_paths = ['lib']
  s.required_ruby_version = '>= 2.4'

  s.add_runtime_dependency 'fluentd', [">= 0.14.0", "< 2"]

  s.add_development_dependency 'minitest', '~> 5.8'
  s.add_development_dependency 'minitest-stub_any_instance', '~> 1.0.0'
  s.add_development_dependency 'rake'
  s.add_development_dependency 'test-unit', '~> 3.1'
  s.add_development_dependency 'webmock', '~> 3.0'
  s.add_development_dependency 'simplecov', '~> 0.11'
end
