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

require 'fluent/mixin/config_placeholders'
require 'fluent/mixin/plaintextformatter'
require 'socket'

require 'sumologic_cloud_syslog/logger'

module Fluent
  class SumologicCloudSyslogOutput < Fluent::Output
    Fluent::Plugin.register_output('sumologic_cloud_syslog', self)

    include Fluent::Mixin::PlainTextFormatter
    include Fluent::Mixin::ConfigPlaceholders
    include Fluent::HandleTagNameMixin

    config_param :host, :string
    config_param :port, :integer
    config_param :token, :string
    config_param :cert, :string, :default => nil
    config_param :key, :string, :default => nil
    config_param :hostname, :string, :default => nil
    config_param :facility, :string, :default => 'LOCAL0'

    # Allow to map keys from record to syslog message headers
    SYSLOG_HEADERS = [
      :severity, :facility, :hostname, :app_name, :procid, :msgid
    ]

    SYSLOG_HEADERS.each do |key_name|
      config_param "#{key_name}_key".to_sym, :string, :default => nil
    end

    def initialize
      super

      @loggers = {}
    end

    def shutdown
      super
      @loggers.values.each(&:close)
    end

    # This method is called before starting.
    def configure(conf)
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
    end

    # Get logger for given tag
    def logger(tag)
      @loggers[tag] ||= begin
        logger = ::SumologicCloudSyslog::Logger.new(host, port, token, cert: cert, key: key)
        logger.facility(facility)
        logger.hostname(hostname)
        logger.app_name(tag)
        logger
      end
      @loggers[tag].reopen unless @loggers[tag].opened?
      @loggers[tag]
    end

    def emit(tag, es, chain)
      chain.next
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

        # Send message to Sumo
        logger(tag).log(severity, format(tag, time, record), time: Time.at(time)) { |header|
          # Map syslog headers from record
          @mappings.each do |name, record_key|
            header.send("#{name}=", record[record_key]) unless record[record_key].nil?
          end
        }
      end
    end
  end
end
