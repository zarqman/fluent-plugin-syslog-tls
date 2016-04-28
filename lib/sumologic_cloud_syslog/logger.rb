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

require_relative 'protocol'
require_relative 'ssl_transport'

module SumologicCloudSyslog
  class Logger
    attr_reader :host, :port, :cert, :key, :transport

    def initialize(host, port, token, cert: nil, key: nil)
      @host = host
      @port = port
      @cert = cert
      @key = key

      @default_header = SumologicCloudSyslog::Header.new
      @default_structured_data = SumologicCloudSyslog::StructuredData.new(token)
      open
    end

    # Sets default facility for each message
    def facility(val)
      @default_header.facility = val
    end

    # Sets default hostname for each message
    def hostname(val)
      @default_header.hostname = val
    end

    # Sets default app_name for each message
    def app_name(val)
      @default_header.app_name = val
    end

    # Sets default procid for message
    def procid(val)
      @default_header.procid = val
    end

    # Check if SSL connection is opened
    def opened?
      transport && !transport.closed?
    end

    # Open SSL connection
    def open
      @transport = SumologicCloudSyslog::SSLTransport.new(host, port, cert: cert, key: key)
    end

    # Close SSL connection
    def close
      raise RuntimeError.new 'syslog not open' if transport.closed?
      transport.close
    end

    # Send log message with severity to Sumologic
    def log(severity, message, time: nil)
      time ||= Time.now

      m = SumologicCloudSyslog::Message.new

      # Include authentication header
      m.structured_data << @default_structured_data

      # Adjust header with current timestamp and severity
      m.header = @default_header.dup
      m.header.severity = severity
      m.header.timestamp = time

      yield m.header if block_given?

      m.msg = message

      @transport.write(m.to_s)
    end
  end
end
