# Copyright 2016 Acquia, Inc.
# Copyright 2016-2023 t.e.morgan.
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
require 'syslog_tls/ssl_transport'

class SSLTransportTest < Test::Unit::TestCase
  include SSLTestHelper

  # srvr-min  srvr-max clnt-min should-raise?
  [ [:TLS1_2, :TLS1_2, :TLS1_2],
    [:TLS1_2, :TLS1_3, :TLS1_2],
    [:TLS1_3, :TLS1_3, :TLS1_2],
    [:TLS1_2, :TLS1_2, :TLS1_3, true],
    [:TLS1_2, :TLS1_3, :TLS1_3],
    [:TLS1_3, :TLS1_3, :TLS1_3],
  ].each do |(server_min, server_max, client_min, should_raise)|
    define_method "test_#{server_min}-#{server_max}_server_#{client_min}_client" do
      Thread.report_on_exception = false
      blk = lambda do
        server = ssl_server(min_version: server_min, max_version: server_max)
        st = Thread.new {
          client = server.accept
          assert_equal "TESTTEST2\n", client.gets
          client.close
        }
        t = SyslogTls::SSLTransport.new("localhost", server.addr[1], ca_cert: false, ssl_version: client_min)
        t.write("TEST")
        t.write("TEST2\n")
        st.join
      end
      if should_raise
        assert_raises OpenSSL::SSL::SSLError, &blk
      else
        blk.call
      end
    ensure
      Thread.report_on_exception = true
    end
  end

  def test_retry
    client = Object.new
    def client.connect_nonblock
      true
    end
    def client.write_nonblock(s)
      raise "Test"
    end

    SyslogTls::SSLTransport.stub_any_instance(:get_ssl_connection, client) do
      assert_raises RuntimeError do
        t = SyslogTls::SSLTransport.new("localhost", 33000, max_retries: 3)
        t.write("TEST\n")
      end
    end
  end
end
