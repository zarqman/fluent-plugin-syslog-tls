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

require 'socket'

module Fluent::Plugin
  class SyslogTlsOutput < Output
    Fluent::Plugin.register_output('syslog_tls', self)

    helpers :inject, :formatter, :compat_parameters

    DEFAULT_FORMAT_TYPE = 'json'

    config_param :host, :string
    config_param :port, :integer
    config_param :idle_timeout, :integer, default: nil
    config_param :ca_cert, :string, default: 'system'
    config_param :token, :string, default: nil
    config_param :client_cert, :string, default: nil
    config_param :client_key, :string, default: nil
    config_param :hostname, :string, default: nil
    config_param :facility, :string, default: 'LOCAL0'

    # Allow to map keys from record to syslog message headers
    SYSLOG_HEADERS = [
      :severity, :facility, :hostname, :app_name, :procid, :msgid
    ]

    SYSLOG_HEADERS.each do |key_name|
      config_param "#{key_name}_key".to_sym, :string, default: nil
    end

    config_section :format do
      config_set_default :@type, DEFAULT_FORMAT_TYPE
    end

    attr_accessor :formatter


    def initialize
      super
      require 'syslog_tls/logger'
      @loggers = {}
    end

    def shutdown
      @loggers.values.each(&:close)
      super
    end

    # This method is called before starting.
    def configure(conf)
      if conf['output_type'] && !conf['format']
        conf['format'] = conf['output_type']
      end
      compat_parameters_convert(conf, :inject, :formatter)

      super
      @host = conf['host']
      @port = conf['port']
      @token = conf['token']
      @hostname = conf['hostname'] || Socket.gethostname.split('.').first

      # Determine mapping of record keys to syslog keys
      @mappings = {}
      SYSLOG_HEADERS.each do |key_name|
        conf_key = "#{key_name}_key"
        @mappings[key_name] = conf[conf_key] if conf.key?(conf_key)
      end

      @formatter = formatter_create(conf: conf.elements('format').first, default_type: DEFAULT_FORMAT_TYPE)
    end

    # Get logger for given tag
    def logger(tag)
      # Try to reuse existing logger
      @loggers[tag] ||= new_logger(tag)

      # Create new logger if old one is closed
      if @loggers[tag].closed?
        @loggers[tag] = new_logger(tag)
      end

      @loggers[tag]
    end

    def new_logger(tag)
      transport = ::SyslogTls::SSLTransport.new(host, port, idle_timeout: idle_timeout, ca_cert: ca_cert, client_cert: client_cert, client_key: client_key, max_retries: 3)
      logger = ::SyslogTls::Logger.new(transport, token)
      logger.facility(facility)
      logger.hostname(hostname)
      logger.app_name(tag)
      logger
    end

    def format(tag, time, record)
      record = inject_values_to_record(tag, time, record)
      @formatter.format(tag, time, record)
    end

    def process(tag, es)
      es.each do |time, record|
        record.each_pair do |_, v|
          v.force_encoding('utf-8') if v.is_a?(String)
        end

        # Check if severity has been provided in record otherwise use INFO
        # by default.
        severity = if @mappings.key?(:severity)
                     record[@mappings[:severity]] || 'INFO'
                   else
                     'INFO'
                   end

        # Send message to Syslog
        begin
          logger(tag).log(severity, format(tag, time, record), time: Time.at(time)) do |header|
            # Map syslog headers from record
            @mappings.each do |name, record_key|
              header.send("#{name}=", record[record_key]) unless record[record_key].nil?
            end
          end
        rescue => e
          log.error e.to_s
        end
      end
    end
  end
end
