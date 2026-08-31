# Copyright 2016 Acquia, Inc.
# Copyright 2016-2025 t.e.morgan.
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
require 'thread'
require 'syslog_tls/logger'
require 'fluent/plugin/output'

module Fluent::Plugin
  class SyslogTlsOutput < Output
    Fluent::Plugin.register_output('syslog_tls', self)

    helpers :inject, :formatter, :compat_parameters

    DEFAULT_FORMAT_TYPE = 'json'
    THREAD_LOGGERS_KEY = :fluent_plugin_syslog_tls_loggers

    config_param :host, :string
    config_param :port, :integer
    config_param :idle_timeout, :integer, default: nil
    config_param :ca_cert, :string, default: 'system'
    config_param :verify_cert_name, :bool, default: true
    config_param :token, :string, default: nil
    config_param :client_cert, :string, default: nil
    config_param :client_key, :string, default: nil
    config_param :hostname, :string, default: nil
    config_param :facility, :string, default: 'LOCAL0'
    # Linux TCP_USER_TIMEOUT (ms). 0 disables. Ignored if the sockopt is missing.
    config_param :tcp_user_timeout, :integer, default: 15000

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

    config_section :buffer do
      config_set_default :chunk_keys, ['tag']
      config_set_default :flush_mode, :interval
      config_set_default :flush_interval, 5
      config_set_default :flush_thread_interval, 0.5
      config_set_default :flush_thread_burst_interval, 0.5
    end

    attr_accessor :formatter


    def initialize
      super
      @loggers_mutex = Mutex.new
      @loggers = []
    end

    def close
      super
      @loggers_mutex.synchronize do
        @loggers.each do |logger|
          logger.close rescue nil
        end
        @loggers.clear
      end
      thread_map = Thread.current[THREAD_LOGGERS_KEY]
      thread_map.delete(object_id) if thread_map
    end

    def multi_workers_ready?
      true
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

    def logger(tag)
      cache = loggers_for_current_thread
      cached = cache[tag]
      if cached.nil? || cached.closed?
        cached = new_logger(tag)
        cache[tag] = cached
        @loggers_mutex.synchronize { @loggers << cached }
      end
      cached
    end

    def new_logger(tag)
      transport = ::SyslogTls::SSLTransport.new(host, port,
        idle_timeout: idle_timeout,
        ca_cert: ca_cert,
        client_cert: client_cert,
        client_key: client_key,
        verify_cert_name: verify_cert_name,
        max_retries: 3,
        tcp_user_timeout: tcp_user_timeout,
      )
      logger = ::SyslogTls::Logger.new(transport, token)
      logger.facility(facility)
      logger.hostname(hostname)
      logger.app_name(tag)
      logger
    end

    def format_payload(tag, time, record)
      record = inject_values_to_record(tag, time, record)
      @formatter.format(tag, time, record)
    end

    def emit_record(tag, time, record)
      record.each_pair do |k, v|
        record[k] = v.dup.force_encoding('UTF-8') if v.is_a?(String) && v.encoding != Encoding::UTF_8
      end

      # Check if severity has been provided in record otherwise use INFO
      # by default.
      severity = if @mappings.key?(:severity)
                   record[@mappings[:severity]] || 'INFO'
                 else
                   'INFO'
                 end

      logger(tag).log(severity, format_payload(tag, time, record), time: time_from(time)) do |header|
        @mappings.each do |name, record_key|
          header.send("#{name}=", record[record_key]) unless record[record_key].nil?
        end
      end
    end

    def process(tag, es)
      es.each do |time, record|
        begin
          emit_record(tag, time, record)
        rescue => e
          log.error e.to_s
        end
      end
    end

    def write(chunk)
      return if chunk.empty?
      tag = chunk.metadata.tag
      begin
        chunk.each do |time, record|
          begin
            emit_record(tag, time, record)
          rescue ArgumentError => e
            log.error e.to_s
          end
        end
      rescue
        release_logger_for_current_thread(tag)
        raise
      end
    end

    private

    def time_from(time)
      case time
      when Time
        time
      else
        Time.at(time.to_r)
      end
    end

    def loggers_for_current_thread
      all = Thread.current[THREAD_LOGGERS_KEY] ||= {}
      all[object_id] ||= {}
    end

    def release_logger_for_current_thread(tag)
      cache = loggers_for_current_thread
      logger = cache.delete(tag)
      return unless logger
      logger.close rescue nil
      @loggers_mutex.synchronize { @loggers.delete(logger) }
    end
  end
end
