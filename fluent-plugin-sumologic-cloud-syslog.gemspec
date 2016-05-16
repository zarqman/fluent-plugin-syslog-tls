# Copyright 2016 Acquia, Inc.
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
require 'sumologic_cloud_syslog/version'

Gem::Specification.new do |s|
  s.name          = 'fluent-plugin-sumologic-cloud-syslog'
  s.version       = SumologicCloudSyslog::VERSION
  s.authors       = ['Acquia Engineering']
  s.email         = ['engineering@acquia.com']
  s.summary       = %q{Fluent Sumologic Cloud Syslog plugin}
  s.description   = %q{Sumologic Cloud Syslog output plugin for Fluent event collector}
  s.homepage      = 'https://github.com/acquia/fluent-plugin-sumologic-cloud-syslog'
  s.license       = 'Apache v2'
  s.files         = `git ls-files`.split($/)
  s.executables   = s.files.grep(%r{^bin/}).map{ |f| File.basename(f) }
  s.test_files    = s.files.grep(%r{^(test|spec|features)/})
  s.require_paths = ['lib']
  s.required_ruby_version = '>= 2.0.0'

  s.add_runtime_dependency 'fluentd', '~> 0.12'
  s.add_runtime_dependency 'fluent-mixin-config-placeholders', '~> 0.3'
  s.add_runtime_dependency 'fluent-mixin-plaintextformatter', '~> 0.2'

  s.add_development_dependency 'minitest', '~> 5.8'
  s.add_development_dependency 'minitest-stub_any_instance', '~> 1.0.0'
  s.add_development_dependency 'rake', '~> 10.5'
  s.add_development_dependency 'test-unit', '~> 3.1'
  s.add_development_dependency 'webmock', '~> 2.0'
  s.add_development_dependency 'simplecov', '~> 0.11'
end
