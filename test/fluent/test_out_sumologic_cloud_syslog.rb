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

require 'helper'
require 'fluent/plugin/out_sumologic_cloud_syslog'

class SumologicCloudSyslogOutput< Test::Unit::TestCase
  def setup
    Fluent::Test.setup
    @driver = nil
  end

  def driver(tag='test', conf='')
    @driver ||= Fluent::Test::OutputTestDriver.new(Fluent::SumologicCloudSyslogOutput, tag).configure(conf)
  end

  def sample_record
    #@todo: define
    {}
  end

  def test_configure
    config = %{
      host   syslog.collection.us1.sumologic.com
      port   6514
      cert
      key
      token  1234567890
    }
    instance = driver('test', config).instance

    assert_equal 'syslog.collection.us1.sumologic.com', instance.host
    assert_equal '6514', instance.port
    assert_equal '', instance.cert
    assert_equal '', instance.key
    assert_equal '1234567890', instance.token
  end
end
