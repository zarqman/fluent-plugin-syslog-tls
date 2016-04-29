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
require 'date'
require 'sumologic_cloud_syslog/protocol'

class Protocol < Test::Unit::TestCase
  def test_header_defaults
    h = SumologicCloudSyslog::Header.new

    # Check defaults
    assert_equal h.severity, 'INFO'
    assert_equal h.facility, 'LOCAL0'
    assert_equal h.version, 1
    assert_equal h.hostname, SumologicCloudSyslog::NIL_VALUE
    assert_equal h.app_name, SumologicCloudSyslog::NIL_VALUE
    assert_equal h.procid, SumologicCloudSyslog::NIL_VALUE
    assert_equal h.msgid, SumologicCloudSyslog::NIL_VALUE

    assert_equal h.to_s, "<#{h.pri}>1 #{h.timestamp.to_datetime.rfc3339} - - - -"
  end

  def test_header_facility_setter
    h = SumologicCloudSyslog::Header.new
    assert_raise do
      h.facility = "NON_EXISTING"
    end
    SumologicCloudSyslog::Header::FACILITIES.each do |facility, _|
      assert_nothing_raised do
        h.facility = facility
      end
    end
  end

  def test_header_severity_setter
    h = SumologicCloudSyslog::Header.new
    assert_raise do
      h.severity = "NON_EXISTING"
    end
    SumologicCloudSyslog::Header::SEVERITIES.each do |severity, _|
      assert_nothing_raised do
        h.severity = severity
      end
    end
  end

  def test_header_timestamp_setter
    h = SumologicCloudSyslog::Header.new
    assert_raise do
      h.timestamp = Time.now.to_i
    end
    assert_nothing_raised do
      h.timestamp = Time.now
    end
  end

  def test_header_hostname
    h = SumologicCloudSyslog::Header.new
    h.hostname = "hostname"
    assert_equal h.to_s, "<#{h.pri}>1 #{h.timestamp.to_datetime.rfc3339} hostname - - -"
  end

  def test_header_appname
    h = SumologicCloudSyslog::Header.new
    h.app_name = "appname"
    assert_equal h.to_s, "<#{h.pri}>1 #{h.timestamp.to_datetime.rfc3339} - appname - -"
  end

  def test_header_procid
    h = SumologicCloudSyslog::Header.new
    h.procid = $$
    assert_equal h.to_s, "<#{h.pri}>1 #{h.timestamp.to_datetime.rfc3339} - - #{$$} -"
  end

  def test_header_msgid
    h = SumologicCloudSyslog::Header.new
    h.msgid = "msgid"
    assert_equal h.to_s, "<#{h.pri}>1 #{h.timestamp.to_datetime.rfc3339} - - - msgid"
  end

  def test_structured_data_defaults
    id = "hash@IANA-ID"
    sd = SumologicCloudSyslog::StructuredData.new(id)
    assert_equal sd.to_s, "[#{id}]"
  end

  def test_structured_data_key
    id = "hash@IANA-ID"
    sd = SumologicCloudSyslog::StructuredData.new(id)
    sd.data["key"] = "val"
    assert_equal sd.to_s, "[#{id} key=\"val\"]"
  end

  def test_structured_data_escaping
    id = "hash@IANA-ID"
    sd = SumologicCloudSyslog::StructuredData.new(id)
    sd.data["key"] = '\]"'
    assert_equal sd.to_s, "[#{id} key=\"\\\\\\]\\\"\"]"
  end

  def test_messsage_defaults
    m = SumologicCloudSyslog::Message.new
    assert_not_nil m.header
    assert_true m.structured_data.is_a? Array
    assert_equal m.structured_data.length, 0
    assert_equal m.msg, ""

    assert_equal m.to_s, "<134>1 #{m.header.timestamp.to_datetime.rfc3339} - - - - -\n"
  end

  def test_message_msg
    m = SumologicCloudSyslog::Message.new
    m.msg = "TEST"
    assert_equal m.to_s, "<134>1 #{m.header.timestamp.to_datetime.rfc3339} - - - - - TEST\n"
  end

  def test_message_sd
    m = SumologicCloudSyslog::Message.new
    m.structured_data << SumologicCloudSyslog::StructuredData.new("TEST_ID")
    assert_equal m.to_s, "<134>1 #{m.header.timestamp.to_datetime.rfc3339} - - - - [TEST_ID]\n"
  end

  def test_message_multiple_sd
    m = SumologicCloudSyslog::Message.new
    m.structured_data << SumologicCloudSyslog::StructuredData.new("TEST_ID")
    m.structured_data << SumologicCloudSyslog::StructuredData.new("TEST_ID2")
    assert_equal m.to_s, "<134>1 #{m.header.timestamp.to_datetime.rfc3339} - - - - [TEST_ID][TEST_ID2]\n"
  end

  def test_message_multiple_sd_msg
    m = SumologicCloudSyslog::Message.new
    m.structured_data << SumologicCloudSyslog::StructuredData.new("TEST_ID")
    m.structured_data << SumologicCloudSyslog::StructuredData.new("TEST_ID2")
    m.msg = "MSG"
    assert_equal m.to_s, "<134>1 #{m.header.timestamp.to_datetime.rfc3339} - - - - [TEST_ID][TEST_ID2] MSG\n"
  end
end
