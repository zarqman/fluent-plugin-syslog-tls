# Copyright 2016 Acquia, Inc.
# Copyright 2016 t.e.morgan.
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
require 'ssl'
require 'date'
require 'minitest/mock'
require 'fluent/plugin/out_syslog_tls'

class SyslogTlsOutputTest < Test::Unit::TestCase
  include SSLTestHelper

  def setup
    Fluent::Test.setup
    @driver = nil
  end

  def driver(tag='test', conf='')
    @driver ||= Fluent::Test::OutputTestDriver.new(Fluent::SyslogTlsOutput, tag).configure(conf)
  end

  def sample_record
    {
      "app_name" => "app",
      "hostname" => "host",
      "procid" => $$,
      "msgid" => 1000,
      "message" => "MESSAGE",
      "severity" => "PANIC",
    }
  end

  def mock_logger(token='TOKEN')
    io = StringIO.new
    io.set_encoding('utf-8')
    logger = ::SyslogTls::Logger.new(io, token)
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

  def test_default_emit
    config = %{
      host   syslog.collection.us1.sumologic.com
      port   6514
      cert
      key
    }
    instance = driver('test', config).instance

    time = Time.now
    record = sample_record
    logger = mock_logger(instance.token)

    instance.stub(:new_logger, logger) do
      chain = Minitest::Mock.new
      chain.expect(:next, nil)
      instance.emit('test', {time.to_i => record}, chain)
    end

    formatted_time = time.dup.utc.strftime("%Y-%m-%dT%H:%M:%SZ")
    assert_equal "<134>1 #{time.to_datetime.rfc3339} - - - - - #{formatted_time}\ttest\t#{record.to_json.to_s}\n\n", logger.transport.string
  end

  def test_message_headers_mapping
    config = %{
      host   syslog.collection.us1.sumologic.com
      port   6514
      cert
      key
      token  1234567890
      hostname_key hostname
      procid_key procid
      app_name_key app_name
      msgid_key msgid
    }
    instance = driver('test', config).instance

    time = Time.now
    record = sample_record
    logger = mock_logger

    instance.stub(:new_logger, logger) do
      chain = Minitest::Mock.new
      chain.expect(:next, nil)
      instance.emit('test', {time.to_i => record}, chain)
    end

    assert_true logger.transport.string.start_with?("<134>1 #{time.to_datetime.rfc3339} host app #{$$} 1000 [TOKEN]")
  end

  def test_message_severity_mapping
    config = %{
      host   syslog.collection.us1.sumologic.com
      port   6514
      cert
      key
      token  1234567890
      severity_key severity
    }
    instance = driver('test', config).instance

    time = Time.now
    record = sample_record
    logger = mock_logger

    instance.stub(:new_logger, logger) do
      chain = Minitest::Mock.new
      chain.expect(:next, nil)
      instance.emit('test', {time.to_i => record}, chain)
    end

    assert_true logger.transport.string.start_with?("<128>1")
  end

  def test_ssl
    time = Time.now
    record = sample_record

    server = ssl_server
    st = Thread.new {
        client = server.accept
        assert_equal "<134>1 #{time.to_datetime.rfc3339} host app #{$$} 1000 [1234567890] #{formatted_time}\ttest\t#{record.to_json.to_s}\n", client.gets
        client.close
    }

    config = %{
      host   localhost
      port   #{server.addr[1]}
      cert
      key
      token  1234567890
      hostname_key hostname
      procid_key procid
      app_name_key app_name
      msgid_key msgid
    }
    instance = driver('test', config).instance

    chain = Minitest::Mock.new
    chain.expect(:next, nil)

    SyslogTls::SSLTransport.stub_any_instance(:get_ssl_connection, ssl_client) do
      instance.emit('test', {time.to_i => record}, chain)
    end

    st.join
  end
end
