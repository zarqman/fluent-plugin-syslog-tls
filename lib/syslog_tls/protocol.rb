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

require 'date'

require_relative 'facility'
require_relative 'severity'

# Syslog protocol https://tools.ietf.org/html/rfc5424
module SyslogTls
  # RFC defined nil value
  NIL_VALUE = '-'

  # All headers by specification wrapped in single object
  class Header
    attr_accessor :version, :hostname, :app_name, :procid, :msgid
    attr_reader :facility, :severity, :timestamp

    FACILITIES = {}
    SEVERITIES = {}

    Facility.setup_constants FACILITIES
    Severity.setup_constants SEVERITIES

    def initialize
      @timestamp = Time.now
      @severity = 'INFO'
      @facility = 'LOCAL0'
      @version = 1
      @hostname = NIL_VALUE
      @app_name = NIL_VALUE
      @procid = NIL_VALUE
      @msgid = NIL_VALUE
    end

    def timestamp=(val)
      raise ArgumentError.new("Must provide Time object value instead: #{val.inspect}") unless val.is_a?(Time)
      @timestamp = val
    end

    def facility=(val)
      raise ArgumentError.new("Invalid facility value: #{val.inspect}") unless FACILITIES.key?(val)
      @facility = val
    end

    def severity=(val)
      raise ArgumentError.new("Invalid severity value: #{val.inspect}") unless SEVERITIES.key?(val)
      @severity = val
    end

    # Priority value is calculated by first multiplying the Facility
    # number by 8 and then adding the numerical value of the Severity.
    def pri
      FACILITIES[facility] * 8 + SEVERITIES[severity]
    end

    def assemble
      [
        "<#{pri}>#{version}",
        timestamp.to_datetime.rfc3339,
        hostname,
        app_name,
        procid,
        msgid
      ].join(' ')
    end

    def to_s
      assemble
    end
  end

  # Structured data field
  class StructuredData
    attr_accessor :id, :data

    def initialize(id)
      @id = id
      @data = {}
    end

    # Format data structured data to
    # [id k="v" ...]
    def assemble
      return NIL_VALUE unless id
      parts = [id]
      data.each do |k, v|
        # Characters ", ] and \ must be escaped to prevent any parsing errors
        v = v.gsub(/(\"|\]|\\)/) { |match| '\\' + match }
        parts << "#{k}=\"#{v}\""
      end
      "[#{parts.join(' ')}]"
    end

    def to_s
      assemble
    end
  end

  # Message represents full message that can be sent to syslog
  class Message
    attr_accessor :structured_data, :msg
    attr_writer :header

    def initialize
      @msg = ''
      @structured_data = []
    end

    def header
      @header ||= Header.new
    end

    def assemble
      # Start with header
      out = [header.to_s]
      # Add all structured data
      if structured_data.length > 0
        out << structured_data.map(&:to_s).join('')
      else
        out << NIL_VALUE
      end
      # Add message
      out << msg if msg.length > 0
      # Message must end with new line delimiter
      out.join(' ') + "\n"
    end

    def to_s
      assemble
    end
  end
end
