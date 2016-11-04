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
require 'syslog_tls/ssl_transport'

class SSLTransportTest < Test::Unit::TestCase
  include SSLTestHelper

  def test_ok_connection
    server = ssl_server
    st = Thread.new {
      client = server.accept
      assert_equal "TESTTEST2\n", client.gets
      client.close
    }
    SyslogTls::SSLTransport.stub_any_instance(:get_ssl_connection, ssl_client) do
      t = SyslogTls::SSLTransport.new("localhost", server.addr[1], max_retries: 3)
      t.write("TEST")
      t.write("TEST2\n")
    end
    st.join
  end

  def test_retry
    client = Object.new
    def client.connect
      true
    end
    def client.write(s)
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
