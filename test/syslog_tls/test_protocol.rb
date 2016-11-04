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
require 'syslog_tls/protocol'

class ProtocolTest < Test::Unit::TestCase
  def test_header_defaults
    h = SyslogTls::Header.new

    # Check defaults
    assert_equal 'INFO', h.severity
    assert_equal 'LOCAL0', h.facility
    assert_equal 1, h.version
    assert_equal SyslogTls::NIL_VALUE, h.hostname
    assert_equal SyslogTls::NIL_VALUE, h.app_name
    assert_equal SyslogTls::NIL_VALUE, h.procid
    assert_equal SyslogTls::NIL_VALUE, h.msgid

    assert_equal "<#{h.pri}>1 #{h.timestamp.to_datetime.rfc3339} - - - -", h.to_s
  end

  def test_header_facility_setter
    h = SyslogTls::Header.new
    assert_raise do
      h.facility = "NON_EXISTING"
    end
    SyslogTls::Header::FACILITIES.each do |facility, _|
      assert_nothing_raised do
        h.facility = facility
      end
    end
  end

  def test_header_severity_setter
    h = SyslogTls::Header.new
    assert_raise do
      h.severity = "NON_EXISTING"
    end
    SyslogTls::Header::SEVERITIES.each do |severity, _|
      assert_nothing_raised do
        h.severity = severity
      end
    end
  end

  def test_header_timestamp_setter
    h = SyslogTls::Header.new
    assert_raise do
      h.timestamp = Time.now.to_i
    end
    assert_nothing_raised do
      h.timestamp = Time.now
    end
  end

  def test_header_hostname
    h = SyslogTls::Header.new
    h.hostname = "hostname"
    assert_equal "<#{h.pri}>1 #{h.timestamp.to_datetime.rfc3339} hostname - - -", h.to_s
  end

  def test_header_appname
    h = SyslogTls::Header.new
    h.app_name = "appname"
    assert_equal "<#{h.pri}>1 #{h.timestamp.to_datetime.rfc3339} - appname - -", h.to_s
  end

  def test_header_procid
    h = SyslogTls::Header.new
    h.procid = $$
    assert_equal "<#{h.pri}>1 #{h.timestamp.to_datetime.rfc3339} - - #{$$} -", h.to_s
  end

  def test_header_msgid
    h = SyslogTls::Header.new
    h.msgid = "msgid"
    assert_equal "<#{h.pri}>1 #{h.timestamp.to_datetime.rfc3339} - - - msgid", h.to_s
  end

  def test_structured_data_defaults
    id = "hash@IANA-ID"
    sd = SyslogTls::StructuredData.new(id)
    assert_equal "[#{id}]", sd.to_s
  end

  def test_structured_data_key
    id = "hash@IANA-ID"
    sd = SyslogTls::StructuredData.new(id)
    sd.data["key"] = "val"
    assert_equal "[#{id} key=\"val\"]", sd.to_s
  end

  def test_structured_data_escaping
    id = "hash@IANA-ID"
    sd = SyslogTls::StructuredData.new(id)
    sd.data["key"] = '\]"'
    assert_equal "[#{id} key=\"\\\\\\]\\\"\"]", sd.to_s
  end

  def test_messsage_defaults
    m = SyslogTls::Message.new
    assert_not_nil m.header
    assert_true m.structured_data.is_a? Array
    assert_equal 0, m.structured_data.length
    assert_equal "", m.msg

    assert_equal "<134>1 #{m.header.timestamp.to_datetime.rfc3339} - - - - -\n", m.to_s
  end

  def test_message_msg
    m = SyslogTls::Message.new
    m.msg = "TEST"
    assert_equal "<134>1 #{m.header.timestamp.to_datetime.rfc3339} - - - - - TEST\n", m.to_s
  end

  def test_message_sd
    m = SyslogTls::Message.new
    m.structured_data << SyslogTls::StructuredData.new("TEST_ID")
    assert_equal "<134>1 #{m.header.timestamp.to_datetime.rfc3339} - - - - [TEST_ID]\n", m.to_s
  end

  def test_message_multiple_sd
    m = SyslogTls::Message.new
    m.structured_data << SyslogTls::StructuredData.new("TEST_ID")
    m.structured_data << SyslogTls::StructuredData.new("TEST_ID2")
    assert_equal "<134>1 #{m.header.timestamp.to_datetime.rfc3339} - - - - [TEST_ID][TEST_ID2]\n", m.to_s
  end

  def test_message_multiple_sd_msg
    m = SyslogTls::Message.new
    m.structured_data << SyslogTls::StructuredData.new("TEST_ID")
    m.structured_data << SyslogTls::StructuredData.new("TEST_ID2")
    m.msg = "MSG"
    assert_equal "<134>1 #{m.header.timestamp.to_datetime.rfc3339} - - - - [TEST_ID][TEST_ID2] MSG\n", m.to_s
  end
end
