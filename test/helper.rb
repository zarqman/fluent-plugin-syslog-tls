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

require 'coveralls'
require 'simplecov'

SimpleCov.start

Coveralls.wear! if ENV['TRAVIS']

# Fluentd sets default encoding to ASCII-8BIT, but coverall can load git data which can contain UTF-8 characters
at_exit do
  Encoding.default_internal = 'UTF-8' if defined?(Encoding) && Encoding.respond_to?(:default_internal)
  Encoding.default_external = 'UTF-8' if defined?(Encoding) && Encoding.respond_to?(:default_external)
end

require 'test/unit'
require 'fluent/test'
require 'minitest/pride'

require 'webmock/test_unit'
WebMock.disable_net_connect!
