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
require 'date'
require 'syslog_tls/logger'

class LoggerTest < Test::Unit::TestCase
  def test_logger_defaults
    io = StringIO.new
    l = SyslogTls::Logger.new(io, "TOKEN")
    time = Time.now
    l.log(:WARN, "MESSAGE", time: time)
    assert_equal "<132>1 #{time.to_datetime.rfc3339} - - - - [TOKEN] MESSAGE\n", io.string
  end

  def test_logger_default_headers
    io = StringIO.new
    l = SyslogTls::Logger.new(io, "TOKEN")
    l.hostname("hostname")
    l.app_name("appname")
    l.procid($$)
    l.facility("SYSLOG")
    time = Time.now
    l.log(:WARN, "MESSAGE", time: time)
    assert_equal "<44>1 #{time.to_datetime.rfc3339} hostname appname #{$$} - [TOKEN] MESSAGE\n", io.string
  end

  def test_logger_closed
    io = StringIO.new
    l = SyslogTls::Logger.new(io, "TOKEN")
    assert_false l.closed?
    l.close
    assert_true l.closed?
  end
end
